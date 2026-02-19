import SpriteKit

/// Displays the tech tree between loops
/// Player spends Knowledge Points to unlock nodes
class TechTreeScene: SKScene {
    
    private var meta: MetaState!
    private var scrollNode: SKNode!
    private var kpLabel: SKLabelNode!
    private var nodeButtons: [String: SKNode] = [:]
    private var selectedNodeID: String?
    private var detailPanel: SKNode?
    
    // Layout
    private let branchSpacing: CGFloat = 80
    private let tierSpacing: CGFloat = 70
    private let nodeSize: CGFloat = 44
    
    // Callback
    var onStartLoop: (() -> Void)?
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.03, blue: 0.06, alpha: 1)
        meta = MetaState.load()
        
        buildUI()
    }
    
    private func buildUI() {
        // Title
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "TECH TREE"
        title.fontSize = 20
        title.fontColor = SKColor(red: 0.4, green: 0.75, blue: 1, alpha: 1)
        title.position = CGPoint(x: size.width / 2, y: size.height - 50)
        title.zPosition = 10
        addChild(title)
        
        // KP display
        kpLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        kpLabel.fontSize = 14
        kpLabel.fontColor = SKColor(red: 0.4, green: 0.9, blue: 1, alpha: 1)
        kpLabel.position = CGPoint(x: size.width / 2, y: size.height - 72)
        kpLabel.zPosition = 10
        addChild(kpLabel)
        updateKPLabel()
        
        // Stats
        let stats = SKLabelNode(fontNamed: "Menlo")
        stats.text = "Loops: \(meta.totalLoops)  •  Best: \(meta.bestLoopScore) KP"
        stats.fontSize = 10
        stats.fontColor = SKColor(white: 0.4, alpha: 1)
        stats.position = CGPoint(x: size.width / 2, y: size.height - 88)
        stats.zPosition = 10
        addChild(stats)
        
        // Scrollable tech tree area
        scrollNode = SKNode()
        scrollNode.position = CGPoint(x: 0, y: 0)
        addChild(scrollNode)
        
        buildTree()
        
        // Start Loop button at bottom
        let btnY: CGFloat = 40
        let startBtn = SKShapeNode(rectOf: CGSize(width: 180, height: 42), cornerRadius: 12)
        startBtn.fillColor = SKColor(red: 0.15, green: 0.4, blue: 0.2, alpha: 1)
        startBtn.strokeColor = SKColor(red: 0.25, green: 0.6, blue: 0.3, alpha: 1)
        startBtn.lineWidth = 1.5
        startBtn.position = CGPoint(x: size.width / 2, y: btnY)
        startBtn.zPosition = 10
        startBtn.name = "startLoopBtn"
        addChild(startBtn)
        
        let startLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        startLabel.text = "START NEW LOOP"
        startLabel.fontSize = 14
        startLabel.fontColor = .white
        startLabel.verticalAlignmentMode = .center
        startBtn.addChild(startLabel)
    }
    
    private func buildTree() {
        scrollNode.removeAllChildren()
        nodeButtons = [:]
        
        let branches = TechBranch.allCases
        let treeWidth = CGFloat(branches.count) * branchSpacing
        let startX = (size.width - treeWidth) / 2 + branchSpacing / 2
        let topY = size.height - 120
        
        for (bi, branch) in branches.enumerated() {
            let bx = startX + CGFloat(bi) * branchSpacing
            
            // Branch header
            let header = SKLabelNode(fontNamed: "Menlo-Bold")
            header.text = branch.symbol
            header.fontSize = 18
            header.position = CGPoint(x: bx, y: topY)
            header.zPosition = 5
            scrollNode.addChild(header)
            
            let branchLabel = SKLabelNode(fontNamed: "Menlo")
            branchLabel.text = branch.rawValue
            branchLabel.fontSize = 7
            branchLabel.fontColor = SKColor(white: 0.5, alpha: 1)
            branchLabel.position = CGPoint(x: bx, y: topY - 14)
            branchLabel.zPosition = 5
            scrollNode.addChild(branchLabel)
            
            // Locked indicator for temporal branch
            if branch == .temporal && !meta.isUnlocked("RES-08") {
                let lock = SKLabelNode(fontNamed: "Menlo")
                lock.text = "🔒"
                lock.fontSize = 14
                lock.position = CGPoint(x: bx, y: topY - 30)
                lock.zPosition = 5
                scrollNode.addChild(lock)
            }
            
            // Nodes in this branch
            let branchNodes = TechTree.allNodes.filter { $0.branch == branch }
            let tiers = Dictionary(grouping: branchNodes, by: { $0.tier })
            
            for tier in 1...3 {
                guard let nodesInTier = tiers[tier] else { continue }
                let tierY = topY - 40 - CGFloat(tier - 1) * tierSpacing
                
                let nodeCount = nodesInTier.count
                let subSpacing: CGFloat = nodeCount > 1 ? min(30, branchSpacing / CGFloat(nodeCount + 1)) : 0
                let subStartX = bx - subSpacing * CGFloat(nodeCount - 1) / 2
                
                for (ni, node) in nodesInTier.enumerated() {
                    let nx = subStartX + CGFloat(ni) * subSpacing
                    let ny = tierY
                    
                    let btn = createNodeButton(node: node, at: CGPoint(x: nx, y: ny))
                    scrollNode.addChild(btn)
                    nodeButtons[node.id] = btn
                }
            }
        }
        
        // Draw connection lines
        drawConnections()
    }
    
    private func createNodeButton(node: TechNode, at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.name = "techNode_\(node.id)"
        
        let state = meta.nodeState(node)
        
        // Background circle
        let bg = SKShapeNode(circleOfRadius: nodeSize / 2)
        bg.lineWidth = 2
        
        switch state {
        case .unlocked:
            bg.fillColor = SKColor(red: 0.1, green: 0.35, blue: 0.15, alpha: 1)
            bg.strokeColor = SKColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1)
        case .affordable:
            bg.fillColor = SKColor(red: 0.12, green: 0.15, blue: 0.25, alpha: 1)
            bg.strokeColor = SKColor(red: 0.4, green: 0.6, blue: 1, alpha: 1)
            bg.glowWidth = 3
        case .tooExpensive:
            bg.fillColor = SKColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)
            bg.strokeColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 0.6)
        case .locked:
            bg.fillColor = SKColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1)
            bg.strokeColor = SKColor(white: 0.15, alpha: 0.5)
        }
        container.addChild(bg)
        
        // Icon
        let icon = SKLabelNode(fontNamed: "Menlo-Bold")
        if state == .unlocked {
            icon.text = "✓"
            icon.fontColor = SKColor(red: 0.3, green: 0.9, blue: 0.3, alpha: 1)
        } else if node.unlocksBuilding {
            icon.text = "🏗"
        } else {
            icon.text = node.branch.symbol
        }
        icon.fontSize = 14
        icon.verticalAlignmentMode = .center
        icon.position = CGPoint(x: 0, y: 1)
        icon.zPosition = 1
        container.addChild(icon)
        
        // Cost label below
        if state != .unlocked {
            let costLabel = SKLabelNode(fontNamed: "Menlo")
            costLabel.text = "\(node.cost)"
            costLabel.fontSize = 8
            costLabel.fontColor = state == .affordable
                ? SKColor(red: 0.4, green: 0.9, blue: 1, alpha: 1)
                : SKColor(white: 0.35, alpha: 1)
            costLabel.position = CGPoint(x: 0, y: -nodeSize / 2 - 10)
            costLabel.zPosition = 1
            container.addChild(costLabel)
        }
        
        return container
    }
    
    private func drawConnections() {
        for node in TechTree.allNodes {
            guard let btnNode = nodeButtons[node.id] else { continue }
            for prereqID in node.prerequisites {
                guard let prereqNode = nodeButtons[prereqID] else { continue }
                
                let line = SKShapeNode()
                let path = CGMutablePath()
                path.move(to: prereqNode.position)
                path.addLine(to: btnNode.position)
                line.path = path
                
                let isActive = meta.isUnlocked(prereqID)
                line.strokeColor = isActive
                    ? SKColor(red: 0.3, green: 0.6, blue: 0.3, alpha: 0.5)
                    : SKColor(white: 0.15, alpha: 0.3)
                line.lineWidth = isActive ? 1.5 : 0.75
                line.zPosition = -1
                scrollNode.addChild(line)
            }
        }
    }
    
    // MARK: - Touch
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Start loop button
        if let startBtn = childNode(withName: "startLoopBtn"), startBtn.contains(location) {
            run(SoundManager.shared.newloop)
            onStartLoop?()
            return
        }
        
        // Tech nodes
        let scrollLocation = touch.location(in: scrollNode)
        for (nodeID, btn) in nodeButtons {
            let distance = hypot(scrollLocation.x - btn.position.x, scrollLocation.y - btn.position.y)
            if distance < nodeSize / 2 + 5 {
                handleNodeTap(nodeID: nodeID)
                return
            }
        }
        
        // Dismiss detail panel
        dismissDetail()
    }
    
    private func handleNodeTap(nodeID: String) {
        guard let node = TechTree.nodeMap[nodeID] else { return }
        let state = meta.nodeState(node)
        
        if state == .affordable {
            // Purchase
            if meta.purchase(node) {
                run(SoundManager.shared.build)
                buildTree()
                updateKPLabel()
            }
        } else if state == .unlocked {
            // Already owned — show info
            showDetail(for: node)
        } else {
            // Show info
            run(SoundManager.shared.tap)
            showDetail(for: node)
        }
    }
    
    private func showDetail(for node: TechNode) {
        dismissDetail()
        
        let state = meta.nodeState(node)
        let panel = SKNode()
        panel.zPosition = 20
        panel.name = "detailPanel"
        
        let bg = SKShapeNode(rectOf: CGSize(width: size.width * 0.85, height: 100), cornerRadius: 12)
        bg.fillColor = SKColor(red: 0.08, green: 0.08, blue: 0.14, alpha: 0.95)
        bg.strokeColor = SKColor(red: 0.2, green: 0.25, blue: 0.4, alpha: 1)
        bg.lineWidth = 1.5
        bg.position = CGPoint(x: size.width / 2, y: 110)
        panel.addChild(bg)
        
        let nameLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        nameLabel.text = "\(node.branch.symbol) \(node.name)"
        nameLabel.fontSize = 13
        nameLabel.fontColor = state == .unlocked ? SKColor(red: 0.3, green: 0.9, blue: 0.3, alpha: 1) : .white
        nameLabel.position = CGPoint(x: 0, y: 25)
        bg.addChild(nameLabel)
        
        let descLabel = SKLabelNode(fontNamed: "Menlo")
        descLabel.text = node.description
        descLabel.fontSize = 10
        descLabel.fontColor = SKColor(white: 0.7, alpha: 1)
        descLabel.position = CGPoint(x: 0, y: 5)
        bg.addChild(descLabel)
        
        let statusText: String
        switch state {
        case .unlocked: statusText = "✅ Unlocked"
        case .affordable: statusText = "Tap to purchase — \(node.cost) KP"
        case .tooExpensive: statusText = "Need \(node.cost) KP (have \(meta.knowledgePoints))"
        case .locked:
            let missing = node.prerequisites.filter { !meta.isUnlocked($0) }
                .compactMap { TechTree.nodeMap[$0]?.name }
            statusText = "Requires: \(missing.joined(separator: ", "))"
        }
        
        let statusLabel = SKLabelNode(fontNamed: "Menlo")
        statusLabel.text = statusText
        statusLabel.fontSize = 9
        statusLabel.fontColor = SKColor(white: 0.45, alpha: 1)
        statusLabel.position = CGPoint(x: 0, y: -18)
        bg.addChild(statusLabel)
        
        addChild(panel)
        detailPanel = panel
        
        panel.alpha = 0
        panel.run(SKAction.fadeIn(withDuration: 0.15))
    }
    
    private func dismissDetail() {
        detailPanel?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.removeFromParent()
        ]))
        detailPanel = nil
    }
    
    private func updateKPLabel() {
        let unlocked = meta.unlockedTechIDs.count
        let total = TechTree.allNodes.count
        kpLabel.text = "💡 \(meta.knowledgePoints) KP  •  \(unlocked)/\(total) unlocked"
    }
}
