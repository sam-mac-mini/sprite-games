import SpriteKit

/// Callback when player picks a choice
protocol EventOverlayDelegate: AnyObject {
    func eventOverlayDidChoose(choiceIndex: Int)
    func eventOverlayDidDismiss()
}

/// Renders the event popup as a modal overlay
final class EventOverlayRenderer {
    
    let overlayNode = SKNode()
    weak var delegate: EventOverlayDelegate?
    
    private var choiceButtons: [SKShapeNode] = []
    private var dismissButton: SKShapeNode?
    private let sceneSize: CGSize
    
    /// Set to true when Emergency Protocols tech is unlocked
    var canDismissEvents: Bool = false
    
    init(sceneSize: CGSize) {
        self.sceneSize = sceneSize
        overlayNode.zPosition = 400
        overlayNode.isHidden = true
    }
    
    // MARK: - Show Event
    
    func show(event: GameEvent) {
        overlayNode.removeAllChildren()
        choiceButtons = []
        overlayNode.isHidden = false
        
        // Dimmer
        let dimmer = SKShapeNode(rectOf: CGSize(width: sceneSize.width * 2, height: sceneSize.height * 2))
        dimmer.fillColor = SKColor.black.withAlphaComponent(0.7)
        dimmer.strokeColor = .clear
        dimmer.zPosition = 0
        dimmer.name = "eventDimmer"
        overlayNode.addChild(dimmer)
        
        // Card dimensions + vertical layout budgeting
        let cardW = sceneSize.width * 0.88
        let buttonW = cardW - 30

        var buttonH: CGFloat = 52
        var buttonSpacing: CGFloat = 8
        var bottomPadding: CGFloat = 20
        var dismissHeight: CGFloat = 30
        var dismissSpacing: CGFloat = 8
        var descLineHeight: CGFloat = 16
        var descFontSize: CGFloat = sceneSize.width < 370 ? 10.5 : 11
        var descMaxLines = 4

        // Tighter vertical budgets on compact devices.
        if sceneSize.height < 760 {
            buttonH = 49
            buttonSpacing = 7
            bottomPadding = 18
            dismissHeight = 29
            dismissSpacing = 7
            descLineHeight = 15
            descFontSize = min(descFontSize, 10.5)
            descMaxLines = 3
        }
        if sceneSize.height < 700 {
            buttonH = 46
            buttonSpacing = 6
            bottomPadding = 16
            dismissHeight = 27
            dismissSpacing = 6
            descLineHeight = 14
            descFontSize = min(descFontSize, 10)
            descMaxLines = 3
        }

        // Description is wrapped first so we can size card height to prevent overlap/clipping.
        let descMaxWidth = cardW - 26
        let descLines = wordWrap(
            event.description,
            fontNamed: "Menlo",
            fontSize: descFontSize,
            maxWidth: descMaxWidth,
            maxLines: descMaxLines
        )

        let choicesAreaHeight = CGFloat(event.choices.count) * buttonH
            + CGFloat(max(0, event.choices.count - 1)) * buttonSpacing
        let dismissExtraHeight = canDismissEvents ? (dismissHeight + dismissSpacing) : 0
        let requiredCardH = CGFloat(72) + CGFloat(max(descLines.count - 1, 0)) * descLineHeight
            + bottomPadding + dismissExtraHeight + choicesAreaHeight
        let minCardH: CGFloat = sceneSize.height < 700 ? 248 : 280
        let maxCardH = max(minCardH, sceneSize.height - 36)
        let cardH = min(max(minCardH, ceil(requiredCardH)), maxCardH)

        // Card background
        let card = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 14)
        card.fillColor = SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 0.97)
        card.strokeColor = borderColor(for: event.severity)
        card.lineWidth = 2

        let preferredCardCenterY: CGFloat = 20
        let minCardCenterY = -sceneSize.height / 2 + 18 + cardH / 2
        let maxCardCenterY = sceneSize.height / 2 - 18 - cardH / 2
        let cardCenterY = min(max(preferredCardCenterY, minCardCenterY), maxCardCenterY)

        card.position = CGPoint(x: 0, y: cardCenterY)
        card.zPosition = 1
        overlayNode.addChild(card)
        
        // Severity indicator bar
        let barWidth = cardW - 20
        let bar = SKShapeNode(rectOf: CGSize(width: barWidth, height: 3), cornerRadius: 1.5)
        bar.fillColor = borderColor(for: event.severity)
        bar.strokeColor = .clear
        bar.position = CGPoint(x: 0, y: cardH / 2 - 10)
        bar.zPosition = 2
        card.addChild(bar)
        
        // Title
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        let titleMaxWidth = cardW - 24
        let titleFontSize = fittedFontSize(
            for: event.title,
            fontNamed: "Menlo-Bold",
            baseFontSize: 15,
            minFontSize: 12,
            maxWidth: titleMaxWidth
        )
        title.fontSize = titleFontSize
        title.text = truncatedText(
            event.title,
            fontNamed: "Menlo-Bold",
            fontSize: titleFontSize,
            maxWidth: titleMaxWidth
        )
        title.fontColor = borderColor(for: event.severity)
        title.position = CGPoint(x: 0, y: cardH / 2 - 35)
        title.zPosition = 2
        card.addChild(title)
        
        // Description — width-based wrap to keep text contained on compact cards
        for (i, line) in descLines.enumerated() {
            let label = SKLabelNode(fontNamed: "Menlo")
            label.text = line
            label.fontSize = descFontSize
            label.fontColor = SKColor(white: 0.75, alpha: 1)
            label.position = CGPoint(x: 0, y: cardH / 2 - 58 - CGFloat(i) * descLineHeight)
            label.zPosition = 2
            card.addChild(label)
        }
        
        // Choice buttons
        let choicesBaseY = -cardH / 2 + bottomPadding + (canDismissEvents ? (dismissHeight + dismissSpacing) : 0)
        let firstChoiceY = choicesBaseY + choicesAreaHeight - buttonH / 2

        for (i, choice) in event.choices.enumerated() {
            let btnY = firstChoiceY - CGFloat(i) * (buttonH + buttonSpacing)
            
            let btn = SKShapeNode(rectOf: CGSize(width: buttonW, height: buttonH), cornerRadius: 10)
            btn.fillColor = i == 0
                ? SKColor(red: 0.12, green: 0.18, blue: 0.3, alpha: 1)
                : SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1)
            btn.strokeColor = i == 0
                ? SKColor(red: 0.2, green: 0.35, blue: 0.6, alpha: 1)
                : SKColor(red: 0.15, green: 0.15, blue: 0.22, alpha: 1)
            btn.lineWidth = 1.5
            btn.position = CGPoint(x: 0, y: btnY)
            btn.zPosition = 2
            btn.name = "eventChoice_\(i)"
            card.addChild(btn)
            choiceButtons.append(btn)
            
            // Choice label
            let choiceLabel = SKLabelNode(fontNamed: "Menlo-Bold")
            let choiceTextMaxWidth = buttonW - 20
            let choiceFontSize = fittedFontSize(
                for: choice.label,
                fontNamed: "Menlo-Bold",
                baseFontSize: buttonH < 50 ? 12 : 13,
                minFontSize: buttonH < 50 ? 8.6 : 9,
                maxWidth: choiceTextMaxWidth
            )
            choiceLabel.fontSize = choiceFontSize
            choiceLabel.text = truncatedText(
                choice.label,
                fontNamed: "Menlo-Bold",
                fontSize: choiceFontSize,
                maxWidth: choiceTextMaxWidth
            )
            choiceLabel.fontColor = .white
            choiceLabel.position = CGPoint(x: 0, y: 8)
            choiceLabel.zPosition = 3
            btn.addChild(choiceLabel)
            
            // Effect description
            let effectLabel = SKLabelNode(fontNamed: "Menlo")
            let effectFontSize = fittedFontSize(
                for: choice.description,
                fontNamed: "Menlo",
                baseFontSize: buttonH < 50 ? 9.5 : 10,
                minFontSize: buttonH < 50 ? 7.6 : 8,
                maxWidth: choiceTextMaxWidth
            )
            effectLabel.fontSize = effectFontSize
            effectLabel.text = truncatedText(
                choice.description,
                fontNamed: "Menlo",
                fontSize: effectFontSize,
                maxWidth: choiceTextMaxWidth
            )
            effectLabel.fontColor = SKColor(white: 0.5, alpha: 1)
            effectLabel.position = CGPoint(x: 0, y: -10)
            effectLabel.zPosition = 3
            btn.addChild(effectLabel)
        }
        
        // Emergency Protocols: dismiss button
        dismissButton = nil
        if canDismissEvents {
            let dismissY = -cardH / 2 + bottomPadding + dismissHeight / 2
            let btn = SKShapeNode(rectOf: CGSize(width: buttonW * 0.6, height: dismissHeight), cornerRadius: 8)
            btn.fillColor = SKColor(red: 0.15, green: 0.08, blue: 0.08, alpha: 1)
            btn.strokeColor = SKColor(red: 0.4, green: 0.15, blue: 0.15, alpha: 1)
            btn.lineWidth = 1
            btn.position = CGPoint(x: 0, y: dismissY)
            btn.zPosition = 2
            btn.name = "eventDismiss"
            card.addChild(btn)
            dismissButton = btn
            
            let lbl = SKLabelNode(fontNamed: "Menlo")
            let dismissText = "DISMISS (-5 STABILITY)"
            let dismissMaxWidth = buttonW * 0.6 - 12
            let dismissFontSize = fittedFontSize(
                for: dismissText,
                fontNamed: "Menlo",
                baseFontSize: 10,
                minFontSize: 8,
                maxWidth: dismissMaxWidth
            )
            lbl.text = truncatedText(
                dismissText,
                fontNamed: "Menlo",
                fontSize: dismissFontSize,
                maxWidth: dismissMaxWidth
            )
            lbl.fontSize = dismissFontSize
            lbl.fontColor = SKColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1)
            lbl.verticalAlignmentMode = .center
            btn.addChild(lbl)
        }
        
        // Animate in
        card.setScale(0.85)
        card.alpha = 0
        card.run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.25),
            SKAction.fadeIn(withDuration: 0.2)
        ]))
    }
    
    // MARK: - Tap Handling
    
    /// Returns true if tap was consumed by the overlay
    func handleTap(at point: CGPoint) -> Bool {
        guard !overlayNode.isHidden else { return false }
        
        // Choice buttons use frame-based hit testing so compact-mode size changes remain accurate.
        for (i, btn) in choiceButtons.enumerated() {
            if let rect = overlayRect(for: btn, padding: 6), rect.contains(point) {
                // Visual feedback
                btn.run(SKAction.sequence([
                    SKAction.scale(to: 0.95, duration: 0.05),
                    SKAction.scale(to: 1.0, duration: 0.05)
                ]))
                delegate?.eventOverlayDidChoose(choiceIndex: i)
                return true
            }
        }
        
        // Check dismiss button
        if let dismissBtn = dismissButton,
           let rect = overlayRect(for: dismissBtn, padding: 6),
           rect.contains(point) {
            delegate?.eventOverlayDidDismiss()
            return true
        }
        
        // Consume tap even if no button hit (block input to game behind)
        return true
    }
    
    // MARK: - Dismiss
    
    func dismiss() {
        overlayNode.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.run { [weak self] in
                self?.overlayNode.removeAllChildren()
                self?.overlayNode.isHidden = true
                self?.overlayNode.alpha = 1
                self?.choiceButtons = []
            }
        ]))
    }
    
    // MARK: - Helpers

    private func overlayRect(for node: SKNode, padding: CGFloat = 0) -> CGRect? {
        guard let parent = node.parent else { return nil }

        let frame = node.calculateAccumulatedFrame()
        let minPoint = parent.convert(CGPoint(x: frame.minX, y: frame.minY), to: overlayNode)
        let maxPoint = parent.convert(CGPoint(x: frame.maxX, y: frame.maxY), to: overlayNode)

        let rect = CGRect(
            x: min(minPoint.x, maxPoint.x),
            y: min(minPoint.y, maxPoint.y),
            width: abs(maxPoint.x - minPoint.x),
            height: abs(maxPoint.y - minPoint.y)
        )

        return rect.insetBy(dx: -padding, dy: -padding)
    }
    
    private func borderColor(for severity: EventSeverity) -> SKColor {
        switch severity {
        case .minor: return SKColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1)
        case .moderate: return SKColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1)
        case .severe: return SKColor(red: 0.9, green: 0.25, blue: 0.2, alpha: 1)
        }
    }

    private func fittedFontSize(
        for text: String,
        fontNamed: String,
        baseFontSize: CGFloat,
        minFontSize: CGFloat,
        maxWidth: CGFloat
    ) -> CGFloat {
        guard !text.isEmpty, maxWidth > 0 else { return baseFontSize }

        let probe = SKLabelNode(fontNamed: fontNamed)
        var candidate = baseFontSize
        let floorSize = min(minFontSize, baseFontSize)

        while candidate > floorSize {
            probe.fontSize = candidate
            probe.text = text
            if probe.frame.width <= maxWidth {
                return candidate
            }
            candidate -= 0.4
        }

        return floorSize
    }

    private func truncatedText(
        _ text: String,
        fontNamed: String,
        fontSize: CGFloat,
        maxWidth: CGFloat
    ) -> String {
        guard !text.isEmpty, maxWidth > 0 else { return text }

        let probe = SKLabelNode(fontNamed: fontNamed)
        probe.fontSize = fontSize
        probe.text = text
        if probe.frame.width <= maxWidth {
            return text
        }

        var trimmed = text
        while !trimmed.isEmpty {
            trimmed.removeLast()
            let candidate = trimmed + "…"
            probe.text = candidate
            if probe.frame.width <= maxWidth {
                return candidate
            }
        }

        return "…"
    }
    
    private func wordWrap(
        _ text: String,
        fontNamed: String,
        fontSize: CGFloat,
        maxWidth: CGFloat,
        maxLines: Int
    ) -> [String] {
        guard !text.isEmpty, maxWidth > 0, maxLines > 0 else { return [] }

        let probe = SKLabelNode(fontNamed: fontNamed)
        probe.fontSize = fontSize

        let words = text.split(separator: " ").map(String.init)
        var lines: [String] = []
        var current = ""

        for (index, word) in words.enumerated() {
            let candidate = current.isEmpty ? word : "\(current) \(word)"
            probe.text = candidate

            if probe.frame.width <= maxWidth {
                current = candidate
                continue
            }

            if !current.isEmpty {
                lines.append(current)
                if lines.count == maxLines {
                    var overflowWords = [word]
                    if index + 1 < words.count {
                        overflowWords.append(contentsOf: words[(index + 1)...])
                    }
                    let overflowText = overflowWords.joined(separator: " ")
                    lines[maxLines - 1] = truncatedText(
                        lines[maxLines - 1] + " " + overflowText,
                        fontNamed: fontNamed,
                        fontSize: fontSize,
                        maxWidth: maxWidth
                    )
                    return lines
                }
                current = word
            } else {
                // Single long token; hard-truncate to fit width.
                lines.append(truncatedText(word, fontNamed: fontNamed, fontSize: fontSize, maxWidth: maxWidth))
                if lines.count == maxLines { return lines }
                current = ""
            }
        }

        if !current.isEmpty {
            if lines.count < maxLines {
                lines.append(current)
            } else {
                lines[maxLines - 1] = truncatedText(
                    lines[maxLines - 1] + " " + current,
                    fontNamed: fontNamed,
                    fontSize: fontSize,
                    maxWidth: maxWidth
                )
            }
        }

        return lines
    }
}
