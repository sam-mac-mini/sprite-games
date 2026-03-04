import Foundation
import SpriteKit

/// Shows info about a selected building
final class InfoPanelRenderer {
    let node: SKNode

    init(
        buildingType: BuildingType,
        tile: Tile,
        adjacencyMultiplier: Double = 1.0,
        sceneSize: CGSize,
        maxWorkers: Int = 2,
        secondWorkerEfficiency: Double = 0.6,
        thirdWorkerEfficiency: Double = 0.4
    ) {
        node = SKNode()
        node.zPosition = 150
        node.name = "infoPanel"

        let hasBonus = adjacencyMultiplier > 1.01
        let isCompact = sceneSize.width < 390
        let panelWidth = min(sceneSize.width - 24, 440)
        let panelHeight: CGFloat = hasBonus ? (isCompact ? 146 : 154) : (isCompact ? 130 : 138)

        // Background
        let bg = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 12)
        bg.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 0.95)
        bg.strokeColor = SKColor(red: 0.3, green: 0.35, blue: 0.5, alpha: 1)
        bg.lineWidth = 1.5
        bg.position = CGPoint(x: 0, y: 0)
        node.addChild(bg)

        // Title
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        let titleBase = isCompact ? buildingType.menuTitle : buildingType.rawValue.uppercased()
        title.text = Self.clampLine(titleBase, maxChars: isCompact ? 12 : 20)
        title.fontSize = isCompact ? 13 : 15
        title.fontColor = buildingType.color
        title.position = CGPoint(x: 0, y: panelHeight / 2 - (isCompact ? 24 : 26))
        title.horizontalAlignmentMode = .center
        node.addChild(title)

        // Production/consumption summaries
        let prod = buildingType.production
        let cons = buildingType.consumption

        var prodTokens: [String] = []
        if prod.metal > 0 { prodTokens.append("MTL +\(Self.rateString(prod.metal))/s") }
        if prod.energy > 0 { prodTokens.append("PWR +\(Self.rateString(prod.energy))/s") }
        if prod.biomass > 0 { prodTokens.append("BIO +\(Self.rateString(prod.biomass))/s") }
        if prod.research > 0 { prodTokens.append("SCI +\(Self.rateString(prod.research))/s") }

        var costTokens: [String] = []
        if cons.energy > 0 { costTokens.append("PWR -\(Self.rateString(cons.energy))/s") }
        if cons.biomass > 0 { costTokens.append("BIO -\(Self.rateString(cons.biomass))/s") }

        let productionLineRaw = prodTokens.isEmpty ? "PROD: —" : "PROD: \(prodTokens.joined(separator: " · "))"
        let upkeepLineRaw = costTokens.isEmpty ? "UPKEEP: none" : "UPKEEP: \(costTokens.joined(separator: " · "))"
        let maxLineCharacters = isCompact ? 50 : 62
        let productionLine = Self.clampLine(productionLineRaw, maxChars: maxLineCharacters)
        let upkeepLine = Self.clampLine(upkeepLineRaw, maxChars: maxLineCharacters)

        let outputMult = Self.outputMultiplier(
            workers: tile.assignedWorkers,
            secondWorkerEfficiency: secondWorkerEfficiency,
            thirdWorkerEfficiency: thirdWorkerEfficiency
        )
        let outputPercent = Int((outputMult * 100).rounded())

        let statusText: String
        if tile.isDisabled {
            statusText = "DISABLED"
        } else if tile.assignedWorkers == 0 {
            statusText = "UNSTAFFED"
        } else if tile.isActive {
            statusText = "ACTIVE"
        } else {
            statusText = "IDLE"
        }

        let compactStatusText: String
        switch statusText {
        case "DISABLED":
            compactStatusText = "OFF"
        case "UNSTAFFED":
            compactStatusText = "EMPTY"
        case "ACTIVE":
            compactStatusText = "ON"
        default:
            compactStatusText = "IDLE"
        }

        let workerLine: String
        if isCompact {
            workerLine = "CRW \(tile.assignedWorkers)/\(maxWorkers) • \(outputPercent)% • \(compactStatusText)"
        } else {
            workerLine = "CREW \(tile.assignedWorkers)/\(maxWorkers) • OUT \(outputPercent)% • STATE \(statusText)"
        }

        let workerColor: SKColor
        switch statusText {
        case "DISABLED":
            workerColor = SKColor(red: 1.0, green: 0.65, blue: 0.4, alpha: 1)
        case "UNSTAFFED":
            workerColor = SKColor(red: 0.98, green: 0.82, blue: 0.5, alpha: 1)
        case "IDLE":
            workerColor = SKColor(white: 0.7, alpha: 1)
        default:
            workerColor = SKColor(white: 0.9, alpha: 1)
        }

        var lines: [(text: String, color: SKColor)] = [
            (productionLine, SKColor(red: 0.55, green: 0.95, blue: 0.9, alpha: 1)),
            (upkeepLine, SKColor(red: 1.0, green: 0.78, blue: 0.55, alpha: 1)),
            (workerLine, workerColor)
        ]
        if hasBonus {
            let pct = Int((adjacencyMultiplier - 1.0) * 100)
            lines.append(("BONUS +\(pct)% adjacency", SKColor(red: 0.3, green: 1, blue: 0.5, alpha: 1)))
        }

        let textStartY: CGFloat = isCompact ? 18 : 22
        let contentX = -panelWidth / 2 + 12

        let longestLineCount = lines.map(\.text.count).max() ?? 0
        let baseFontSize: CGFloat = isCompact ? 9.5 : 11
        let fontSizeAdjustment: CGFloat
        switch longestLineCount {
        case 0 ... 42:
            fontSizeAdjustment = 0
        case 43 ... 52:
            fontSizeAdjustment = -0.6
        default:
            fontSizeAdjustment = -1.2
        }
        let lineFontSize = max(8.2, baseFontSize + fontSizeAdjustment)
        let lineSpacing: CGFloat = isCompact ? (lineFontSize >= 9 ? 16 : 15) : (lineFontSize >= 10.5 ? 18 : 17)

        for (i, line) in lines.enumerated() {
            let label = SKLabelNode(fontNamed: "Menlo")
            label.text = line.text
            label.fontSize = lineFontSize
            label.fontColor = line.color
            label.position = CGPoint(x: contentX, y: textStartY - CGFloat(i) * lineSpacing)
            label.horizontalAlignmentMode = .left
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

    private static func outputMultiplier(
        workers: Int,
        secondWorkerEfficiency: Double,
        thirdWorkerEfficiency: Double
    ) -> Double {
        guard workers > 0 else { return 0 }

        var mult = 1.0
        if workers >= 2 { mult += secondWorkerEfficiency }
        if workers >= 3 { mult += thirdWorkerEfficiency }
        return mult
    }

    private static func clampLine(_ text: String, maxChars: Int) -> String {
        guard text.count > maxChars, maxChars > 1 else { return text }
        return String(text.prefix(maxChars - 1)) + "…"
    }

    private static func rateString(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.01 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}
