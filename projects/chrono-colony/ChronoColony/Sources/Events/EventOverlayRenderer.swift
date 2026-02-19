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
        
        // Card dimensions
        let cardW = sceneSize.width * 0.88
        let cardH: CGFloat = 280
        
        // Card background
        let card = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 14)
        card.fillColor = SKColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 0.97)
        card.strokeColor = borderColor(for: event.severity)
        card.lineWidth = 2
        card.position = CGPoint(x: 0, y: 20)
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
        title.text = event.title
        title.fontSize = 15
        title.fontColor = borderColor(for: event.severity)
        title.position = CGPoint(x: 0, y: cardH / 2 - 35)
        title.zPosition = 2
        card.addChild(title)
        
        // Description — word-wrap manually
        let descLines = wordWrap(event.description, maxChars: Int(cardW / 7))
        for (i, line) in descLines.enumerated() {
            let label = SKLabelNode(fontNamed: "Menlo")
            label.text = line
            label.fontSize = 11
            label.fontColor = SKColor(white: 0.75, alpha: 1)
            label.position = CGPoint(x: 0, y: cardH / 2 - 58 - CGFloat(i) * 16)
            label.zPosition = 2
            card.addChild(label)
        }
        
        // Choice buttons
        let buttonW = cardW - 30
        let buttonH: CGFloat = 52
        let buttonSpacing: CGFloat = 8
        let choicesStartY: CGFloat = -cardH / 2 + buttonH * 2 + buttonSpacing + 20
        
        for (i, choice) in event.choices.enumerated() {
            let btnY = choicesStartY - CGFloat(i) * (buttonH + buttonSpacing)
            
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
            choiceLabel.text = choice.label
            choiceLabel.fontSize = 13
            choiceLabel.fontColor = .white
            choiceLabel.position = CGPoint(x: 0, y: 8)
            choiceLabel.zPosition = 3
            btn.addChild(choiceLabel)
            
            // Effect description
            let effectLabel = SKLabelNode(fontNamed: "Menlo")
            effectLabel.text = choice.description
            effectLabel.fontSize = 10
            effectLabel.fontColor = SKColor(white: 0.5, alpha: 1)
            effectLabel.position = CGPoint(x: 0, y: -10)
            effectLabel.zPosition = 3
            btn.addChild(effectLabel)
        }
        
        // Emergency Protocols: dismiss button
        dismissButton = nil
        if canDismissEvents {
            let dismissY = choicesStartY - CGFloat(event.choices.count) * (buttonH + buttonSpacing) - 8
            let btn = SKShapeNode(rectOf: CGSize(width: buttonW * 0.6, height: 30), cornerRadius: 8)
            btn.fillColor = SKColor(red: 0.15, green: 0.08, blue: 0.08, alpha: 1)
            btn.strokeColor = SKColor(red: 0.4, green: 0.15, blue: 0.15, alpha: 1)
            btn.lineWidth = 1
            btn.position = CGPoint(x: 0, y: dismissY)
            btn.zPosition = 2
            btn.name = "eventDismiss"
            card.addChild(btn)
            dismissButton = btn
            
            let lbl = SKLabelNode(fontNamed: "Menlo")
            lbl.text = "✕ Dismiss (−5 Stability)"
            lbl.fontSize = 10
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
        
        // Convert point to overlay space
        for (i, btn) in choiceButtons.enumerated() {
            // Convert button frame to overlay coordinate space
            let btnInOverlay = btn.parent!.convert(btn.position, to: overlayNode)
            let halfW: CGFloat = (sceneSize.width * 0.88 - 30) / 2
            let halfH: CGFloat = 26
            let rect = CGRect(
                x: btnInOverlay.x - halfW,
                y: btnInOverlay.y - halfH,
                width: halfW * 2,
                height: halfH * 2
            )
            if rect.contains(point) {
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
        if let dismissBtn = dismissButton, let parent = dismissBtn.parent {
            let btnInOverlay = parent.convert(dismissBtn.position, to: overlayNode)
            let halfW: CGFloat = (sceneSize.width * 0.88 - 30) * 0.3
            let halfH: CGFloat = 15
            let rect = CGRect(x: btnInOverlay.x - halfW, y: btnInOverlay.y - halfH, width: halfW * 2, height: halfH * 2)
            if rect.contains(point) {
                delegate?.eventOverlayDidDismiss()
                return true
            }
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
    
    private func borderColor(for severity: EventSeverity) -> SKColor {
        switch severity {
        case .minor: return SKColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1)
        case .moderate: return SKColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1)
        case .severe: return SKColor(red: 0.9, green: 0.25, blue: 0.2, alpha: 1)
        }
    }
    
    private func wordWrap(_ text: String, maxChars: Int) -> [String] {
        let words = text.split(separator: " ")
        var lines: [String] = []
        var current = ""
        
        for word in words {
            let test = current.isEmpty ? String(word) : current + " " + word
            if test.count > maxChars && !current.isEmpty {
                lines.append(current)
                current = String(word)
            } else {
                current = test
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }
}
