import SpriteKit

/// Renders the top resource bar and timer
final class HUDRenderer {
    let hudNode: SKNode
    
    private let timerLabel: SKLabelNode
    private let metalLabel: SKLabelNode
    private let energyLabel: SKLabelNode
    private let biomassLabel: SKLabelNode
    private let researchLabel: SKLabelNode
    private let stabilityLabel: SKLabelNode
    private let colonistLabel: SKLabelNode
    private let phaseLabel: SKLabelNode
    
    private let stabilityBar: SKShapeNode
    private let stabilityFill: SKShapeNode
    
    init(sceneSize: CGSize) {
        hudNode = SKNode()
        hudNode.name = "hud"
        hudNode.zPosition = 100
        
        let topY = sceneSize.height / 2 - 30
        let fontSize: CGFloat = 14
        let smallFont: CGFloat = 12
        
        // Timer — centered, prominent
        timerLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        timerLabel.fontSize = 22
        timerLabel.fontColor = .white
        timerLabel.position = CGPoint(x: 0, y: topY)
        timerLabel.horizontalAlignmentMode = .center
        hudNode.addChild(timerLabel)
        
        // Phase indicator
        phaseLabel = SKLabelNode(fontNamed: "Menlo")
        phaseLabel.fontSize = smallFont
        phaseLabel.fontColor = SKColor(red: 0.6, green: 0.6, blue: 0.7, alpha: 1)
        phaseLabel.position = CGPoint(x: 0, y: topY - 20)
        phaseLabel.horizontalAlignmentMode = .center
        hudNode.addChild(phaseLabel)
        
        // Resource row
        let resourceY = topY - 48
        let spacing: CGFloat = sceneSize.width / 6
        let startX = -sceneSize.width / 2 + spacing * 0.7
        
        metalLabel = Self.makeResourceLabel("⛏ 0", x: startX, y: resourceY, fontSize: fontSize)
        energyLabel = Self.makeResourceLabel("⚡ 0", x: startX + spacing, y: resourceY, fontSize: fontSize)
        biomassLabel = Self.makeResourceLabel("🌱 0", x: startX + spacing * 2, y: resourceY, fontSize: fontSize)
        researchLabel = Self.makeResourceLabel("🔬 0", x: startX + spacing * 3, y: resourceY, fontSize: fontSize)
        colonistLabel = Self.makeResourceLabel("👤 0", x: startX + spacing * 4, y: resourceY, fontSize: fontSize)
        
        hudNode.addChild(metalLabel)
        hudNode.addChild(energyLabel)
        hudNode.addChild(biomassLabel)
        hudNode.addChild(researchLabel)
        hudNode.addChild(colonistLabel)
        
        // Stability bar
        let barWidth: CGFloat = sceneSize.width * 0.6
        let barHeight: CGFloat = 8
        let barY = resourceY - 22
        
        stabilityBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 4)
        stabilityBar.position = CGPoint(x: 0, y: barY)
        stabilityBar.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1)
        stabilityBar.strokeColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1)
        hudNode.addChild(stabilityBar)
        
        stabilityFill = SKShapeNode(rectOf: CGSize(width: barWidth - 2, height: barHeight - 2), cornerRadius: 3)
        stabilityFill.position = CGPoint(x: 0, y: barY)
        stabilityFill.fillColor = .green
        stabilityFill.strokeColor = .clear
        hudNode.addChild(stabilityFill)
        
        stabilityLabel = SKLabelNode(fontNamed: "Menlo")
        stabilityLabel.fontSize = smallFont
        stabilityLabel.fontColor = .white
        stabilityLabel.position = CGPoint(x: 0, y: barY - 16)
        stabilityLabel.horizontalAlignmentMode = .center
        hudNode.addChild(stabilityLabel)
    }
    
    func update(state: GameState) {
        // Timer
        timerLabel.text = state.remainingTimeFormatted
        if state.remainingTime < 120 {
            timerLabel.fontColor = .red
        } else if state.remainingTime < 300 {
            timerLabel.fontColor = .orange
        } else {
            timerLabel.fontColor = .white
        }
        
        // Phase
        switch state.phase {
        case .landing: phaseLabel.text = "LANDING"
        case .expansion: phaseLabel.text = "EXPANSION"
        case .escalation: phaseLabel.text = "⚠ ESCALATION"
        case .collapse: phaseLabel.text = "💥 COLLAPSE"
        case .summary: phaseLabel.text = "LOOP COMPLETE"
        }
        
        // Resources with deltas
        metalLabel.text = "⛏ \(Int(state.metal)) \(Self.deltaString(state.metalDelta))"
        energyLabel.text = "⚡ \(Int(state.energy)) \(Self.deltaString(state.energyDelta))"
        biomassLabel.text = "🌱 \(Int(state.biomass)) \(Self.deltaString(state.biomassDelta))"
        researchLabel.text = "🔬 \(Int(state.research)) \(Self.deltaString(state.researchDelta))"
        colonistLabel.text = "👤 \(state.availableColonists)/\(state.totalColonists)"
        
        // Stability bar
        let ratio = CGFloat(state.stability / GameConstants.maxStability)
        let barWidth = stabilityBar.frame.width - 2
        stabilityFill.xScale = max(0.01, ratio)
        
        if state.stability < GameConstants.stabilityCriticalThreshold {
            stabilityFill.fillColor = .red
        } else if state.stability < GameConstants.stabilityWarningThreshold {
            stabilityFill.fillColor = .orange
        } else {
            stabilityFill.fillColor = .green
        }
        
        stabilityLabel.text = "Stability: \(Int(state.stability))%"
    }
    
    // MARK: - Helpers
    
    private static func makeResourceLabel(_ text: String, x: CGFloat, y: CGFloat, fontSize: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Menlo")
        label.text = text
        label.fontSize = fontSize
        label.fontColor = .white
        label.position = CGPoint(x: x, y: y)
        label.horizontalAlignmentMode = .left
        return label
    }
    
    private static func deltaString(_ delta: Double) -> String {
        if abs(delta) < 0.1 { return "" }
        let sign = delta > 0 ? "+" : ""
        return "(\(sign)\(String(format: "%.1f", delta)))"
    }
}
