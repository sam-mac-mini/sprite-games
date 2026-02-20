import SpriteKit
import UIKit

/// Displays the tech tree between loops — tabbed, branch-based tree layout.
final class TechTreeScene: SKScene {
    
    private var meta: MetaState!
    private var kpLabel: SKLabelNode!
    private var contentCropNode: SKCropNode!
    private var contentNode: SKNode!
    private var tabButtons: [SKShapeNode] = []
    private var nodeViews: [String: SKShapeNode] = [:]
    private var nodePositions: [String: CGPoint] = [:]
    private var selectedBranch: TechBranch = .infrastructure
    
    // Safe-area / layout
    private var safeTop: CGFloat = 0
    private var tabsY: CGFloat = 0
    private var contentTopY: CGFloat = 0
    private let contentBottomY: CGFloat = 86
    private var contentHeight: CGFloat { contentTopY - contentBottomY }
    private var contentRect: CGRect {
        CGRect(x: 0, y: contentBottomY, width: size.width, height: contentHeight)
    }
    
    // Dynamic node sizing (computed from branch width)
    private var nodeWidth: CGFloat = 96
    private let nodeHeight: CGFloat = 88
    private let tierSpacing: CGFloat = 170
    
    // Scroll
    private var scrollOffset: CGFloat = 0
    private var maxScrollOffset: CGFloat = 0
    private var lastTouchY: CGFloat = 0
    private var isDragging = false
    private var panGesture: UIPanGestureRecognizer?
    
    // Session-local apply flow
    private var pendingPurchases: Int = 0
    private var applyButton: SKShapeNode?
    private var applyLabel: SKLabelNode?
    private var toastNode: SKLabelNode?
    
    // Callback
    var onStartLoop: (() -> Void)?
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.03, blue: 0.06, alpha: 1)
        safeTop = view.safeAreaInsets.top
        meta = MetaState.load()
        buildUI()
        installPanGestureIfNeeded(view: view)
    }
    
    override func willMove(from view: SKView) {
        if let pan = panGesture {
            view.removeGestureRecognizer(pan)
            panGesture = nil
        }
    }
    
    // MARK: - UI
    
    private func buildUI() {
        removeAllChildren()
        
        let topBase = size.height - safeTop - 14
        
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "TECH TREE"
        title.fontSize = 17
        title.fontColor = SKColor(red: 0.4, green: 0.75, blue: 1, alpha: 1)
        title.position = CGPoint(x: size.width / 2, y: topBase)
        title.zPosition = 30
        addChild(title)
        
        kpLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        kpLabel.fontSize = 13
        kpLabel.fontColor = SKColor(red: 0.4, green: 0.9, blue: 1, alpha: 1)
        kpLabel.position = CGPoint(x: size.width / 2, y: topBase - 18)
        kpLabel.zPosition = 30
        addChild(kpLabel)
        updateKPLabel()
        
        let stats = SKLabelNode(fontNamed: "Menlo")
        stats.text = "Loops: \(meta.totalLoops) • Best: \(meta.bestLoopScore) KP"
        stats.fontSize = 9
        stats.fontColor = SKColor(white: 0.45, alpha: 1)
        stats.position = CGPoint(x: size.width / 2, y: topBase - 32)
        stats.zPosition = 30
        addChild(stats)
        
        tabsY = topBase - 58
        contentTopY = tabsY - 22
        
        buildTabBar()
        
        // Backdrop with Kenney texture tint
        let backdropTex = SKSpriteNode(imageNamed: "groundTileAlt")
        backdropTex.size = CGSize(width: size.width - 10, height: contentHeight + 8)
        backdropTex.position = CGPoint(x: size.width / 2, y: contentBottomY + contentHeight / 2)
        backdropTex.color = SKColor(red: 0.06, green: 0.08, blue: 0.12, alpha: 1)
        backdropTex.colorBlendFactor = 0.72
        backdropTex.alpha = 0.9
        backdropTex.zPosition = 2
        addChild(backdropTex)
        
        let border = SKShapeNode(rectOf: CGSize(width: size.width - 10, height: contentHeight + 8), cornerRadius: 10)
        border.fillColor = .clear
        border.strokeColor = SKColor(white: 0.14, alpha: 0.6)
        border.lineWidth = 1
        border.position = backdropTex.position
        border.zPosition = 3
        addChild(border)
        
        // Crop/mask for scroll area
        contentCropNode = SKCropNode()
        contentCropNode.zPosition = 5
        let mask = SKSpriteNode(color: .white, size: CGSize(width: size.width - 12, height: contentHeight))
        mask.position = CGPoint(x: size.width / 2, y: contentBottomY + contentHeight / 2)
        contentCropNode.maskNode = mask
        
        contentNode = SKNode()
        contentCropNode.addChild(contentNode)
        addChild(contentCropNode)
        
        addChild(makeScrollButton(name: "scrollUp", text: "▲", x: size.width - 18, y: contentTopY - 14))
        addChild(makeScrollButton(name: "scrollDown", text: "▼", x: size.width - 18, y: contentBottomY + 12))
        
        let dragHint = SKLabelNode(fontNamed: "Menlo")
        dragHint.text = "Drag / ▲▼ to scroll"
        dragHint.fontSize = 8
        dragHint.fontColor = SKColor(white: 0.35, alpha: 1)
        dragHint.position = CGPoint(x: size.width - 60, y: contentBottomY - 8)
        dragHint.zPosition = 30
        addChild(dragHint)
        
        // Bottom buttons: Apply + Start
        applyButton = makeBottomButton(name: "applyBtn", text: "APPLY", width: 116, x: size.width / 2 - 66, y: 35,
                                       fill: SKColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 0.9),
                                       stroke: SKColor(white: 0.2, alpha: 0.7))
        if let applyButton = applyButton {
            applyButton.zPosition = 30
            addChild(applyButton)
            applyLabel = applyButton.childNode(withName: "label") as? SKLabelNode
        }
        
        let startBtn = makeBottomButton(name: "startLoopBtn", text: "▶ START", width: 116, x: size.width / 2 + 66, y: 35,
                                        fill: SKColor(red: 0.15, green: 0.4, blue: 0.2, alpha: 1),
                                        stroke: SKColor(red: 0.25, green: 0.6, blue: 0.3, alpha: 1))
        startBtn.zPosition = 30
        addChild(startBtn)
        refreshApplyButton()
        
        buildBranchTree(for: selectedBranch)
    }
    
    private func buildTabBar() {
        tabButtons.forEach { $0.removeFromParent() }
        tabButtons = []
        
        let branches = TechBranch.allCases
        let tabWidth = (size.width - 16) / CGFloat(branches.count)
        let startX: CGFloat = 8 + tabWidth / 2
        
        for (i, branch) in branches.enumerated() {
            let isSelected = branch == selectedBranch
            let tab = SKShapeNode(rectOf: CGSize(width: tabWidth - 4, height: 28), cornerRadius: 8)
            tab.fillColor = isSelected
                ? branchColor(branch).withAlphaComponent(0.35)
                : SKColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.85)
            tab.strokeColor = isSelected ? branchColor(branch) : SKColor(white: 0.15, alpha: 0.5)
            tab.lineWidth = isSelected ? 1.5 : 0.75
            tab.position = CGPoint(x: startX + CGFloat(i) * tabWidth, y: tabsY)
            tab.zPosition = 30
            tab.name = "tab_\(i)"
            addChild(tab)
            tabButtons.append(tab)
            
            // Kenney-style icon per branch
            let icon = SKSpriteNode(imageNamed: branchIconName(branch))
            icon.size = CGSize(width: 14, height: 14)
            icon.position = CGPoint(x: -tabWidth * 0.22, y: 0)
            icon.alpha = isSelected ? 0.95 : 0.6
            tab.addChild(icon)
            
            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.text = branch.shortName
            label.fontSize = 9
            label.fontColor = isSelected ? .white : SKColor(white: 0.5, alpha: 1)
            label.position = CGPoint(x: 7, y: 0)
            label.verticalAlignmentMode = .center
            tab.addChild(label)
        }
    }
    
    private func branchIconName(_ branch: TechBranch) -> String {
        switch branch {
        case .infrastructure: return "metalExtractor"
        case .colony: return "farm"
        case .research: return "researchLab"
        case .temporal: return "anomaly"
        }
    }
    
    // MARK: - Tree Layout
    
    private func buildBranchTree(for branch: TechBranch) {
        contentNode.removeAllChildren()
        nodeViews.removeAll()
        nodePositions.removeAll()
        scrollOffset = 0
        
        let nodes = orderedNodes(for: branch)
        let byTier = Dictionary(grouping: nodes, by: { $0.tier })
        let tiers = byTier.keys.sorted()
        let maxCount = byTier.values.map { $0.count }.max() ?? 1
        
        // Dynamic width so no overlap (max 3 cards on iPhone portrait)
        let usableWidth = size.width - 26
        let spacing: CGFloat = 8
        let candidate = floor((usableWidth - spacing * CGFloat(maxCount - 1)) / CGFloat(maxCount))
        nodeWidth = max(82, min(108, candidate))
        
        let topY = contentTopY - 28
        
        // First pass: position nodes tier by tier
        for (tierIndex, tier) in tiers.enumerated() {
            guard let tierNodes = byTier[tier] else { continue }
            let y = topY - CGFloat(tierIndex) * tierSpacing
            
            let tierLabel = SKLabelNode(fontNamed: "Menlo-Bold")
            tierLabel.text = "TIER \(tier)"
            tierLabel.fontSize = 10
            tierLabel.fontColor = SKColor(white: 0.34, alpha: 1)
            tierLabel.position = CGPoint(x: size.width / 2, y: y + 56)
            tierLabel.zPosition = 0
            contentNode.addChild(tierLabel)
            
            let xs: [CGFloat]
            if tier == tiers.first {
                xs = evenSlots(count: tierNodes.count)
            } else {
                // align child cards toward average x of prerequisites, then snap to nearest slots
                let targets = tierNodes.map { node in
                    let parentXs = node.prerequisites.compactMap { nodePositions[$0]?.x }
                    guard !parentXs.isEmpty else { return size.width / 2 }
                    return parentXs.reduce(0, +) / CGFloat(parentXs.count)
                }
                xs = assignTargetsToSlots(targets: targets, slotCount: tierNodes.count)
            }
            
            for (i, node) in tierNodes.enumerated() {
                let p = CGPoint(x: xs[i], y: y)
                nodePositions[node.id] = p
                let card = createNodeCard(node: node, at: p)
                nodeViews[node.id] = card
                contentNode.addChild(card)
            }
        }
        
        // Second pass: draw top->bottom elbow connections in the gaps between tiers
        for node in nodes {
            guard let to = nodePositions[node.id] else { continue }
            for prereq in node.prerequisites {
                guard let from = nodePositions[prereq] else { continue }
                
                let start = CGPoint(x: from.x, y: from.y - nodeHeight / 2 + 2)
                let end = CGPoint(x: to.x, y: to.y + nodeHeight / 2 - 2)
                let midY = (start.y + end.y) / 2
                
                let path = CGMutablePath()
                path.move(to: start)
                path.addLine(to: CGPoint(x: start.x, y: midY))
                path.addLine(to: CGPoint(x: end.x, y: midY))
                path.addLine(to: end)
                
                let line = SKShapeNode(path: path)
                let active = meta.isUnlocked(prereq)
                line.strokeColor = active
                    ? SKColor(red: 0.3, green: 0.7, blue: 0.35, alpha: 0.62)
                    : SKColor(white: 0.18, alpha: 0.45)
                line.lineWidth = active ? 2 : 1
                line.zPosition = -1
                contentNode.addChild(line)
            }
        }
        
        // Scroll bounds
        let lowest = nodePositions.values.map { $0.y - nodeHeight / 2 }.min() ?? (topY - 40)
        let highest = nodePositions.values.map { $0.y + nodeHeight / 2 }.max() ?? topY
        let contentSpan = (highest + 20) - (lowest - 20)
        maxScrollOffset = max(0, contentSpan - contentHeight)
        applyScroll()
    }
    
    private func orderedNodes(for branch: TechBranch) -> [TechNode] {
        let base: [TechNode]
        switch branch {
        case .infrastructure: base = TechTree.infrastructure
        case .colony: base = TechTree.colony
        case .research: base = TechTree.research
        case .temporal: base = TechTree.temporal
        }
        return base.sorted {
            if $0.tier == $1.tier { return $0.id < $1.id }
            return $0.tier < $1.tier
        }
    }
    
    private func evenSlots(count: Int) -> [CGFloat] {
        guard count > 1 else { return [size.width / 2] }
        let minX: CGFloat = 14 + nodeWidth / 2
        let maxX: CGFloat = size.width - 28 - nodeWidth / 2
        let step = (maxX - minX) / CGFloat(count - 1)
        return (0..<count).map { minX + CGFloat($0) * step }
    }
    
    private func assignTargetsToSlots(targets: [CGFloat], slotCount: Int) -> [CGFloat] {
        let slots = evenSlots(count: slotCount)
        var used = Array(repeating: false, count: slotCount)
        var result = Array(repeating: size.width / 2, count: slotCount)
        
        for (i, target) in targets.enumerated() {
            var best = 0
            var bestDist = CGFloat.greatestFiniteMagnitude
            for s in 0..<slots.count where !used[s] {
                let d = abs(slots[s] - target)
                if d < bestDist {
                    bestDist = d
                    best = s
                }
            }
            used[best] = true
            result[i] = slots[best]
        }
        return result
    }
    
    private func createNodeCard(node: TechNode, at position: CGPoint) -> SKShapeNode {
        let state = meta.nodeState(node)
        let card = SKShapeNode(rectOf: CGSize(width: nodeWidth, height: nodeHeight), cornerRadius: 10)
        card.position = position
        card.name = "node_\(node.id)"
        card.zPosition = 2
        
        // Kenney texture underlay
        let tex = SKSpriteNode(imageNamed: "groundTile")
        tex.size = CGSize(width: nodeWidth - 4, height: nodeHeight - 4)
        tex.alpha = 0.2
        tex.color = SKColor(red: 0.1, green: 0.12, blue: 0.2, alpha: 1)
        tex.colorBlendFactor = 0.55
        tex.zPosition = -1
        card.addChild(tex)
        
        switch state {
        case .unlocked:
            card.fillColor = SKColor(red: 0.08, green: 0.18, blue: 0.08, alpha: 0.95)
            card.strokeColor = SKColor(red: 0.28, green: 0.7, blue: 0.3, alpha: 0.9)
        case .affordable:
            card.fillColor = SKColor(red: 0.08, green: 0.1, blue: 0.2, alpha: 0.95)
            card.strokeColor = SKColor(red: 0.32, green: 0.55, blue: 0.95, alpha: 0.95)
            card.glowWidth = 2
        case .tooExpensive:
            card.fillColor = SKColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.9)
            card.strokeColor = SKColor(white: 0.22, alpha: 0.6)
        case .locked:
            card.fillColor = SKColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 0.85)
            card.strokeColor = SKColor(white: 0.12, alpha: 0.4)
        }
        card.lineWidth = 1.5
        
        let status = SKLabelNode(fontNamed: "Menlo-Bold")
        status.text = {
            switch state {
            case .unlocked: return "✅"
            case .affordable: return "💡"
            case .tooExpensive: return "🔒"
            case .locked: return "⛔"
            }
        }()
        status.fontSize = 13
        status.position = CGPoint(x: -nodeWidth / 2 + 12, y: nodeHeight / 2 - 16)
        status.verticalAlignmentMode = .center
        card.addChild(status)
        
        // Name (wrapped to avoid overflow)
        let nameLines = wordWrap(node.name, maxChars: max(10, Int((nodeWidth - 34) / 5.3))).prefix(2)
        for (i, line) in nameLines.enumerated() {
            let name = SKLabelNode(fontNamed: "Menlo-Bold")
            name.text = line
            name.fontSize = 8.5
            name.horizontalAlignmentMode = .left
            name.verticalAlignmentMode = .center
            name.position = CGPoint(x: -nodeWidth / 2 + 24, y: nodeHeight / 2 - 15 - CGFloat(i) * 9)
            name.fontColor = state == .locked ? SKColor(white: 0.35, alpha: 1) : .white
            card.addChild(name)
        }
        
        // Description (wrapped + clamped)
        let descTop = nodeHeight / 2 - 33 - CGFloat(max(0, nameLines.count - 1)) * 9
        let descLines = wordWrap(node.description, maxChars: max(12, Int((nodeWidth - 14) / 5.6)))
        for (i, line) in descLines.prefix(2).enumerated() {
            let desc = SKLabelNode(fontNamed: "Menlo")
            desc.text = line
            desc.fontSize = 7.3
            desc.horizontalAlignmentMode = .left
            desc.verticalAlignmentMode = .center
            desc.position = CGPoint(x: -nodeWidth / 2 + 8, y: descTop - CGFloat(i) * 10)
            desc.fontColor = state == .locked ? SKColor(white: 0.26, alpha: 1) : SKColor(white: 0.62, alpha: 1)
            card.addChild(desc)
        }
        
        let cost = SKLabelNode(fontNamed: "Menlo-Bold")
        cost.horizontalAlignmentMode = .right
        cost.verticalAlignmentMode = .center
        cost.position = CGPoint(x: nodeWidth / 2 - 7, y: -nodeHeight / 2 + 15)
        cost.fontSize = 8.5
        switch state {
        case .unlocked:
            cost.text = "OWNED"
            cost.fontColor = SKColor(red: 0.35, green: 0.8, blue: 0.35, alpha: 0.9)
        case .affordable:
            cost.text = "\(node.cost) KP • TAP"
            cost.fontColor = SKColor(red: 0.4, green: 0.9, blue: 1, alpha: 1)
        case .tooExpensive:
            cost.text = "\(node.cost) KP"
            cost.fontColor = SKColor(red: 0.85, green: 0.35, blue: 0.35, alpha: 0.8)
        case .locked:
            cost.text = "\(node.cost) KP"
            cost.fontColor = SKColor(white: 0.3, alpha: 1)
        }
        card.addChild(cost)
        
        return card
    }
    
    // MARK: - Input
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        lastTouchY = loc.y
        isDragging = false
        
        // Start
        if abs(loc.x - (size.width / 2 + 66)) < 58 && abs(loc.y - 35) < 22 {
            run(SoundManager.shared.newloop)
            onStartLoop?()
            return
        }
        
        // Apply
        if abs(loc.x - (size.width / 2 - 66)) < 58 && abs(loc.y - 35) < 22 {
            if pendingPurchases > 0 {
                showToast("Applied \(pendingPurchases) unlock(s)", color: SKColor(red: 0.4, green: 0.9, blue: 1, alpha: 1))
                pendingPurchases = 0
                refreshApplyButton()
            } else {
                showToast("No pending unlocks", color: SKColor(white: 0.7, alpha: 1))
            }
            return
        }
        
        // Tabs
        for (i, tab) in tabButtons.enumerated() {
            let halfW = tab.frame.width / 2
            let halfH = tab.frame.height / 2
            if abs(loc.x - tab.position.x) < halfW && abs(loc.y - tab.position.y) < halfH {
                let branch = TechBranch.allCases[i]
                if branch != selectedBranch {
                    selectedBranch = branch
                    buildTabBar()
                    buildBranchTree(for: selectedBranch)
                    run(SoundManager.shared.tap)
                }
                return
            }
        }
        
        // Scroll buttons
        if abs(loc.x - (size.width - 18)) < 15 && abs(loc.y - (contentTopY - 14)) < 12 {
            scrollBy(-110)
            return
        }
        if abs(loc.x - (size.width - 18)) < 15 && abs(loc.y - (contentBottomY + 12)) < 12 {
            scrollBy(110)
            return
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        guard contentRect.contains(loc) else { return }
        
        let deltaY = loc.y - lastTouchY
        lastTouchY = loc.y
        
        if abs(deltaY) > 2 { isDragging = true }
        if isDragging && maxScrollOffset > 0 {
            scrollOffset = clamp(scrollOffset - deltaY, min: 0, max: maxScrollOffset)
            applyScroll()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if isDragging { return }
        
        let locSelf = touch.location(in: self)
        guard contentRect.contains(locSelf) else { return }
        let loc = touch.location(in: contentNode)
        
        for node in orderedNodes(for: selectedBranch) {
            guard let view = nodeViews[node.id] else { continue }
            if abs(loc.x - view.position.x) < nodeWidth / 2 && abs(loc.y - view.position.y) < nodeHeight / 2 {
                handleNodeTap(node)
                return
            }
        }
    }
    
    private func installPanGestureIfNeeded(view: SKView) {
        guard panGesture == nil else { return }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
        panGesture = pan
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard maxScrollOffset > 0 else { return }
        guard let view = self.view else { return }
        let pView = gesture.location(in: view)
        let loc = convertPoint(fromView: pView)
        guard contentRect.contains(loc) else { return }
        
        switch gesture.state {
        case .began:
            lastTouchY = loc.y
        case .changed:
            let deltaY = loc.y - lastTouchY
            lastTouchY = loc.y
            scrollOffset = clamp(scrollOffset - deltaY, min: 0, max: maxScrollOffset)
            applyScroll()
        default:
            break
        }
    }
    
    private func handleNodeTap(_ node: TechNode) {
        let state = meta.nodeState(node)
        if state == .affordable {
            if meta.purchase(node) {
                run(SoundManager.shared.build)
                pendingPurchases += 1
                refreshApplyButton()
                showToast("Unlocked: \(node.name)", color: SKColor(red: 0.35, green: 0.9, blue: 0.45, alpha: 1))
                updateKPLabel()
                buildBranchTree(for: selectedBranch)
            }
        } else {
            run(SoundManager.shared.tap)
        }
    }
    
    // MARK: - Buttons / Feedback
    
    private func makeBottomButton(name: String, text: String, width: CGFloat, x: CGFloat, y: CGFloat, fill: SKColor, stroke: SKColor) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: CGSize(width: width, height: 40), cornerRadius: 12)
        btn.fillColor = fill
        btn.strokeColor = stroke
        btn.lineWidth = 1.5
        btn.position = CGPoint(x: x, y: y)
        btn.name = name
        
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.fontSize = 12
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.name = "label"
        btn.addChild(label)
        return btn
    }
    
    private func refreshApplyButton() {
        guard let applyButton = applyButton, let applyLabel = applyLabel else { return }
        if pendingPurchases > 0 {
            applyButton.fillColor = SKColor(red: 0.12, green: 0.3, blue: 0.45, alpha: 1)
            applyButton.strokeColor = SKColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1)
            applyButton.alpha = 1.0
            applyLabel.text = "APPLY (\(pendingPurchases))"
            applyLabel.fontColor = .white
        } else {
            applyButton.fillColor = SKColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 0.9)
            applyButton.strokeColor = SKColor(white: 0.2, alpha: 0.7)
            applyButton.alpha = 0.75
            applyLabel.text = "APPLY"
            applyLabel.fontColor = SKColor(white: 0.65, alpha: 1)
        }
    }
    
    private func showToast(_ text: String, color: SKColor) {
        toastNode?.removeFromParent()
        let toast = SKLabelNode(fontNamed: "Menlo-Bold")
        toast.text = text
        toast.fontSize = 11
        toast.fontColor = color
        toast.position = CGPoint(x: size.width / 2, y: 62)
        toast.zPosition = 40
        addChild(toast)
        toastNode = toast
        
        toast.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            SKAction.fadeOut(withDuration: 0.35),
            SKAction.removeFromParent()
        ]))
    }
    
    private func makeScrollButton(name: String, text: String, x: CGFloat, y: CGFloat) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: CGSize(width: 22, height: 20), cornerRadius: 6)
        btn.fillColor = SKColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 0.9)
        btn.strokeColor = SKColor(white: 0.2, alpha: 0.7)
        btn.lineWidth = 1
        btn.position = CGPoint(x: x, y: y)
        btn.zPosition = 30
        btn.name = name
        
        let lbl = SKLabelNode(fontNamed: "Menlo-Bold")
        lbl.text = text
        lbl.fontSize = 11
        lbl.fontColor = SKColor(white: 0.8, alpha: 1)
        lbl.verticalAlignmentMode = .center
        btn.addChild(lbl)
        return btn
    }
    
    // MARK: - Scroll Helpers
    
    private func scrollBy(_ amount: CGFloat) {
        guard maxScrollOffset > 0 else { return }
        scrollOffset = clamp(scrollOffset + amount, min: 0, max: maxScrollOffset)
        applyScroll()
    }
    
    private func applyScroll() {
        // Positive offset moves tree upward so lower tiers come into view.
        contentNode.position = CGPoint(x: 0, y: scrollOffset)
    }
    
    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
    
    // MARK: - Misc
    
    private func updateKPLabel() {
        let unlocked = meta.unlockedTechIDs.count
        let total = TechTree.allNodes.count
        kpLabel.text = "💡 \(meta.knowledgePoints) KP • \(unlocked)/\(total) unlocked"
    }
    
    private func branchColor(_ branch: TechBranch) -> SKColor {
        switch branch {
        case .infrastructure: return SKColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1)
        case .colony: return SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1)
        case .research: return SKColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1)
        case .temporal: return SKColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1)
        }
    }
    
    private func wordWrap(_ text: String, maxChars: Int) -> [String] {
        guard maxChars > 3 else { return [String(text.prefix(3))] }
        var words: [String] = []
        
        // Split overly long words into chunks so they can't overflow labels.
        for raw in text.split(separator: " ").map(String.init) {
            if raw.count <= maxChars {
                words.append(raw)
            } else {
                var start = raw.startIndex
                while start < raw.endIndex {
                    let end = raw.index(start, offsetBy: maxChars, limitedBy: raw.endIndex) ?? raw.endIndex
                    words.append(String(raw[start..<end]))
                    start = end
                }
            }
        }
        
        var lines: [String] = []
        var current = ""
        for word in words {
            let test = current.isEmpty ? word : current + " " + word
            if test.count > maxChars && !current.isEmpty {
                lines.append(current)
                current = word
            } else {
                current = test
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }
}
