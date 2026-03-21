import SpriteKit

/// Progressive tutorial that guides new players through their first loops
/// Steps advance when the player completes specific actions
final class TutorialSystem {
    
    enum Step: Int, CaseIterable {
        case welcome = 0          // "Welcome to Chrono Colony"
        case selectBuilding       // "Tap a building in the menu below"
        case placeBuilding        // "Now tap an empty tile to place it"
        case resourcesExplained   // "Watch your resources change ↑"
        case buildFarm            // "Food is draining! Build a Farm 🌱"
        case assignWorkers        // "Tap 👤 Staff, then tap a building"
        case watchTimer           // "Survive until the timer runs out"
        case collapseExplained    // "Loop ended! Earn Knowledge Points"
        case techTreeHint         // "Spend KP to unlock new tech"
        case done                 // Tutorial complete
    }
    
    private(set) var currentStep: Step = .welcome
    private var hintNode: SKNode?
    private var arrowNode: SKNode?
    private let sceneSize: CGSize
    private let safeTopInset: CGFloat
    private let safeBottomInset: CGFloat
    private weak var parentNode: SKNode?
    
    /// Whether the tutorial is active (first 2 loops)
    var isActive: Bool {
        currentStep != .done
    }
    
    init(sceneSize: CGSize, safeTop: CGFloat = 0, safeBottom: CGFloat = 0) {
        self.sceneSize = sceneSize
        self.safeTopInset = max(0, safeTop)
        self.safeBottomInset = max(0, safeBottom)
    }
    
    /// Check if tutorial should run based on meta progression
    static func shouldShowTutorial() -> Bool {
        let meta = MetaState.load()
        return meta.totalLoops < 3
    }
    
    func attach(to node: SKNode) {
        parentNode = node
        currentStep = .welcome
        showStep(.welcome)
    }
    
    // MARK: - Action Callbacks
    
    func onBuildingSelected() {
        if currentStep == .selectBuilding || currentStep == .welcome {
            advance(to: .placeBuilding)
        }
    }
    
    func onBuildingPlaced(type: BuildingType) {
        if currentStep == .placeBuilding {
            advance(to: .resourcesExplained)
            // Auto-advance after 3s
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                if self?.currentStep == .resourcesExplained {
                    self?.advance(to: .buildFarm)
                }
            }
        } else if currentStep == .buildFarm && type == .farm {
            advance(to: .assignWorkers)
        }
    }
    
    func onWorkerAssigned() {
        if currentStep == .assignWorkers {
            advance(to: .watchTimer)
        }
    }
    
    func onCollapseStarted() {
        if currentStep == .watchTimer || currentStep.rawValue < Step.watchTimer.rawValue {
            advance(to: .collapseExplained)
        }
    }
    
    func onSummaryShown() {
        if currentStep == .collapseExplained || currentStep.rawValue < Step.collapseExplained.rawValue {
            advance(to: .techTreeHint)
        }
    }
    
    func onTechTreeOpened() {
        if currentStep == .techTreeHint {
            advance(to: .done)
        }
    }
    
    // MARK: - Step Display
    
    private func advance(to step: Step) {
        currentStep = step
        showStep(step)
    }
    
    private func showStep(_ step: Step) {
        clearHint()
        guard step != .done else { return }
        
        let (text, suggestedPosition, hasArrow, arrowDirection) = config(for: step)
        let compactSummaryHint = (step == .techTreeHint)
        let position = clampedHintPosition(suggestedPosition, compactHint: compactSummaryHint)
        
        // Background pill with hint text
        let padding: CGFloat = compactSummaryHint ? 12 : 16
        let bgHeight: CGFloat = compactSummaryHint ? 26 : 32
        let maxBgWidth = sceneSize.width - 20
        let minBgWidth: CGFloat = compactSummaryHint ? 170 : 190
        let fontName = compactSummaryHint ? "Menlo" : "Menlo-Bold"
        let baseFontSize: CGFloat = compactSummaryHint ? 10 : 12
        let minFontSize: CGFloat = compactSummaryHint ? 8.5 : 10
        let maxTextWidth = maxBgWidth - padding * 2

        let hintFontSize = fittedFontSize(
            for: text,
            fontNamed: fontName,
            baseFontSize: baseFontSize,
            minFontSize: minFontSize,
            maxWidth: maxTextWidth
        )
        let hintText = truncatedText(
            text,
            fontNamed: fontName,
            fontSize: hintFontSize,
            maxWidth: maxTextWidth
        )
        let textWidth = measuredWidth(for: hintText, fontNamed: fontName, fontSize: hintFontSize)
        let bgWidth = max(minBgWidth, min(maxBgWidth, textWidth + padding * 2))

        let bg = SKShapeNode(rectOf: CGSize(width: bgWidth, height: bgHeight), cornerRadius: compactSummaryHint ? 9 : 10)
        bg.fillColor = SKColor(red: 0.08, green: 0.08, blue: 0.18, alpha: 0.95)
        bg.strokeColor = SKColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 0.8)
        bg.lineWidth = 1.5
        bg.position = position
        bg.zPosition = 500
        bg.name = "tutorialHint"
        
        let label = SKLabelNode(fontNamed: fontName)
        label.text = hintText
        label.fontSize = hintFontSize
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 1
        bg.addChild(label)
        
        // Arrow indicator
        if hasArrow {
            let arrow = SKLabelNode(fontNamed: "Menlo-Bold")
            arrow.fontSize = compactSummaryHint ? 16 : 20
            arrow.fontColor = SKColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1)
            arrow.zPosition = 501
            let arrowOffset = compactSummaryHint ? 18.0 : 24.0
            
            let rawArrowPosition: CGPoint
            switch arrowDirection {
            case .down:
                arrow.text = "↓"
                rawArrowPosition = CGPoint(x: position.x, y: position.y - arrowOffset)
            case .up:
                arrow.text = "↑"
                rawArrowPosition = CGPoint(x: position.x, y: position.y + arrowOffset)
            case .left:
                arrow.text = "←"
                rawArrowPosition = CGPoint(x: position.x - bgWidth/2 - 12, y: position.y)
            }
            arrow.position = clampedArrowPosition(rawArrowPosition, compactHint: compactSummaryHint)
            parentNode?.addChild(arrow)
            
            // Pulse animation on arrow
            arrow.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.4, duration: 0.5),
                SKAction.fadeAlpha(to: 1.0, duration: 0.5)
            ])))
            arrowNode = arrow
        }
        
        parentNode?.addChild(bg)
        hintNode = bg
    }
    
    private enum ArrowDir { case down, up, left }
    
    private func config(for step: Step) -> (text: String, position: CGPoint, hasArrow: Bool, arrowDir: ArrowDir) {
        let midX: CGFloat = 0
        let topArea = sceneSize.height / 2 - 110
        let midArea: CGFloat = 0
        let bottomArea = -sceneSize.height / 2 + 150
        
        switch step {
        case .welcome:
            return ("Welcome to Chrono Colony", CGPoint(x: midX, y: midArea + 30), false, .down)
        case .selectBuilding:
            return ("Tap a building in the menu", CGPoint(x: midX, y: bottomArea + 40), true, .down)
        case .placeBuilding:
            return ("Tap an empty tile to build", CGPoint(x: midX, y: midArea), true, .up)
        case .resourcesExplained:
            return ("Resources are changing", CGPoint(x: midX, y: topArea - 20), true, .up)
        case .buildFarm:
            return ("Food is draining: build a Farm", CGPoint(x: midX, y: bottomArea + 40), true, .down)
        case .assignWorkers:
            return ("Tap Staff, then tap a building", CGPoint(x: midX, y: bottomArea + 40), true, .down)
        case .watchTimer:
            return ("Survive until collapse", CGPoint(x: midX, y: topArea - 20), false, .down)
        case .collapseExplained:
            return ("You earned Knowledge Points", CGPoint(x: midX, y: midArea + 40), false, .down)
        case .techTreeHint:
            // Compact summary hint: sits above the CTA with clear separation from rows + button label.
            return ("Tap SPEND KNOWLEDGE", CGPoint(x: midX, y: -94), true, .down)
        case .done:
            return ("", .zero, false, .down)
        }
    }
    
    private func clearHint() {
        hintNode?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
        arrowNode?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
        hintNode = nil
        arrowNode = nil
    }

    private func clampedHintPosition(_ position: CGPoint, compactHint: Bool) -> CGPoint {
        let topPadding: CGFloat = compactHint ? 48 : 56
        let bottomPadding: CGFloat = compactHint ? 84 : 96
        let rawMinY = -sceneSize.height / 2 + safeBottomInset + bottomPadding
        let rawMaxY = sceneSize.height / 2 - safeTopInset - topPadding

        // Extremely short layouts (or large accessibility insets) can invert bounds.
        // Normalize first so clamping always returns a stable in-range value.
        let minY = min(rawMinY, rawMaxY)
        let maxY = max(rawMinY, rawMaxY)

        let clampedY = min(max(position.y, minY), maxY)
        return CGPoint(x: position.x, y: clampedY)
    }

    private func clampedArrowPosition(_ position: CGPoint, compactHint: Bool) -> CGPoint {
        let sidePadding: CGFloat = compactHint ? 22 : 26
        let verticalPadding: CGFloat = compactHint ? 46 : 52

        let minX = -sceneSize.width / 2 + sidePadding
        let maxX = sceneSize.width / 2 - sidePadding

        let rawMinY = -sceneSize.height / 2 + safeBottomInset + verticalPadding
        let rawMaxY = sceneSize.height / 2 - safeTopInset - verticalPadding
        let minY = min(rawMinY, rawMaxY)
        let maxY = max(rawMinY, rawMaxY)

        let clampedX = min(max(position.x, minX), maxX)
        let clampedY = min(max(position.y, minY), maxY)
        return CGPoint(x: clampedX, y: clampedY)
    }

    private func measuredWidth(for text: String, fontNamed: String, fontSize: CGFloat) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let probe = SKLabelNode(fontNamed: fontNamed)
        probe.fontSize = fontSize
        probe.text = text
        return probe.frame.width
    }

    private func fittedFontSize(
        for text: String,
        fontNamed: String,
        baseFontSize: CGFloat,
        minFontSize: CGFloat,
        maxWidth: CGFloat
    ) -> CGFloat {
        guard !text.isEmpty, maxWidth > 0 else { return baseFontSize }

        var candidate = baseFontSize
        let floorSize = min(minFontSize, baseFontSize)
        while candidate > floorSize {
            if measuredWidth(for: text, fontNamed: fontNamed, fontSize: candidate) <= maxWidth {
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
        if measuredWidth(for: text, fontNamed: fontNamed, fontSize: fontSize) <= maxWidth {
            return text
        }

        var trimmed = text
        while !trimmed.isEmpty {
            trimmed.removeLast()
            let candidate = trimmed + "…"
            if measuredWidth(for: candidate, fontNamed: fontNamed, fontSize: fontSize) <= maxWidth {
                return candidate
            }
        }

        return "…"
    }
    
    // MARK: - Auto-advance welcome
    
    func startWelcomeSequence() {
        guard currentStep == .welcome else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard self?.currentStep == .welcome else { return }
            self?.advance(to: .selectBuilding)
        }
    }
}
