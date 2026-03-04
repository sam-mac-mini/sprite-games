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

    private let isCompactHUD: Bool
    private let useCompactResourceLabels: Bool
    private let stabilityBarCenterX: CGFloat
    private let stabilityBarFillWidth: CGFloat

    private static let warningTextColor = SKColor(red: 1, green: 0.43, blue: 0.43, alpha: 1)
    private static let metalTint = SKColor(red: 0.75, green: 0.86, blue: 1.0, alpha: 1)
    private static let energyTint = SKColor(red: 1.0, green: 0.9, blue: 0.58, alpha: 1)
    private static let biomassTint = SKColor(red: 0.65, green: 0.95, blue: 0.72, alpha: 1)
    private static let researchTint = SKColor(red: 0.86, green: 0.78, blue: 1.0, alpha: 1)

    init(sceneSize: CGSize, safeTop: CGFloat = 60) {
        hudNode = SKNode()
        hudNode.name = "hud"
        hudNode.zPosition = 100

        isCompactHUD = sceneSize.width < 375
        // Use shortened resource text on most phone widths to avoid crowding.
        useCompactResourceLabels = sceneSize.width <= 400

        let topY = sceneSize.height / 2 - safeTop
        let fontSize: CGFloat = isCompactHUD ? 11 : 13

        // HUD background
        let panelHeight: CGFloat = isCompactHUD ? 76 : 96
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
        timerTitle.fontSize = isCompactHUD ? 8 : 9
        timerTitle.fontColor = SKColor(white: 0.62, alpha: 1)
        timerTitle.position = CGPoint(x: -panelWidth / 4, y: topY + (isCompactHUD ? 4 : 6))
        timerTitle.horizontalAlignmentMode = .center
        hudNode.addChild(timerTitle)

        timerLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        timerLabel.fontSize = isCompactHUD ? 18 : 22
        timerLabel.fontColor = .white
        timerLabel.position = CGPoint(x: -panelWidth / 4, y: topY - 15)
        timerLabel.horizontalAlignmentMode = .center
        hudNode.addChild(timerLabel)

        // Phase block (right-aligned to avoid clashing with POP label)
        phaseLabel = SKLabelNode(fontNamed: "Menlo")
        phaseLabel.fontSize = isCompactHUD ? 8 : 11
        phaseLabel.fontColor = SKColor(white: 0.65, alpha: 1)
        phaseLabel.position = CGPoint(x: panelWidth / 2 - (isCompactHUD ? 14 : 12), y: topY - (isCompactHUD ? 2 : 2))
        phaseLabel.horizontalAlignmentMode = .right
        hudNode.addChild(phaseLabel)

        // Colonists
        let colonistFontSize = isCompactHUD ? max(9.0, fontSize - 2.0) : fontSize
        colonistLabel = Self.makeLabel(x: panelWidth / 2 - (isCompactHUD ? 14 : 12), y: topY - (isCompactHUD ? 21 : 20), fontSize: colonistFontSize)
        colonistLabel.horizontalAlignmentMode = .right
        hudNode.addChild(colonistLabel)

        // Resources — single row
        let resY = topY - (isCompactHUD ? 32 : 36)
        let colW = panelWidth / 4
        let defaultLeftX = -panelWidth / 2 + 8
        let compactStartX = -panelWidth / 2 + colW / 2
        let resourceFontSize = useCompactResourceLabels ? max(9.0, fontSize - 2.0) : fontSize

        let resourceX: [CGFloat]
        if useCompactResourceLabels {
            resourceX = [
                compactStartX,
                compactStartX + colW,
                compactStartX + colW * 2,
                compactStartX + colW * 3
            ]
        } else {
            resourceX = [
                defaultLeftX,
                defaultLeftX + colW,
                defaultLeftX + colW * 2,
                defaultLeftX + colW * 3
            ]
        }

        metalLabel = Self.makeLabel(x: resourceX[0], y: resY, fontSize: resourceFontSize)
        energyLabel = Self.makeLabel(x: resourceX[1], y: resY, fontSize: resourceFontSize)
        biomassLabel = Self.makeLabel(x: resourceX[2], y: resY, fontSize: resourceFontSize)
        researchLabel = Self.makeLabel(x: resourceX[3], y: resY, fontSize: resourceFontSize)

        if useCompactResourceLabels {
            metalLabel.horizontalAlignmentMode = .center
            energyLabel.horizontalAlignmentMode = .center
            biomassLabel.horizontalAlignmentMode = .center
            researchLabel.horizontalAlignmentMode = .center
        }

        metalLabel.fontColor = Self.metalTint
        energyLabel.fontColor = Self.energyTint
        biomassLabel.fontColor = Self.biomassTint
        researchLabel.fontColor = Self.researchTint

        hudNode.addChild(metalLabel)
        hudNode.addChild(energyLabel)
        hudNode.addChild(biomassLabel)
        hudNode.addChild(researchLabel)

        // Stability bar
        let barWidth = panelWidth * 0.6
        let barHeight: CGFloat = 5
        let barY = resY - (isCompactHUD ? 14 : 16)

        stabilityBarCenterX = -panelWidth / 6
        stabilityBarFillWidth = barWidth - 1

        let stabilityBg = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 2)
        stabilityBg.position = CGPoint(x: stabilityBarCenterX, y: barY)
        stabilityBg.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1)
        stabilityBg.strokeColor = .clear
        hudNode.addChild(stabilityBg)

        stabilityFill = SKShapeNode(rectOf: CGSize(width: stabilityBarFillWidth, height: barHeight - 1), cornerRadius: 2)
        stabilityFill.position = CGPoint(x: stabilityBarCenterX, y: barY)
        stabilityFill.fillColor = .green
        stabilityFill.strokeColor = .clear
        hudNode.addChild(stabilityFill)

        stabilityLabel = SKLabelNode(fontNamed: "Menlo")
        stabilityLabel.fontSize = isCompactHUD ? 9 : 10
        stabilityLabel.fontColor = SKColor(white: 0.65, alpha: 1)
        stabilityLabel.position = CGPoint(x: stabilityBarCenterX + barWidth / 2 + (isCompactHUD ? 2 : 6), y: barY - 2)
        stabilityLabel.horizontalAlignmentMode = .left
        hudNode.addChild(stabilityLabel)
    }

    func update(state: GameState) {
        timerLabel.text = state.remainingTimeFormatted
        if state.remainingTime < 60 {
            timerLabel.fontColor = .red
            if timerLabel.action(forKey: "timerUrgencyPulse") == nil {
                let pulse = SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(to: 1.08, duration: 0.32),
                        SKAction.fadeAlpha(to: 0.78, duration: 0.32)
                    ]),
                    SKAction.group([
                        SKAction.scale(to: 1.0, duration: 0.32),
                        SKAction.fadeAlpha(to: 1.0, duration: 0.32)
                    ])
                ])
                timerLabel.run(SKAction.repeatForever(pulse), withKey: "timerUrgencyPulse")
            }
        } else if state.remainingTime < 120 {
            timerLabel.fontColor = SKColor(red: 1, green: 0.4, blue: 0.2, alpha: 1)
            timerLabel.removeAction(forKey: "timerUrgencyPulse")
            timerLabel.setScale(1.0)
            timerLabel.alpha = 1.0
        } else {
            timerLabel.fontColor = .white
            timerLabel.removeAction(forKey: "timerUrgencyPulse")
            timerLabel.setScale(1.0)
            timerLabel.alpha = 1.0
        }

        switch state.phase {
        case .landing:
            phaseLabel.text = useCompactResourceLabels ? "LAND" : "PHASE: LANDING"
            phaseLabel.fontColor = SKColor(white: 0.65, alpha: 1)
        case .expansion:
            phaseLabel.text = useCompactResourceLabels ? "EXPN" : "PHASE: EXPANSION"
            phaseLabel.fontColor = SKColor(red: 0.72, green: 0.82, blue: 1.0, alpha: 1)
        case .escalation:
            phaseLabel.text = useCompactResourceLabels ? "ESCL" : "PHASE: ESCALATION"
            phaseLabel.fontColor = .orange
        case .collapse:
            phaseLabel.text = useCompactResourceLabels ? "COLL" : "PHASE: COLLAPSE"
            phaseLabel.fontColor = .red
        case .summary:
            phaseLabel.text = ""
        }

        let metalValue = useCompactResourceLabels ? Self.compactNumber(state.metal) : "\(Int(state.metal))"
        let energyValue = useCompactResourceLabels ? Self.compactNumber(state.energy) : "\(Int(state.energy))"
        let biomassValue = useCompactResourceLabels ? Self.compactNumber(state.biomass) : "\(Int(state.biomass))"
        let researchValue = useCompactResourceLabels ? Self.compactNumber(state.research) : "\(Int(state.research))"

        if useCompactResourceLabels {
            metalLabel.text = "MTL \(metalValue)"
            energyLabel.text = "PWR \(energyValue)"
            biomassLabel.text = "BIO \(biomassValue)"
            researchLabel.text = "SCI \(researchValue)"
        } else {
            metalLabel.text = "METAL \(metalValue)"
            energyLabel.text = "ENERGY \(energyValue)"
            biomassLabel.text = "FOOD \(biomassValue)"
            researchLabel.text = "SCI \(researchValue)"
        }

        colonistLabel.text = "POP \(state.availableColonists)/\(state.totalColonists)"

        metalLabel.fontColor = state.metal < 30 ? Self.warningTextColor : Self.metalTint
        energyLabel.fontColor = state.energy < 10 ? Self.warningTextColor : Self.energyTint
        biomassLabel.fontColor = state.biomass < 10 ? Self.warningTextColor : Self.biomassTint
        researchLabel.fontColor = state.research < 5 ? Self.warningTextColor : Self.researchTint
        colonistLabel.fontColor = (state.totalColonists > 0 && state.availableColonists == 0)
            ? Self.warningTextColor
            : .white

        let ratio = max(0, min(1, CGFloat(state.stability / GameConstants.maxStability)))
        let visibleRatio = max(0.01, ratio)
        stabilityFill.xScale = visibleRatio

        // Keep left edge anchored so depletion reads naturally left→right.
        let xShift = (stabilityBarFillWidth * (1 - visibleRatio)) / 2
        stabilityFill.position.x = stabilityBarCenterX - xShift

        if state.stability < GameConstants.stabilityCriticalThreshold {
            stabilityFill.fillColor = .red
            stabilityLabel.fontColor = Self.warningTextColor
            if stabilityFill.action(forKey: "stabilityCriticalPulse") == nil {
                let pulse = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.55, duration: 0.35),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.35)
                ])
                stabilityFill.run(SKAction.repeatForever(pulse), withKey: "stabilityCriticalPulse")
            }
        } else if state.stability < GameConstants.stabilityWarningThreshold {
            stabilityFill.fillColor = .orange
            stabilityLabel.fontColor = SKColor(red: 1.0, green: 0.76, blue: 0.48, alpha: 1)
            stabilityFill.removeAction(forKey: "stabilityCriticalPulse")
            stabilityFill.alpha = 1.0
        } else {
            stabilityFill.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1)
            stabilityLabel.fontColor = SKColor(white: 0.65, alpha: 1)
            stabilityFill.removeAction(forKey: "stabilityCriticalPulse")
            stabilityFill.alpha = 1.0
        }

        let stabilityPrefix = useCompactResourceLabels ? "STB" : "STAB"
        stabilityLabel.text = "\(stabilityPrefix) \(Int(state.stability))%"
    }

    private static func compactNumber(_ value: Double) -> String {
        let sign = value < 0 ? "-" : ""
        let absValue = abs(value)

        if absValue >= 1_000_000 {
            let scaled = absValue / 1_000_000
            return sign + compactSuffix(scaled, suffix: "M")
        }

        if absValue >= 1_000 {
            let scaled = absValue / 1_000
            return sign + compactSuffix(scaled, suffix: "K")
        }

        return "\(Int(value.rounded()))"
    }

    private static func compactSuffix(_ scaled: Double, suffix: String) -> String {
        let raw = String(format: scaled >= 10 ? "%.0f" : "%.1f", scaled)
        let trimmed = raw.hasSuffix(".0") ? String(raw.dropLast(2)) : raw
        return "\(trimmed)\(suffix)"
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
