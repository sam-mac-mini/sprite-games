import SpriteKit

/// Displays the tech tree between loops — tabbed layout with scrollable node lists
class TechTreeScene: SKScene {
    
    private var meta: MetaState!
    private var kpLabel: SKLabelNode!
    private var contentNode: SKNode!
    private var tabButtons: [SKShapeNode] = []
    private var selectedBranch: TechBranch = .infrastructure
    
    // Scroll state
    private var scrollOffset: CGFloat = 0
    private var maxScrollOffset: CGFloat = 0
    private var lastTouchY: CGFloat = 0
    private var isDragging = false
    
    // Layout constants
    private let tabBarY: CGFloat = 0  // Set in didMove
    private let contentTopY: CGFloat = 0
    private let contentBottomY: CGFloat = 0
    private let cardHeight: CGFloat = 90
    private let cardSpacing: CGFloat = 10
    
    // Callback
    var onStartLoop: (() -> Void)?
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.03, blue: 0.06, alpha: 1)
        meta = MetaState.load()
        buildUI()
    }
    
    private func buildUI() {
        removeAllChildren()
        
        // Title
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "TECH TREE"
        title.fontSize = 18
        title.fontColor = SKColor(red: 0.4, green: 0.75, blue: 1, alpha: 1)
        title.position = CGPoint(x: size.width / 2, y: size.height - 35)
        title.zPosition = 10
        addChild(title)
        
        // KP display
        kpLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        kpLabel.fontSize = 13
        kpLabel.fontColor = SKColor(red: 0.4, green: 0.9, blue: 1, alpha: 1)
        kpLabel.position = CGPoint(x: size.width / 2, y: size.height - 54)
        kpLabel.zPosition = 10
        addChild(kpLabel)
        updateKPLabel()
        
        // Stats
        let stats = SKLabelNode(fontNamed: "Menlo")
        stats.text = "Loops: \(meta.totalLoops)  •  Best: \(meta.bestLoopScore) KP"
        stats.fontSize = 9
        stats.fontColor = SKColor(white: 0.4, alpha: 1)
        stats.position = CGPoint(x: size.width / 2, y: size.height - 68)
        stats.zPosition = 10
        addChild(stats)
        
        // Tab bar
        buildTabBar(y: size.height - 95)
        
        // Content area (scrollable) — between tab bar and start button
        contentNode = SKNode()
        contentNode.zPosition = 5
        addChild(contentNode)
        
        // Clipping mask for scroll area
        let cropNode = SKCropNode()
        let maskHeight = size.height - 170
        let mask = SKSpriteNode(color: .white, size: CGSize(width: size.width, height: maskHeight))
        mask.position = CGPoint(x: size.width / 2, y: 70 + maskHeight / 2)
        cropNode.maskNode = mask
        cropNode.zPosition = 5
        cropNode.addChild(contentNode)
        addChild(cropNode)
        
        // Start Loop button at bottom
        let startBtn = SKShapeNode(rectOf: CGSize(width: 200, height: 40), cornerRadius: 12)
        startBtn.fillColor = SKColor(red: 0.15, green: 0.4, blue: 0.2, alpha: 1)
        startBtn.strokeColor = SKColor(red: 0.25, green: 0.6, blue: 0.3, alpha: 1)
        startBtn.lineWidth = 1.5
        startBtn.position = CGPoint(x: size.width / 2, y: 35)
        startBtn.zPosition = 10
        startBtn.name = "startLoopBtn"
        addChild(startBtn)
        
        let startLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        startLabel.text = "▶ START NEW LOOP"
        startLabel.fontSize = 13
        startLabel.fontColor = .white
        startLabel.verticalAlignmentMode = .center
        startBtn.addChild(startLabel)
        
        // Build content for initial tab
        buildContent(for: selectedBranch)
    }
    
    // MARK: - Tab Bar
    
    private func buildTabBar(y: CGFloat) {
        tabButtons = []
        let branches = TechBranch.allCases
        let tabWidth = (size.width - 16) / CGFloat(branches.count)
        let startX: CGFloat = 8 + tabWidth / 2
        
        for (i, branch) in branches.enumerated() {
            let tx = startX + CGFloat(i) * tabWidth
            let isSelected = branch == selectedBranch
            
            let tab = SKShapeNode(rectOf: CGSize(width: tabWidth - 4, height: 28), cornerRadius: 8)
            tab.fillColor = isSelected
                ? branchColor(branch).withAlphaComponent(0.3)
                : SKColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.8)
            tab.strokeColor = isSelected
                ? branchColor(branch)
                : SKColor(white: 0.15, alpha: 0.5)
            tab.lineWidth = isSelected ? 1.5 : 0.75
            tab.position = CGPoint(x: tx, y: y)
            tab.zPosition = 10
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
    
    // MARK: - Content (Scrollable Node List)
    
    private func buildContent(for branch: TechBranch) {
        contentNode.removeAllChildren()
        scrollOffset = 0
        
        let nodes = TechTree.allNodes.filter { $0.branch == branch }.sorted { $0.tier < $1.tier }
        let cardWidth = size.width - 24
        let contentTop = size.height - 120
        
        for (i, node) in nodes.enumerated() {
            let cardY = contentTop - CGFloat(i) * (cardHeight + cardSpacing)
            let card = createNodeCard(node: node, width: cardWidth, at: CGPoint(x: size.width / 2, y: cardY))
            contentNode.addChild(card)
        }
        
        // Calculate scroll bounds
        let totalHeight = CGFloat(nodes.count) * (cardHeight + cardSpacing)
        let visibleHeight = size.height - 170
        maxScrollOffset = max(0, totalHeight - visibleHeight)
    }
    
    private func createNodeCard(node: TechNode, width: CGFloat, at position: CGPoint) -> SKNode {
        let state = meta.nodeState(node)
        
        let card = SKShapeNode(rectOf: CGSize(width: width, height: cardHeight), cornerRadius: 12)
        card.position = position
        card.name = "card_\(node.id)"
        
        // Card styling based on state
        switch state {
        case .unlocked:
            card.fillColor = SKColor(red: 0.08, green: 0.18, blue: 0.08, alpha: 0.95)
            card.strokeColor = SKColor(red: 0.25, green: 0.6, blue: 0.25, alpha: 0.8)
        case .affordable:
            card.fillColor = SKColor(red: 0.08, green: 0.1, blue: 0.2, alpha: 0.95)
            card.strokeColor = SKColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 0.9)
            card.glowWidth = 2
        case .tooExpensive:
            card.fillColor = SKColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.9)
            card.strokeColor = SKColor(white: 0.2, alpha: 0.5)
        case .locked:
            card.fillColor = SKColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 0.8)
            card.strokeColor = SKColor(white: 0.1, alpha: 0.3)
        }
        card.lineWidth = 1.5
        
        // Left side: Status icon
        let statusIcon = SKLabelNode(fontNamed: "Menlo-Bold")
        switch state {
        case .unlocked: statusIcon.text = "✅"
        case .affordable: statusIcon.text = "💡"
        case .tooExpensive: statusIcon.text = "🔒"
        case .locked: statusIcon.text = "⛔"
        }
        statusIcon.fontSize = 18
        statusIcon.verticalAlignmentMode = .center
        statusIcon.position = CGPoint(x: -width / 2 + 22, y: 10)
        card.addChild(statusIcon)
        
        // Tier badge
        let tierBadge = SKLabelNode(fontNamed: "Menlo")
        tierBadge.text = "T\(node.tier)"
        tierBadge.fontSize = 8
        tierBadge.fontColor = SKColor(white: 0.35, alpha: 1)
        tierBadge.verticalAlignmentMode = .center
        tierBadge.position = CGPoint(x: -width / 2 + 22, y: -10)
        card.addChild(tierBadge)
        
        // Name
        let nameLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        nameLabel.text = node.name
        nameLabel.fontSize = 12
        nameLabel.fontColor = state == .unlocked
            ? SKColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 1)
            : (state == .locked ? SKColor(white: 0.3, alpha: 1) : .white)
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: -width / 2 + 46, y: 22)
        card.addChild(nameLabel)
        
        // Description (word-wrapped)
        let maxDescChars = Int((width - 80) / 6.5)
        let descLines = wordWrap(node.description, maxChars: maxDescChars)
        for (li, line) in descLines.prefix(2).enumerated() {
            let descLabel = SKLabelNode(fontNamed: "Menlo")
            descLabel.text = line
            descLabel.fontSize = 9
            descLabel.fontColor = state == .locked ? SKColor(white: 0.2, alpha: 1) : SKColor(white: 0.55, alpha: 1)
            descLabel.horizontalAlignmentMode = .left
            descLabel.verticalAlignmentMode = .center
            descLabel.position = CGPoint(x: -width / 2 + 46, y: 6 - CGFloat(li) * 13)
            card.addChild(descLabel)
        }
        
        // Right side: Cost or status
        let costLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        costLabel.horizontalAlignmentMode = .right
        costLabel.verticalAlignmentMode = .center
        costLabel.position = CGPoint(x: width / 2 - 12, y: 10)
        costLabel.fontSize = 12
        
        switch state {
        case .unlocked:
            costLabel.text = "OWNED"
            costLabel.fontColor = SKColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 0.7)
            costLabel.fontSize = 10
        case .affordable:
            costLabel.text = "\(node.cost) KP"
            costLabel.fontColor = SKColor(red: 0.4, green: 0.9, blue: 1, alpha: 1)
        case .tooExpensive:
            costLabel.text = "\(node.cost) KP"
            costLabel.fontColor = SKColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 0.7)
        case .locked:
            costLabel.text = "\(node.cost) KP"
            costLabel.fontColor = SKColor(white: 0.2, alpha: 1)
        }
        card.addChild(costLabel)
        
        // Requirements (for locked nodes)
        if state == .locked || state == .tooExpensive {
            let missing = node.prerequisites.filter { !meta.isUnlocked($0) }
                .compactMap { TechTree.nodeMap[$0]?.name }
            if !missing.isEmpty {
                let reqLabel = SKLabelNode(fontNamed: "Menlo")
                reqLabel.text = "Needs: \(missing.joined(separator: ", "))"
                reqLabel.fontSize = 8
                reqLabel.fontColor = SKColor(white: 0.3, alpha: 1)
                reqLabel.horizontalAlignmentMode = .right
                reqLabel.verticalAlignmentMode = .center
                reqLabel.position = CGPoint(x: width / 2 - 12, y: -8)
                card.addChild(reqLabel)
            }
        }
        
        // Purchase hint for affordable
        if state == .affordable {
            let tapHint = SKLabelNode(fontNamed: "Menlo")
            tapHint.text = "TAP TO UNLOCK"
            tapHint.fontSize = 8
            tapHint.fontColor = SKColor(red: 0.3, green: 0.6, blue: 1, alpha: 0.8)
            tapHint.horizontalAlignmentMode = .right
            tapHint.verticalAlignmentMode = .center
            tapHint.position = CGPoint(x: width / 2 - 12, y: -8)
            card.addChild(tapHint)
            
            // Subtle pulse
            tapHint.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.4, duration: 0.8),
                SKAction.fadeAlpha(to: 1.0, duration: 0.8)
            ])))
        }
        
        return card
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchY = location.y
        isDragging = false
        
        // Start loop button
        let startBtnPos = CGPoint(x: size.width / 2, y: 35)
        if abs(location.x - startBtnPos.x) < 100 && abs(location.y - startBtnPos.y) < 20 {
            run(SoundManager.shared.newloop)
            onStartLoop?()
            return
        }
        
        // Tab buttons
        for (i, tab) in tabButtons.enumerated() {
            let halfW = (size.width - 16) / CGFloat(TechBranch.allCases.count) / 2
            if abs(location.x - tab.position.x) < halfW && abs(location.y - tab.position.y) < 14 {
                let branch = TechBranch.allCases[i]
                if branch != selectedBranch {
                    selectedBranch = branch
                    // Rebuild tabs and content
                    tabButtons.forEach { $0.removeFromParent() }
                    buildTabBar(y: size.height - 95)
                    buildContent(for: branch)
                    run(SoundManager.shared.tap)
                }
                return
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let deltaY = location.y - lastTouchY
        lastTouchY = location.y
        
        if abs(deltaY) > 2 { isDragging = true }
        
        if isDragging && maxScrollOffset > 0 {
            scrollOffset = min(maxScrollOffset, max(0, scrollOffset - deltaY))
            contentNode.position = CGPoint(x: 0, y: -scrollOffset)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // Only handle taps (not drags)
        if isDragging { return }
        
        let location = touch.location(in: contentNode)
        
        // Check card taps
        let nodes = TechTree.allNodes.filter { $0.branch == selectedBranch }.sorted { $0.tier < $1.tier }
        let cardWidth = size.width - 24
        
        for node in nodes {
            if let card = contentNode.childNode(withName: "card_\(node.id)") {
                let halfW = cardWidth / 2
                let halfH = cardHeight / 2
                if abs(location.x - card.position.x) < halfW && abs(location.y - card.position.y) < halfH {
                    handleCardTap(node: node)
                    return
                }
            }
        }
    }
    
    private func handleCardTap(node: TechNode) {
        let state = meta.nodeState(node)
        if state == .affordable {
            if meta.purchase(node) {
                run(SoundManager.shared.build)
                updateKPLabel()
                buildContent(for: selectedBranch)
            }
        } else {
            run(SoundManager.shared.tap)
        }
    }
    
    // MARK: - Helpers
    
    private func updateKPLabel() {
        let unlocked = meta.unlockedTechIDs.count
        let total = TechTree.allNodes.count
        kpLabel.text = "💡 \(meta.knowledgePoints) KP  •  \(unlocked)/\(total) unlocked"
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
