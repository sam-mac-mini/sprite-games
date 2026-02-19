import SpriteKit

/// Shows info about a selected building
final class InfoPanelRenderer {
    let node: SKNode
    
    init(buildingType: BuildingType, tile: Tile, adjacencyMultiplier: Double = 1.0, sceneSize: CGSize) {
        node = SKNode()
        node.zPosition = 150
        node.name = "infoPanel"
        
        let hasBonus = adjacencyMultiplier > 1.01
        let panelWidth: CGFloat = sceneSize.width * 0.7
        let panelHeight: CGFloat = hasBonus ? 140 : 120
        
        // Background
        let bg = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 12)
        bg.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 0.95)
        bg.strokeColor = SKColor(red: 0.3, green: 0.35, blue: 0.5, alpha: 1)
        bg.lineWidth = 1.5
        bg.position = CGPoint(x: 0, y: 0)
        node.addChild(bg)
        
        // Title
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "\(buildingType.symbol) \(buildingType.rawValue)"
        title.fontSize = 15
        title.fontColor = buildingType.color
        title.position = CGPoint(x: 0, y: 32)
        title.horizontalAlignmentMode = .center
        node.addChild(title)
        
        // Production info
        let prod = buildingType.production
        let cons = buildingType.consumption
        var infoLines: [String] = []
        
        if prod.metal > 0 { infoLines.append("+\(String(format: "%.1f", prod.metal)) ⛏/s") }
        if prod.energy > 0 { infoLines.append("+\(String(format: "%.1f", prod.energy)) ⚡/s") }
        if prod.biomass > 0 { infoLines.append("+\(String(format: "%.1f", prod.biomass)) 🌱/s") }
        if prod.research > 0 { infoLines.append("+\(String(format: "%.1f", prod.research)) 🔬/s") }
        
        var costLines: [String] = []
        if cons.energy > 0 { costLines.append("-\(String(format: "%.1f", cons.energy)) ⚡/s") }
        if cons.biomass > 0 { costLines.append("-\(String(format: "%.1f", cons.biomass)) 🌱/s") }
        
        let prodText = "Produces: \(infoLines.joined(separator: "  "))"
        let costText = costLines.isEmpty ? "No upkeep" : "Costs: \(costLines.joined(separator: "  "))"
        let workerText = "Workers: \(tile.assignedWorkers)/\(buildingType.requiredWorkers)  •  \(tile.isActive ? "✅ Active" : "⚠️ Needs worker")"
        
        var lines = [prodText, costText, workerText]
        if hasBonus {
            let pct = Int((adjacencyMultiplier - 1.0) * 100)
            lines.append("🔗 Adjacency: +\(pct)% production")
        }
        for (i, line) in lines.enumerated() {
            let label = SKLabelNode(fontNamed: "Menlo")
            label.text = line
            label.fontSize = 11
            // Adjacency line in green
            if line.contains("Adjacency") {
                label.fontColor = SKColor(red: 0.3, green: 1, blue: 0.5, alpha: 1)
            } else {
                label.fontColor = SKColor(white: 0.8, alpha: 1)
            }
            label.position = CGPoint(x: 0, y: 10 - CGFloat(i) * 18)
            label.horizontalAlignmentMode = .center
            node.addChild(label)
        }
        
        // Animate in
        node.setScale(0.8)
        node.alpha = 0
        node.run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.15),
            SKAction.fadeIn(withDuration: 0.15)
        ]))
    }
    
    func dismiss() {
        node.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.8, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.1)
            ]),
            SKAction.removeFromParent()
        ]))
    }
}
