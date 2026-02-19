import SpriteKit

/// Generates detailed building sprite textures programmatically
/// Each building is a composed multi-shape visual rather than a flat square
final class BuildingSprites {
    
    private static var cache: [String: SKTexture] = [:]
    
    /// Get or create a texture for a building type
    static func texture(for type: BuildingType, tileSize: CGFloat, isDisabled: Bool = false) -> SKTexture {
        let key = "\(type.rawValue)_\(Int(tileSize))_\(isDisabled)"
        if let cached = cache[key] { return cached }
        
        let size = CGSize(width: tileSize - 2, height: tileSize - 2)
        let tex = SKTexture(imageNamed: "") // fallback
        
        let node = renderBuilding(type: type, size: size, disabled: isDisabled)
        let texture = SKView().texture(from: node, crop: CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2), size: size))
        
        if let texture = texture {
            cache[key] = texture
            return texture
        }
        return tex
    }
    
    /// Create a sprite node directly (avoids texture rendering issues)
    static func spriteNode(for type: BuildingType, tileSize: CGFloat, isDisabled: Bool = false) -> SKNode {
        return renderBuilding(type: type, size: CGSize(width: tileSize - 2, height: tileSize - 2), disabled: isDisabled)
    }
    
    private static func renderBuilding(type: BuildingType, size: CGSize, disabled: Bool) -> SKNode {
        let container = SKNode()
        let alpha: CGFloat = disabled ? 0.3 : 1.0
        let s = min(size.width, size.height)
        
        switch type {
        case .metalExtractor:
            // Base platform
            let base = SKShapeNode(rectOf: CGSize(width: s * 0.8, height: s * 0.3), cornerRadius: 2)
            base.fillColor = SKColor(red: 0.35, green: 0.35, blue: 0.4, alpha: alpha)
            base.strokeColor = SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: alpha)
            base.lineWidth = 1
            base.position = CGPoint(x: 0, y: -s * 0.15)
            container.addChild(base)
            
            // Drill tower
            let tower = SKShapeNode(rectOf: CGSize(width: s * 0.15, height: s * 0.5))
            tower.fillColor = SKColor(red: 0.5, green: 0.5, blue: 0.6, alpha: alpha)
            tower.strokeColor = SKColor(red: 0.6, green: 0.6, blue: 0.7, alpha: alpha)
            tower.lineWidth = 1
            tower.position = CGPoint(x: 0, y: s * 0.1)
            container.addChild(tower)
            
            // Drill head (triangle-ish)
            let head = SKShapeNode(circleOfRadius: s * 0.08)
            head.fillColor = SKColor(red: 0.7, green: 0.6, blue: 0.3, alpha: alpha)
            head.strokeColor = .clear
            head.position = CGPoint(x: 0, y: s * 0.38)
            container.addChild(head)
            
            // Arm
            let arm = SKShapeNode(rectOf: CGSize(width: s * 0.4, height: s * 0.06))
            arm.fillColor = SKColor(red: 0.45, green: 0.45, blue: 0.5, alpha: alpha)
            arm.strokeColor = .clear
            arm.position = CGPoint(x: s * 0.1, y: s * 0.2)
            arm.zRotation = -0.3
            container.addChild(arm)
            
        case .farm:
            // Greenhouse dome
            let dome = SKShapeNode(ellipseOf: CGSize(width: s * 0.8, height: s * 0.5))
            dome.fillColor = SKColor(red: 0.15, green: 0.45, blue: 0.2, alpha: alpha)
            dome.strokeColor = SKColor(red: 0.25, green: 0.6, blue: 0.3, alpha: alpha * 0.8)
            dome.lineWidth = 1.5
            dome.position = CGPoint(x: 0, y: s * 0.05)
            container.addChild(dome)
            
            // Glass panels (horizontal lines)
            for i in 0..<2 {
                let line = SKShapeNode(rectOf: CGSize(width: s * 0.5, height: 1))
                line.fillColor = SKColor(red: 0.4, green: 0.8, blue: 0.5, alpha: alpha * 0.4)
                line.strokeColor = .clear
                line.position = CGPoint(x: 0, y: s * 0.05 + CGFloat(i) * s * 0.12 - s * 0.06)
                container.addChild(line)
            }
            
            // Soil base
            let soil = SKShapeNode(rectOf: CGSize(width: s * 0.85, height: s * 0.2), cornerRadius: 2)
            soil.fillColor = SKColor(red: 0.25, green: 0.18, blue: 0.1, alpha: alpha)
            soil.strokeColor = .clear
            soil.position = CGPoint(x: 0, y: -s * 0.2)
            container.addChild(soil)
            
            // Small plant sprouts
            for x in stride(from: -s * 0.25, through: s * 0.25, by: s * 0.17) {
                let sprout = SKShapeNode(rectOf: CGSize(width: 2, height: s * 0.12))
                sprout.fillColor = SKColor(red: 0.3, green: 0.7, blue: 0.2, alpha: alpha)
                sprout.strokeColor = .clear
                sprout.position = CGPoint(x: x, y: -s * 0.08)
                container.addChild(sprout)
            }
            
        case .solarArray:
            // Panel mount
            let mount = SKShapeNode(rectOf: CGSize(width: s * 0.06, height: s * 0.35))
            mount.fillColor = SKColor(red: 0.4, green: 0.4, blue: 0.45, alpha: alpha)
            mount.strokeColor = .clear
            mount.position = CGPoint(x: 0, y: -s * 0.08)
            container.addChild(mount)
            
            // Main solar panel (angled)
            let panel = SKShapeNode(rectOf: CGSize(width: s * 0.75, height: s * 0.35), cornerRadius: 2)
            panel.fillColor = SKColor(red: 0.15, green: 0.2, blue: 0.5, alpha: alpha)
            panel.strokeColor = SKColor(red: 0.3, green: 0.4, blue: 0.8, alpha: alpha)
            panel.lineWidth = 1
            panel.position = CGPoint(x: 0, y: s * 0.12)
            panel.zRotation = 0.15
            container.addChild(panel)
            
            // Panel grid lines
            for i in 0..<3 {
                let gridLine = SKShapeNode(rectOf: CGSize(width: 0.5, height: s * 0.3))
                gridLine.fillColor = SKColor(red: 0.25, green: 0.35, blue: 0.7, alpha: alpha * 0.6)
                gridLine.strokeColor = .clear
                gridLine.position = CGPoint(x: CGFloat(i - 1) * s * 0.2, y: s * 0.12)
                gridLine.zRotation = 0.15
                container.addChild(gridLine)
            }
            
            // Sun reflection dot
            let sun = SKShapeNode(circleOfRadius: s * 0.05)
            sun.fillColor = SKColor(red: 1, green: 0.95, blue: 0.5, alpha: alpha * 0.8)
            sun.strokeColor = .clear
            sun.glowWidth = 3
            sun.position = CGPoint(x: s * 0.15, y: s * 0.2)
            container.addChild(sun)
            
        case .researchLab:
            // Main building
            let building = SKShapeNode(rectOf: CGSize(width: s * 0.7, height: s * 0.45), cornerRadius: 3)
            building.fillColor = SKColor(red: 0.15, green: 0.2, blue: 0.4, alpha: alpha)
            building.strokeColor = SKColor(red: 0.25, green: 0.35, blue: 0.6, alpha: alpha)
            building.lineWidth = 1
            building.position = CGPoint(x: 0, y: -s * 0.05)
            container.addChild(building)
            
            // Antenna/dish
            let dish = SKShapeNode(ellipseOf: CGSize(width: s * 0.25, height: s * 0.15))
            dish.fillColor = SKColor(red: 0.3, green: 0.4, blue: 0.7, alpha: alpha)
            dish.strokeColor = SKColor(red: 0.4, green: 0.55, blue: 0.9, alpha: alpha)
            dish.lineWidth = 1
            dish.position = CGPoint(x: s * 0.15, y: s * 0.25)
            container.addChild(dish)
            
            // Antenna mast
            let mast = SKShapeNode(rectOf: CGSize(width: 1.5, height: s * 0.2))
            mast.fillColor = SKColor(red: 0.4, green: 0.5, blue: 0.8, alpha: alpha)
            mast.strokeColor = .clear
            mast.position = CGPoint(x: s * 0.15, y: s * 0.15)
            container.addChild(mast)
            
            // Glowing window
            let window = SKShapeNode(rectOf: CGSize(width: s * 0.2, height: s * 0.12), cornerRadius: 1)
            window.fillColor = SKColor(red: 0.4, green: 0.7, blue: 1, alpha: alpha * 0.7)
            window.strokeColor = .clear
            window.glowWidth = 2
            window.position = CGPoint(x: -s * 0.1, y: -s * 0.02)
            container.addChild(window)
            
            // Data dot (blinking indicator)
            let dot = SKShapeNode(circleOfRadius: s * 0.03)
            dot.fillColor = SKColor(red: 0.3, green: 1, blue: 0.5, alpha: alpha)
            dot.strokeColor = .clear
            dot.glowWidth = 2
            dot.position = CGPoint(x: -s * 0.25, y: s * 0.12)
            container.addChild(dot)
        }
        
        return container
    }
    
    // MARK: - Terrain Deposits
    
    static func depositNode(for type: ResourceDepositType, tileSize: CGFloat) -> SKNode {
        let container = SKNode()
        let s = tileSize - 2
        
        switch type {
        case .metalVein:
            // Crystalline metal formations
            for i in 0..<3 {
                let crystal = SKShapeNode(rectOf: CGSize(width: s * 0.12, height: s * 0.2 + CGFloat(i) * s * 0.08), cornerRadius: 1)
                crystal.fillColor = SKColor(red: 0.5, green: 0.45, blue: 0.6, alpha: 0.9)
                crystal.strokeColor = SKColor(red: 0.65, green: 0.6, blue: 0.75, alpha: 1)
                crystal.lineWidth = 1
                crystal.position = CGPoint(x: CGFloat(i - 1) * s * 0.18, y: CGFloat(i) * s * 0.04 - s * 0.05)
                crystal.zRotation = CGFloat(i - 1) * 0.2
                container.addChild(crystal)
            }
            // Sparkle
            let sparkle = SKShapeNode(circleOfRadius: s * 0.04)
            sparkle.fillColor = SKColor(white: 1, alpha: 0.8)
            sparkle.strokeColor = .clear
            sparkle.glowWidth = 3
            sparkle.position = CGPoint(x: s * 0.1, y: s * 0.15)
            container.addChild(sparkle)
            
        case .biomassZone:
            // Lush vegetation patches
            for i in 0..<4 {
                let bush = SKShapeNode(ellipseOf: CGSize(width: s * 0.2 + CGFloat.random(in: 0...s * 0.1), height: s * 0.15))
                bush.fillColor = SKColor(red: 0.1 + CGFloat(i) * 0.05, green: 0.4 + CGFloat(i) * 0.07, blue: 0.15, alpha: 0.85)
                bush.strokeColor = .clear
                let angle = CGFloat(i) * .pi / 2
                bush.position = CGPoint(x: cos(angle) * s * 0.15, y: sin(angle) * s * 0.12)
                container.addChild(bush)
            }
            // Center bright spot
            let center = SKShapeNode(circleOfRadius: s * 0.06)
            center.fillColor = SKColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 0.6)
            center.strokeColor = .clear
            center.glowWidth = 4
            container.addChild(center)
            
        case .anomaly:
            // Glowing rift/portal
            let outer = SKShapeNode(circleOfRadius: s * 0.22)
            outer.fillColor = SKColor(red: 0.35, green: 0.1, blue: 0.5, alpha: 0.4)
            outer.strokeColor = SKColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 0.8)
            outer.lineWidth = 1.5
            outer.glowWidth = 5
            container.addChild(outer)
            
            let inner = SKShapeNode(circleOfRadius: s * 0.1)
            inner.fillColor = SKColor(red: 0.7, green: 0.4, blue: 1, alpha: 0.7)
            inner.strokeColor = .clear
            inner.glowWidth = 3
            container.addChild(inner)
            
            // Particles (static dots around rift)
            for i in 0..<5 {
                let particle = SKShapeNode(circleOfRadius: s * 0.02)
                particle.fillColor = SKColor(red: 0.8, green: 0.6, blue: 1, alpha: 0.7)
                particle.strokeColor = .clear
                let angle = CGFloat(i) * .pi * 2 / 5
                particle.position = CGPoint(x: cos(angle) * s * 0.28, y: sin(angle) * s * 0.28)
                container.addChild(particle)
            }
        }
        
        return container
    }
}
