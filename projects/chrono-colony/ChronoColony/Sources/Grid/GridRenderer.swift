import SpriteKit

/// Renders the grid and buildings as SpriteKit nodes
final class GridRenderer {
    let gridNode: SKNode
    private let tileSize: CGFloat
    private var tileNodes: [[SKShapeNode]] = []
    private var buildingLabels: [[SKLabelNode?]] = []
    private var workerIndicators: [[SKShapeNode?]] = []
    
    // Grid dimensions
    private let columns: Int
    private let rows: Int
    
    // Colors
    private let emptyColor = SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1)
    private let gridLineColor = SKColor(red: 0.25, green: 0.25, blue: 0.35, alpha: 1)
    private let metalVeinColor = SKColor(red: 0.5, green: 0.45, blue: 0.55, alpha: 1)
    private let biomassZoneColor = SKColor(red: 0.2, green: 0.4, blue: 0.25, alpha: 1)
    private let anomalyColor = SKColor(red: 0.6, green: 0.2, blue: 0.6, alpha: 1)
    private let selectedColor = SKColor(red: 0.9, green: 0.9, blue: 0.3, alpha: 0.4)
    
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
        
        for row in 0..<rows {
            var rowNodes: [SKShapeNode] = []
            var rowLabels: [SKLabelNode?] = []
            var rowIndicators: [SKShapeNode?] = []
            
            for col in 0..<columns {
                let x = offsetX + CGFloat(col) * tileSize
                let y = offsetY + CGFloat(row) * tileSize
                
                // Tile background
                let tile = SKShapeNode(rectOf: CGSize(width: tileSize - 2, height: tileSize - 2), cornerRadius: 4)
                tile.position = CGPoint(x: x, y: y)
                tile.fillColor = emptyColor
                tile.strokeColor = gridLineColor
                tile.lineWidth = 1
                tile.name = "tile_\(col)_\(row)"
                gridNode.addChild(tile)
                rowNodes.append(tile)
                
                // Building symbol label (hidden by default)
                let label = SKLabelNode(text: "")
                label.fontSize = tileSize * 0.5
                label.verticalAlignmentMode = .center
                label.horizontalAlignmentMode = .center
                label.position = CGPoint(x: x, y: y)
                label.zPosition = 1
                label.isHidden = true
                gridNode.addChild(label)
                rowLabels.append(label)
                
                // Worker indicator dot (hidden by default)
                let indicator = SKShapeNode(circleOfRadius: 4)
                indicator.position = CGPoint(x: x + tileSize * 0.3, y: y + tileSize * 0.3)
                indicator.fillColor = .green
                indicator.strokeColor = .clear
                indicator.zPosition = 2
                indicator.isHidden = true
                gridNode.addChild(indicator)
                rowIndicators.append(indicator)
            }
            
            tileNodes.append(rowNodes)
            buildingLabels.append(rowLabels)
            workerIndicators.append(rowIndicators)
        }
    }
    
    /// Update visual state from grid model
    func update(from grid: GridModel) {
        for row in 0..<rows {
            for col in 0..<columns {
                guard let tile = grid.tile(at: col, row: row) else { continue }
                let node = tileNodes[row][col]
                let label = buildingLabels[row][col]
                let indicator = workerIndicators[row][col]
                
                switch tile.content {
                case .empty:
                    node.fillColor = emptyColor
                    label?.isHidden = true
                    indicator?.isHidden = true
                    
                case .building(let type):
                    node.fillColor = type.color
                    label?.text = type.symbol
                    label?.isHidden = false
                    indicator?.isHidden = tile.assignedWorkers == 0
                    indicator?.fillColor = tile.isActive ? .green : .red
                    
                case .resourceDeposit(let deposit):
                    switch deposit {
                    case .metalVein:
                        node.fillColor = metalVeinColor
                        label?.text = "◆"
                        label?.isHidden = false
                    case .biomassZone:
                        node.fillColor = biomassZoneColor
                        label?.text = "♣"
                        label?.isHidden = false
                    case .anomaly:
                        node.fillColor = anomalyColor
                        label?.text = "?"
                        label?.isHidden = false
                    }
                    indicator?.isHidden = true
                    
                case .blocked:
                    node.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
                    label?.isHidden = true
                    indicator?.isHidden = true
                }
            }
        }
    }
    
    /// Highlight a tile (selection feedback)
    func highlightTile(col: Int, row: Int) {
        guard col >= 0, col < columns, row >= 0, row < rows else { return }
        let node = tileNodes[row][col]
        node.run(SKAction.sequence([
            SKAction.run { node.glowWidth = 3 },
            SKAction.wait(forDuration: 0.3),
            SKAction.run { node.glowWidth = 0 }
        ]))
    }
    
    /// Convert a scene point to grid coordinates
    func gridPosition(from point: CGPoint) -> (col: Int, row: Int)? {
        let totalWidth = CGFloat(columns) * tileSize
        let totalHeight = CGFloat(rows) * tileSize
        let originX = -totalWidth / 2
        let originY = -totalHeight / 2
        
        // Convert from grid node's coordinate space
        let localPoint = gridNode.convert(point, from: gridNode.scene!)
        
        let col = Int((localPoint.x - originX) / tileSize)
        let row = Int((localPoint.y - originY) / tileSize)
        
        guard col >= 0, col < columns, row >= 0, row < rows else { return nil }
        return (col, row)
    }
}
