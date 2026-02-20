import SpriteKit

/// Renders the top resource bar and timer
final class HUDRenderer {
    let hudNode: SKNode
    
    private let timerLabel: SKLabelNode
    private let metalLabel: SKLabelNode
    private let energyLabel: SKLabelNode
    private let biomassLabel: SKLabelNode
    private let researchLabel: SKLabelNode
    private let colonistLabel: SKLabelNode
    private let phaseLabel: SKLabelNode
    private let stabilityFill: SKShapeNode
    private let stabilityLabel: SKLabelNode
    
    init(sceneSize: CGSize, safeTop: CGFloat = 60) {
        hudNode = SKNode()
        hudNode.name = "hud"
        hudNode.zPosition = 100
        
        let isCompact = sceneSize.width < 375
        let topY = sceneSize.height / 2 - safeTop
        let fontSize: CGFloat = isCompact ? 11 : 13
        
        // HUD background
        let panelHeight: CGFloat = isCompact ? 76 : 96
        let panelWidth = sceneSize.width - 12
        let hudBg = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 10)
        hudBg.fillColor = SKColor(red: 0.05, green: 0.05, blue: 0.09, alpha: 0.95)
        hudBg.strokeColor = SKColor(red: 0.12, green: 0.15, blue: 0.22, alpha: 0.6)
        hudBg.lineWidth = 1
        hudBg.position = CGPoint(x: 0, y: topY - panelHeight / 2)
        hudNode.addChild(hudBg)
        
        // Timer block
        let timerTitle = SKLabelNode(fontNamed: "Menlo")
        timerTitle.text = "TIME"
        timerTitle.fontSize = isCompact ? 8 : 9
        timerTitle.fontColor = SKColor(white: 0.55, alpha: 1)
        timerTitle.position = CGPoint(x: -panelWidth / 4, y: topY - 2)
        timerTitle.horizontalAlignmentMode = .center
        hudNode.addChild(timerTitle)
        
        timerLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        timerLabel.fontSize = isCompact ? 18 : 22
        timerLabel.fontColor = .white
        timerLabel.position = CGPoint(x: -panelWidth / 4, y: topY - 16)
        timerLabel.horizontalAlignmentMode = .center
        hudNode.addChild(timerLabel)
        
        // Phase block
        phaseLabel = SKLabelNode(fontNamed: "Menlo")
        phaseLabel.fontSize = isCompact ? 9 : 11
        phaseLabel.fontColor = SKColor(white: 0.65, alpha: 1)
        phaseLabel.position = CGPoint(x: panelWidth / 4, y: topY - 8)
        phaseLabel.horizontalAlignmentMode = .center
        hudNode.addChild(phaseLabel)
        
        // Colonists
        colonistLabel = Self.makeLabel(x: panelWidth / 4 - 20, y: topY - 24, fontSize: fontSize)
        colonistLabel.horizontalAlignmentMode = .center
        hudNode.addChild(colonistLabel)
        
        // Resources — single row
        let resY = topY - (isCompact ? 32 : 36)
        let colW = panelWidth / 4
        let leftX = -panelWidth / 2 + 8
        
        metalLabel = Self.makeLabel(x: leftX, y: resY, fontSize: fontSize)
        energyLabel = Self.makeLabel(x: leftX + colW, y: resY, fontSize: fontSize)
        biomassLabel = Self.makeLabel(x: leftX + colW * 2, y: resY, fontSize: fontSize)
        researchLabel = Self.makeLabel(x: leftX + colW * 3, y: resY, fontSize: fontSize)
        
        hudNode.addChild(metalLabel)
        hudNode.addChild(energyLabel)
        hudNode.addChild(biomassLabel)
        hudNode.addChild(researchLabel)
        
        // Stability bar
        let barWidth = panelWidth * 0.6
        let barHeight: CGFloat = 5
        let barY = resY - (isCompact ? 14 : 16)
        
        let stabilityBg = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 2)
        stabilityBg.position = CGPoint(x: -panelWidth / 6, y: barY)
        stabilityBg.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1)
        stabilityBg.strokeColor = .clear
        hudNode.addChild(stabilityBg)
        
        stabilityFill = SKShapeNode(rectOf: CGSize(width: barWidth - 1, height: barHeight - 1), cornerRadius: 2)
        stabilityFill.position = CGPoint(x: -panelWidth / 6, y: barY)
        stabilityFill.fillColor = .green
        stabilityFill.strokeColor = .clear
        hudNode.addChild(stabilityFill)
        
        stabilityLabel = SKLabelNode(fontNamed: "Menlo")
        stabilityLabel.fontSize = isCompact ? 9 : 10
        stabilityLabel.fontColor = SKColor(white: 0.65, alpha: 1)
        stabilityLabel.position = CGPoint(x: -panelWidth / 6 + barWidth / 2 + 6, y: barY - 2)
        stabilityLabel.horizontalAlignmentMode = .left
        hudNode.addChild(stabilityLabel)
    }
    
    func update(state: GameState) {
        timerLabel.text = state.remainingTimeFormatted
        if state.remainingTime < 60 {
            timerLabel.fontColor = .red
        } else if state.remainingTime < 120 {
            timerLabel.fontColor = SKColor(red: 1, green: 0.4, blue: 0.2, alpha: 1)
        } else {
            timerLabel.fontColor = .white
        }
        
        switch state.phase {
        case .landing: phaseLabel.text = "PHASE: LANDING"; phaseLabel.fontColor = SKColor(white: 0.65, alpha: 1)
        case .expansion: phaseLabel.text = "PHASE: EXPANSION"; phaseLabel.fontColor = SKColor(white: 0.65, alpha: 1)
        case .escalation: phaseLabel.text = "PHASE: ESCALATION"; phaseLabel.fontColor = .orange
        case .collapse: phaseLabel.text = "PHASE: COLLAPSE"; phaseLabel.fontColor = .red
        case .summary: phaseLabel.text = ""
        }
        
        metalLabel.text = "METAL \(Int(state.metal))"
        energyLabel.text = "ENERGY \(Int(state.energy))"
        biomassLabel.text = "FOOD \(Int(state.biomass))"
        researchLabel.text = "SCI \(Int(state.research))"
        colonistLabel.text = "POP \(state.availableColonists)/\(state.totalColonists)"
        
        metalLabel.fontColor = state.metal < 30 ? .red : .white
        energyLabel.fontColor = state.energy < 10 ? .red : .white
        biomassLabel.fontColor = state.biomass < 10 ? .red : .white
        
        let ratio = CGFloat(state.stability / GameConstants.maxStability)
        stabilityFill.xScale = max(0.01, ratio)
        
        if state.stability < GameConstants.stabilityCriticalThreshold {
            stabilityFill.fillColor = .red
        } else if state.stability < GameConstants.stabilityWarningThreshold {
            stabilityFill.fillColor = .orange
        } else {
            stabilityFill.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1)
        }
        
        stabilityLabel.text = "STAB \(Int(state.stability))%"
    }
    
    private static func makeLabel(x: CGFloat, y: CGFloat, fontSize: CGFloat) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: "Menlo")
        l.fontSize = fontSize
        l.fontColor = .white
        l.position = CGPoint(x: x, y: y)
        l.horizontalAlignmentMode = .left
        return l
    }
}
