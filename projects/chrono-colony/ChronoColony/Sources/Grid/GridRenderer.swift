import SpriteKit

/// Renders the grid and buildings as SpriteKit nodes
final class GridRenderer {
    let gridNode: SKNode
    private let tileSize: CGFloat
    private var tileNodes: [[SKShapeNode]] = []
    private var buildingLabels: [[SKLabelNode?]] = []
    private var buildingSpriteNodes: [[SKNode?]] = []
    private var depositSpriteNodes: [[SKNode?]] = []
    private var workerNodes: [[SKNode?]] = []
    private var selectionNode: SKShapeNode?
    private var bonusIndicators: [[SKNode?]] = []
    /// Track what was last rendered per tile to avoid rebuild every frame
    private var lastRenderedContent: [[String]] = []
    
    // Grid dimensions
    private let columns: Int
    private let rows: Int
    
    // Colors
    private let emptyColor = SKColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1)
    private let gridLineColor = SKColor(red: 0.2, green: 0.2, blue: 0.28, alpha: 0.6)
    private let metalVeinColor = SKColor(red: 0.35, green: 0.32, blue: 0.45, alpha: 1)
    private let biomassZoneColor = SKColor(red: 0.15, green: 0.3, blue: 0.18, alpha: 1)
    private let anomalyColor = SKColor(red: 0.45, green: 0.15, blue: 0.5, alpha: 1)
    
    init(columns: Int, rows: Int, tileSize: CGFloat) {
        self.columns = columns
        self.rows = rows
        self.tileSize = tileSize
        self.gridNode = SKNode()
        gridNode.name = "grid"
        
        buildGrid()
    }
    
    private func buildGrid() {
        let totalWidth = CGFloat(columns) * tileSize
        let totalHeight = CGFloat(rows) * tileSize
        let offsetX = -totalWidth / 2 + tileSize / 2
        let offsetY = -totalHeight / 2 + tileSize / 2
        
        // Grid background — subtle frame
        let bg = SKShapeNode(rectOf: CGSize(width: totalWidth + 4, height: totalHeight + 4), cornerRadius: 6)
        bg.fillColor = SKColor(red: 0.15, green: 0.12, blue: 0.08, alpha: 1)
        bg.strokeColor = SKColor(red: 0.3, green: 0.25, blue: 0.18, alpha: 0.5)
        bg.lineWidth = 1
        bg.zPosition = -1
        gridNode.addChild(bg)
        
        for row in 0..<rows {
            var rowNodes: [SKShapeNode] = []
            var rowLabels: [SKLabelNode?] = []
            var rowBuildingSprites: [SKNode?] = []
            var rowDepositSprites: [SKNode?] = []
            var rowWorkers: [SKNode?] = []
            var rowBonuses: [SKNode?] = []
            
            for col in 0..<columns {
                let x = offsetX + CGFloat(col) * tileSize
                let y = offsetY + CGFloat(row) * tileSize
                
                // Tile background
                let tile = SKShapeNode(rectOf: CGSize(width: tileSize - 1, height: tileSize - 1), cornerRadius: 2)
                tile.position = CGPoint(x: x, y: y)
                tile.fillColor = .clear
                tile.strokeColor = SKColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 0.4)
                tile.lineWidth = 0.75
                tile.zPosition = 0.8  // Above ground textures
                tile.name = "tile_\(col)_\(row)"
                gridNode.addChild(tile)
                rowNodes.append(tile)
                
                // Building symbol label (hidden by default)
                let label = SKLabelNode(text: "")
                label.fontSize = tileSize * 0.45
                label.verticalAlignmentMode = .center
                label.horizontalAlignmentMode = .center
                label.position = CGPoint(x: x, y: y + 2)
                label.zPosition = 1
                label.isHidden = true
                gridNode.addChild(label)
                rowLabels.append(label)
                
                // Building sprite container (hidden by default)
                let buildingSpriteContainer = SKNode()
                buildingSpriteContainer.position = CGPoint(x: x, y: y)
                buildingSpriteContainer.zPosition = 1.0
                buildingSpriteContainer.isHidden = true
                gridNode.addChild(buildingSpriteContainer)
                rowBuildingSprites.append(buildingSpriteContainer)
                
                // Deposit sprite container (also used for ground on empty tiles)
                let depositSpriteContainer = SKNode()
                depositSpriteContainer.position = CGPoint(x: x, y: y)
                depositSpriteContainer.zPosition = 0.5
                depositSpriteContainer.isHidden = true
                gridNode.addChild(depositSpriteContainer)
                rowDepositSprites.append(depositSpriteContainer)
                
                // Worker node container (hidden by default)
                let workerContainer = SKNode()
                workerContainer.position = CGPoint(x: x, y: y)
                workerContainer.zPosition = 2
                workerContainer.isHidden = true
                gridNode.addChild(workerContainer)
                rowWorkers.append(workerContainer)
                
                // Adjacency bonus indicator (hidden by default)
                let bonusNode = SKNode()
                bonusNode.position = CGPoint(x: x, y: y)
                bonusNode.zPosition = 3
                bonusNode.isHidden = true
                gridNode.addChild(bonusNode)
                
                // Glow border for bonus
                let glow = SKShapeNode(rectOf: CGSize(width: tileSize - 1, height: tileSize - 1), cornerRadius: 4)
                glow.fillColor = .clear
                glow.strokeColor = SKColor(red: 0.2, green: 0.9, blue: 0.5, alpha: 0.6)
                glow.lineWidth = 1.5
                glow.glowWidth = 2
                glow.name = "bonusGlow"
                bonusNode.addChild(glow)
                
                // Small multiplier label
                let bonusLabel = SKLabelNode(fontNamed: "Menlo-Bold")
                bonusLabel.fontSize = tileSize * 0.2
                bonusLabel.fontColor = SKColor(red: 0.3, green: 1, blue: 0.5, alpha: 0.9)
                bonusLabel.position = CGPoint(x: -tileSize * 0.32, y: tileSize * 0.28)
                bonusLabel.horizontalAlignmentMode = .left
                bonusLabel.verticalAlignmentMode = .center
                bonusLabel.name = "bonusLabel"
                bonusNode.addChild(bonusLabel)
                
                rowBonuses.append(bonusNode)
            }
            
            tileNodes.append(rowNodes)
            buildingLabels.append(rowLabels)
            buildingSpriteNodes.append(rowBuildingSprites)
            depositSpriteNodes.append(rowDepositSprites)
            workerNodes.append(rowWorkers)
            bonusIndicators.append(rowBonuses)
        }
        lastRenderedContent = Array(repeating: Array(repeating: "", count: columns), count: rows)
        
        // Selection highlight node
        selectionNode = SKShapeNode(rectOf: CGSize(width: tileSize + 2, height: tileSize + 2), cornerRadius: 5)
        selectionNode?.fillColor = .clear
        selectionNode?.strokeColor = SKColor(red: 0.9, green: 0.9, blue: 0.3, alpha: 0.8)
        selectionNode?.lineWidth = 2
        selectionNode?.zPosition = 10
        selectionNode?.isHidden = true
        selectionNode?.glowWidth = 3
        gridNode.addChild(selectionNode!)
    }
    
    /// Update visual state from grid model
    func update(from grid: GridModel, state: GameState) {
        for row in 0..<rows {
            for col in 0..<columns {
                guard let tile = grid.tile(at: col, row: row) else { continue }
                let node = tileNodes[row][col]
                let label = buildingLabels[row][col]
                let workerContainer = workerNodes[row][col]
                let bonusNode = bonusIndicators[row][col]
                let buildingSprite = buildingSpriteNodes[row][col]
                let depositSprite = depositSpriteNodes[row][col]
                
                switch tile.content {
                case .empty:
                    node.fillColor = .clear
                    label?.isHidden = true
                    workerContainer?.isHidden = true
                    bonusNode?.isHidden = true
                    buildingSprite?.isHidden = true
                    depositSprite?.isHidden = true
                    // Show ground texture for empty tiles
                    let emptyKey = "empty"
                    if lastRenderedContent[row][col] != emptyKey {
                        // Use alternating ground tiles for visual variety
                        let useAlt = (col + row) % 3 == 0
                        let groundName = useAlt ? "groundTileAlt" : "groundTile"
                        // Reuse depositSprite container for ground display on empty tiles
                        depositSprite?.removeAllChildren()
                        let ground = SKSpriteNode(imageNamed: groundName)
                        ground.size = CGSize(width: tileSize, height: tileSize)
                        depositSprite?.addChild(ground)
                        depositSprite?.isHidden = false
                        lastRenderedContent[row][col] = emptyKey
                    } else {
                        depositSprite?.isHidden = false
                    }
                    
                case .building(let type):
                    // Ground tile behind building
                    node.fillColor = .clear
                    label?.isHidden = true
                    depositSprite?.isHidden = true
                    
                    // Show building sprite (only rebuild if changed)
                    let contentKey = "b_\(type.rawValue)_\(tile.isDisabled)"
                    if lastRenderedContent[row][col] != contentKey {
                        buildingSprite?.removeAllChildren()
                        
                        // Ground tile underneath
                        let ground = SKSpriteNode(imageNamed: "groundTile")
                        ground.size = CGSize(width: tileSize, height: tileSize)
                        buildingSprite?.addChild(ground)
                        
                        // Building texture — scaled up to compensate for transparent padding
                        let bSprite = SKSpriteNode(imageNamed: type.imageName)
                        bSprite.size = CGSize(width: tileSize * 1.5, height: tileSize * 1.5)
                        bSprite.alpha = tile.isDisabled ? 0.35 : 1.0
                        buildingSprite?.addChild(bSprite)
                        
                        lastRenderedContent[row][col] = contentKey
                    }
                    // Update alpha live for disable toggle
                    if let bSprite = buildingSprite?.children.last as? SKSpriteNode {
                        bSprite.alpha = tile.isDisabled ? 0.35 : 1.0
                    }
                    buildingSprite?.isHidden = false
                    
                    // Worker visualization
                    updateWorkerDisplay(container: workerContainer, workers: tile.assignedWorkers, isActive: tile.isActive, isDisabled: tile.isDisabled)
                    
                    // Adjacency bonus indicator
                    let mult = grid.adjacencyMultiplier(col: col, row: row)
                    if mult > 1.01 {
                        bonusNode?.isHidden = false
                        if let bonusLabel = bonusNode?.childNode(withName: "bonusLabel") as? SKLabelNode {
                            let pct = Int((mult - 1.0) * 100)
                            bonusLabel.text = "+\(pct)%"
                        }
                    } else {
                        bonusNode?.isHidden = true
                    }
                    
                case .resourceDeposit(let deposit):
                    node.fillColor = .clear
                    label?.isHidden = true
                    buildingSprite?.isHidden = true
                    
                    let depositImageName: String
                    switch deposit {
                    case .metalVein: depositImageName = "metalVein"
                    case .biomassZone: depositImageName = "biomassZone"
                    case .anomaly: depositImageName = "anomaly"
                    }
                    
                    let depositKey = "d_\(deposit)"
                    if lastRenderedContent[row][col] != depositKey {
                        depositSprite?.removeAllChildren()
                        
                        // Ground tile underneath
                        let ground = SKSpriteNode(imageNamed: "groundTile")
                        ground.size = CGSize(width: tileSize, height: tileSize)
                        depositSprite?.addChild(ground)
                        
                        // Deposit texture — scaled up, z above ground
                        let depSprite = SKSpriteNode(imageNamed: depositImageName)
                        depSprite.size = CGSize(width: tileSize * 1.6, height: tileSize * 1.6)
                        depSprite.zPosition = 0.5
                        depositSprite?.addChild(depSprite)
                        
                        lastRenderedContent[row][col] = depositKey
                    }
                    depositSprite?.isHidden = false
                    
                    workerContainer?.isHidden = true
                    bonusNode?.isHidden = true
                    
                case .blocked:
                    node.fillColor = SKColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1)
                    label?.isHidden = true
                    workerContainer?.isHidden = true
                    bonusNode?.isHidden = true
                    buildingSprite?.isHidden = true
                    depositSprite?.isHidden = true
                }
            }
        }
        
        // Escalation visual: subtle red tint on grid border
        if state.phase == .escalation {
            let pulse = abs(sin(state.elapsedTime * 2)) * 0.3
            if let bg = gridNode.children.first as? SKShapeNode {
                bg.strokeColor = SKColor(red: 0.8, green: 0.2 + pulse, blue: 0.2, alpha: 0.8)
            }
        }
    }
    
    private func updateWorkerDisplay(container: SKNode?, workers: Int, isActive: Bool, isDisabled: Bool) {
        guard let container = container else { return }
        container.removeAllChildren()
        
        if workers > 0 {
            container.isHidden = false
            
            // Worker dots at bottom of tile
            for i in 0..<workers {
                let dot = SKShapeNode(circleOfRadius: 3)
                if isDisabled {
                    dot.fillColor = SKColor(red: 0.6, green: 0.5, blue: 0.2, alpha: 0.8)
                } else if isActive {
                    dot.fillColor = SKColor(red: 0.3, green: 0.9, blue: 0.3, alpha: 1)
                } else {
                    dot.fillColor = SKColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1)
                }
                dot.strokeColor = .clear
                dot.position = CGPoint(x: CGFloat(i) * 8 - CGFloat(workers - 1) * 4, y: -tileSize * 0.32)
                container.addChild(dot)
            }
            
            // Worker count badge (show count if >1)
            let badge = SKLabelNode(fontNamed: "Menlo-Bold")
            badge.text = workers > 1 ? "WRK×\(workers)" : "WRK"
            badge.fontSize = tileSize * 0.15
            badge.position = CGPoint(x: tileSize * 0.25, y: tileSize * 0.28)
            badge.verticalAlignmentMode = .center
            badge.horizontalAlignmentMode = .center
            container.addChild(badge)
        } else {
            container.isHidden = true
        }
    }
    
    /// Highlight a tile temporarily
    func highlightTile(col: Int, row: Int, color: SKColor) {
        guard col >= 0, col < columns, row >= 0, row < rows else { return }
        let node = tileNodes[row][col]
        let originalColor = node.fillColor
        
        node.run(SKAction.sequence([
            SKAction.customAction(withDuration: 0.15) { n, _ in
                (n as? SKShapeNode)?.fillColor = color.withAlphaComponent(0.5)
            },
            SKAction.customAction(withDuration: 0.3) { n, t in
                (n as? SKShapeNode)?.fillColor = originalColor
            }
        ]))
    }
    
    /// Select a tile (persistent highlight)
    func selectTile(col: Int, row: Int) {
        guard col >= 0, col < columns, row >= 0, row < rows else { return }
        let node = tileNodes[row][col]
        selectionNode?.position = node.position
        selectionNode?.isHidden = false
    }
    
    func clearSelection() {
        selectionNode?.isHidden = true
    }
    
    /// Placement animation
    func animatePlacement(col: Int, row: Int) {
        guard col >= 0, col < columns, row >= 0, row < rows else { return }
        let node = tileNodes[row][col]
        node.run(SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.15)
        ]))
    }
    
    /// Collapse animation — buildings shake and fade
    func animateCollapse() {
        for row in 0..<rows {
            for col in 0..<columns {
                let node = tileNodes[row][col]
                let delay = Double.random(in: 0...1.5)
                
                node.run(SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    SKAction.group([
                        SKAction.sequence([
                            SKAction.moveBy(x: 2, y: -1, duration: 0.05),
                            SKAction.moveBy(x: -4, y: 2, duration: 0.05),
                            SKAction.moveBy(x: 2, y: -1, duration: 0.05),
                        ]),
                        SKAction.fadeAlpha(to: 0.2, duration: 0.3)
                    ]),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.5) // Restore for next loop
                ]))
            }
        }
    }
    
    /// Convert a scene point to grid coordinates
    func gridPosition(from localPoint: CGPoint) -> (col: Int, row: Int)? {
        let totalWidth = CGFloat(columns) * tileSize
        let totalHeight = CGFloat(rows) * tileSize
        let originX = -totalWidth / 2
        let originY = -totalHeight / 2
        
        let col = Int((localPoint.x - originX) / tileSize)
        let row = Int((localPoint.y - originY) / tileSize)
        
        guard col >= 0, col < columns, row >= 0, row < rows else { return nil }
        return (col, row)
    }
    
    /// Get world position for a grid cell
    func worldPosition(col: Int, row: Int) -> CGPoint? {
        guard col >= 0, col < columns, row >= 0, row < rows else { return nil }
        let totalWidth = CGFloat(columns) * tileSize
        let totalHeight = CGFloat(rows) * tileSize
        let offsetX = -totalWidth / 2 + tileSize / 2
        let offsetY = -totalHeight / 2 + tileSize / 2
        
        let localPos = CGPoint(
            x: offsetX + CGFloat(col) * tileSize,
            y: offsetY + CGFloat(row) * tileSize
        )
        return gridNode.convert(localPos, to: gridNode.parent!)
    }
}
