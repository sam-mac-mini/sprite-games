import SpriteKit

/// Displays the tech tree between loops — tabbed, branch-based tree layout
class TechTreeScene: SKScene {
    
    private var meta: MetaState!
    private var kpLabel: SKLabelNode!
    
    private var contentCropNode: SKCropNode!
    private var contentNode: SKNode!
    private var tabButtons: [SKShapeNode] = []
    private var nodeViews: [String: SKShapeNode] = [:]
    private var selectedBranch: TechBranch = .infrastructure
    
    // Scroll
    private var scrollOffset: CGFloat = 0
    private var maxScrollOffset: CGFloat = 0
    private var lastTouchY: CGFloat = 0
    private var isDragging = false
    
    // Layout
    private let nodeWidth: CGFloat = 142
    private let nodeHeight: CGFloat = 96
    private var contentTopY: CGFloat { size.height - 118 }
    private var contentBottomY: CGFloat { 82 }
    private var contentHeight: CGFloat { contentTopY - contentBottomY }
    private var contentRect: CGRect {
        CGRect(x: 0, y: contentBottomY, width: size.width, height: contentHeight)
    }
    
    // Callback
    var onStartLoop: (() -> Void)?
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.03, blue: 0.06, alpha: 1)
        meta = MetaState.load()
        buildUI()
    }
    
    // MARK: - UI
    
    private func buildUI() {
        removeAllChildren()
        
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "TECH TREE"
        title.fontSize = 18
        title.fontColor = SKColor(red: 0.4, green: 0.75, blue: 1, alpha: 1)
        title.position = CGPoint(x: size.width / 2, y: size.height - 34)
        title.zPosition = 20
        addChild(title)
        
        kpLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        kpLabel.fontSize = 13
        kpLabel.fontColor = SKColor(red: 0.4, green: 0.9, blue: 1, alpha: 1)
        kpLabel.position = CGPoint(x: size.width / 2, y: size.height - 53)
        kpLabel.zPosition = 20
        addChild(kpLabel)
        updateKPLabel()
        
        let stats = SKLabelNode(fontNamed: "Menlo")
        stats.text = "Loops: \(meta.totalLoops) • Best: \(meta.bestLoopScore) KP"
        stats.fontSize = 9
        stats.fontColor = SKColor(white: 0.45, alpha: 1)
        stats.position = CGPoint(x: size.width / 2, y: size.height - 67)
        stats.zPosition = 20
        addChild(stats)
        
        buildTabBar(y: size.height - 93)
        
        // Content backdrop
        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width - 8, height: contentHeight + 6), cornerRadius: 10)
        backdrop.fillColor = SKColor(red: 0.04, green: 0.04, blue: 0.08, alpha: 0.85)
        backdrop.strokeColor = SKColor(white: 0.12, alpha: 0.5)
        backdrop.lineWidth = 1
        backdrop.position = CGPoint(x: size.width / 2, y: contentBottomY + contentHeight / 2)
        backdrop.zPosition = 2
        addChild(backdrop)
        
        // Crop/scroll area
        contentCropNode = SKCropNode()
        contentCropNode.zPosition = 5
        
        let mask = SKSpriteNode(color: .white, size: CGSize(width: size.width - 10, height: contentHeight))
        mask.position = CGPoint(x: size.width / 2, y: contentBottomY + contentHeight / 2)
        contentCropNode.maskNode = mask
        
        contentNode = SKNode()
        contentCropNode.addChild(contentNode)
        addChild(contentCropNode)
        
        // Scroll controls (for simulator/mouse friendliness)
        let up = makeScrollButton(name: "scrollUp", text: "▲", x: size.width - 18, y: contentTopY - 12)
        let down = makeScrollButton(name: "scrollDown", text: "▼", x: size.width - 18, y: contentBottomY + 12)
        addChild(up)
        addChild(down)
        
        let dragHint = SKLabelNode(fontNamed: "Menlo")
        dragHint.text = "Drag to scroll"
        dragHint.fontSize = 8
        dragHint.fontColor = SKColor(white: 0.35, alpha: 1)
        dragHint.position = CGPoint(x: size.width - 48, y: contentBottomY - 8)
        dragHint.zPosition = 20
        addChild(dragHint)
        
        // Start loop button
        let startBtn = SKShapeNode(rectOf: CGSize(width: 200, height: 40), cornerRadius: 12)
        startBtn.fillColor = SKColor(red: 0.15, green: 0.4, blue: 0.2, alpha: 1)
        startBtn.strokeColor = SKColor(red: 0.25, green: 0.6, blue: 0.3, alpha: 1)
        startBtn.lineWidth = 1.5
        startBtn.position = CGPoint(x: size.width / 2, y: 35)
        startBtn.zPosition = 20
        startBtn.name = "startLoopBtn"
        addChild(startBtn)
        
        let startLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        startLabel.text = "▶ START NEW LOOP"
        startLabel.fontSize = 13
        startLabel.fontColor = .white
        startLabel.verticalAlignmentMode = .center
        startBtn.addChild(startLabel)
        
        buildBranchTree(for: selectedBranch)
    }
    
    private func buildTabBar(y: CGFloat) {
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
            tab.position = CGPoint(x: startX + CGFloat(i) * tabWidth, y: y)
            tab.zPosition = 20
            tab.name = "tab_\(i)"
            addChild(tab)
            tabButtons.append(tab)
            
            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.text = "\(branch.symbol) \(branch.shortName)"
            label.fontSize = 9
            label.fontColor = isSelected ? .white : SKColor(white: 0.5, alpha: 1)
            label.verticalAlignmentMode = .center
            tab.addChild(label)
        }
    }
    
    // MARK: - Tree Content
    
    private func buildBranchTree(for branch: TechBranch) {
        contentNode.removeAllChildren()
        nodeViews.removeAll()
        scrollOffset = 0
        
        let nodes = TechTree.allNodes.filter { $0.branch == branch }
        let nodesByTier = Dictionary(grouping: nodes, by: { $0.tier })
        let sortedTiers = nodesByTier.keys.sorted()
        
        let topY = contentTopY - 22
        let tierSpacing: CGFloat = 170
        
        for (tierIndex, tier) in sortedTiers.enumerated() {
            guard let tierNodes = nodesByTier[tier] else { continue }
            let tierY = topY - CGFloat(tierIndex) * tierSpacing
            
            // Tier header
            let tierLabel = SKLabelNode(fontNamed: "Menlo-Bold")
            tierLabel.text = "TIER \(tier)"
            tierLabel.fontSize = 10
            tierLabel.fontColor = SKColor(white: 0.35, alpha: 1)
            tierLabel.position = CGPoint(x: size.width / 2, y: tierY + 62)
            tierLabel.zPosition = 0
            contentNode.addChild(tierLabel)
            
            // Node positions for branching layout
            let orderedNodes = tierNodes.sorted { $0.id < $1.id }
            let xs = horizontalPositions(count: orderedNodes.count)
            
            for (i, node) in orderedNodes.enumerated() {
                let pos = CGPoint(x: xs[i], y: tierY)
                let card = createNodeCard(node: node, at: pos)
                contentNode.addChild(card)
                nodeViews[node.id] = card
            }
        }
        
        // Draw branch connections (behind cards)
        for node in nodes {
            guard let toCard = nodeViews[node.id] else { continue }
            for prereqID in node.prerequisites {
                guard let fromCard = nodeViews[prereqID] else { continue }
                let line = SKShapeNode()
                let path = CGMutablePath()
                path.move(to: CGPoint(x: fromCard.position.x, y: fromCard.position.y - nodeHeight / 2 + 2))
                path.addLine(to: CGPoint(x: toCard.position.x, y: toCard.position.y + nodeHeight / 2 - 2))
                line.path = path
                let active = meta.isUnlocked(prereqID)
                line.strokeColor = active
                    ? SKColor(red: 0.3, green: 0.7, blue: 0.35, alpha: 0.6)
                    : SKColor(white: 0.18, alpha: 0.4)
                line.lineWidth = active ? 2 : 1
                line.zPosition = -2
                contentNode.addChild(line)
            }
        }
        
        // Scroll bounds
        let minY = nodeViews.values.map { $0.position.y }.min() ?? topY
        let contentTotal = (topY + 70) - (minY - nodeHeight / 2 - 20)
        maxScrollOffset = max(0, contentTotal - contentHeight)
        applyScroll()
    }
    
    private func createNodeCard(node: TechNode, at position: CGPoint) -> SKShapeNode {
        let state = meta.nodeState(node)
        let card = SKShapeNode(rectOf: CGSize(width: nodeWidth, height: nodeHeight), cornerRadius: 10)
        card.position = position
        card.name = "node_\(node.id)"
        card.zPosition = 1
        
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
        status.fontSize = 14
        status.position = CGPoint(x: -nodeWidth / 2 + 14, y: nodeHeight / 2 - 18)
        status.verticalAlignmentMode = .center
        card.addChild(status)
        
        let name = SKLabelNode(fontNamed: "Menlo-Bold")
        name.text = node.name
        name.fontSize = 10
        name.horizontalAlignmentMode = .left
        name.verticalAlignmentMode = .center
        name.position = CGPoint(x: -nodeWidth / 2 + 28, y: nodeHeight / 2 - 18)
        name.fontColor = state == .locked ? SKColor(white: 0.35, alpha: 1) : .white
        card.addChild(name)
        
        let descLines = wordWrap(node.description, maxChars: 24)
        for (i, line) in descLines.prefix(2).enumerated() {
            let desc = SKLabelNode(fontNamed: "Menlo")
            desc.text = line
            desc.fontSize = 8
            desc.horizontalAlignmentMode = .left
            desc.verticalAlignmentMode = .center
            desc.position = CGPoint(x: -nodeWidth / 2 + 10, y: 8 - CGFloat(i) * 11)
            desc.fontColor = state == .locked ? SKColor(white: 0.26, alpha: 1) : SKColor(white: 0.62, alpha: 1)
            card.addChild(desc)
        }
        
        let cost = SKLabelNode(fontNamed: "Menlo-Bold")
        cost.horizontalAlignmentMode = .right
        cost.verticalAlignmentMode = .center
        cost.position = CGPoint(x: nodeWidth / 2 - 8, y: -nodeHeight / 2 + 16)
        cost.fontSize = 9
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
    
    private func horizontalPositions(count: Int) -> [CGFloat] {
        if count <= 1 { return [size.width / 2] }
        let usableWidth = size.width - 40
        let step = min(160, usableWidth / CGFloat(count - 1))
        let totalWidth = step * CGFloat(count - 1)
        let start = size.width / 2 - totalWidth / 2
        return (0..<count).map { start + CGFloat($0) * step }
    }
    
    // MARK: - Touch
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        lastTouchY = loc.y
        isDragging = false
        
        // Start loop
        if abs(loc.x - size.width / 2) < 100 && abs(loc.y - 35) < 22 {
            run(SoundManager.shared.newloop)
            onStartLoop?()
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
                    tabButtons.forEach { $0.removeFromParent() }
                    buildTabBar(y: size.height - 93)
                    buildBranchTree(for: selectedBranch)
                    run(SoundManager.shared.tap)
                }
                return
            }
        }
        
        // Scroll buttons
        if abs(loc.x - (size.width - 18)) < 14 && abs(loc.y - (contentTopY - 12)) < 12 {
            scrollBy(-110)
            return
        }
        if abs(loc.x - (size.width - 18)) < 14 && abs(loc.y - (contentBottomY + 12)) < 12 {
            scrollBy(110)
            return
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let deltaY = loc.y - lastTouchY
        lastTouchY = loc.y
        
        if !contentRect.contains(loc) { return }
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
        for node in TechTree.allNodes where node.branch == selectedBranch {
            guard let view = nodeViews[node.id] else { continue }
            let halfW = nodeWidth / 2
            let halfH = nodeHeight / 2
            if abs(loc.x - view.position.x) < halfW && abs(loc.y - view.position.y) < halfH {
                handleNodeTap(node)
                return
            }
        }
    }
    
    private func handleNodeTap(_ node: TechNode) {
        let state = meta.nodeState(node)
        if state == .affordable {
            if meta.purchase(node) {
                run(SoundManager.shared.build)
                updateKPLabel()
                buildBranchTree(for: selectedBranch)
            }
        } else {
            run(SoundManager.shared.tap)
        }
    }
    
    // MARK: - Scroll helpers
    
    private func scrollBy(_ amount: CGFloat) {
        guard maxScrollOffset > 0 else { return }
        scrollOffset = clamp(scrollOffset + amount, min: 0, max: maxScrollOffset)
        applyScroll()
    }
    
    private func applyScroll() {
        contentNode.position = CGPoint(x: 0, y: -scrollOffset)
    }
    
    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
    
    // MARK: - Helpers
    
    private func makeScrollButton(name: String, text: String, x: CGFloat, y: CGFloat) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: CGSize(width: 22, height: 20), cornerRadius: 6)
        btn.fillColor = SKColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 0.9)
        btn.strokeColor = SKColor(white: 0.2, alpha: 0.7)
        btn.lineWidth = 1
        btn.position = CGPoint(x: x, y: y)
        btn.zPosition = 20
        btn.name = name
        let lbl = SKLabelNode(fontNamed: "Menlo-Bold")
        lbl.text = text
        lbl.fontSize = 11
        lbl.fontColor = SKColor(white: 0.8, alpha: 1)
        lbl.verticalAlignmentMode = .center
        btn.addChild(lbl)
        return btn
    }
    
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
        let words = text.split(separator: " ")
        var lines: [String] = []
        var current = ""
        for word in words {
            let test = current.isEmpty ? String(word) : current + " " + word
            if test.count > maxChars && !current.isEmpty {
                lines.append(current)
                current = String(word)
            } else {
                current = test
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }
}
