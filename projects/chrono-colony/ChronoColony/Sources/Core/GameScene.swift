import SpriteKit
import GameplayKit

/// Main game scene — owns the simulation loop
class GameScene: SKScene, BuildMenuDelegate, EventOverlayDelegate {
    
    // MARK: - Core
    private var gameState: GameState!
    private var gridModel: GridModel!
    private var resourceSystem: ResourceSystem!
    private var techEffects: TechEffects!
    
    // MARK: - Renderers
    private var gridRenderer: GridRenderer!
    private var hudRenderer: HUDRenderer!
    private var buildMenu: BuildMenuRenderer!
    private var infoPanel: InfoPanelRenderer?
    private var eventOverlay: EventOverlayRenderer!
    
    // MARK: - Events
    private var eventSystem: EventSystem!
    
    // MARK: - Escalation
    private var escalationSystem: EscalationSystem!
    private var escalationTintNode: SKShapeNode?
    private var lastWarningFlash: TimeInterval = 0
    
    // MARK: - Camera
    private var cameraNode: SKCameraNode!
    private var lastPanPoint: CGPoint?
    private var isPanning = false
    private let minZoom: CGFloat = 0.6
    private let maxZoom: CGFloat = 2.0
    
    // MARK: - Timing
    private var lastTickTime: TimeInterval = 0
    private var tickAccumulator: TimeInterval = 0
    
    // MARK: - Tutorial
    private var tutorial: TutorialSystem!
    
    // MARK: - Interaction State
    private var selectedTilePos: (col: Int, row: Int)?
    
    // MARK: - Layers
    private let worldNode = SKNode()
    
    // MARK: - Layout constants (set by GameViewController)
    var safeTop: CGFloat = 59
    var safeBottom: CGFloat = 34
    
    // MARK: - Scene Setup
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 1)
        
        // safeTop/safeBottom set by GameViewController from actual device safe areas
        
        // Camera
        cameraNode = SKCameraNode()
        self.camera = cameraNode
        addChild(cameraNode)
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // World layer
        addChild(worldNode)
        
        // Load meta progression first (needed for build menu filtering)
        let meta = MetaState.load()
        techEffects = TechEffects(meta: meta)
        
        // Initialize systems
        gameState = GameState()
        gridModel = GridModel()
        resourceSystem = ResourceSystem()
        gridModel.generateMap(rng: &gameState.rng)
        
        // Layout zones — scale to screen
        let hudHeight: CGFloat = size.height > 600 ? 100 : 80
        let buildMenuHeight: CGFloat = size.height > 600 ? 80 : 70
        let gridPaddingV: CGFloat = 4
        let gridAreaTop = size.height - safeTop - hudHeight - gridPaddingV
        let gridAreaBottom = safeBottom + buildMenuHeight + gridPaddingV
        let gridAreaHeight = gridAreaTop - gridAreaBottom
        // Use nearly full width so tiles are as large as possible
        let gridAreaWidth = size.width - 8
        
        // Tile size — use WIDTH as the constraint (grid is square, screen is tall)
        let tileSize = floor(gridAreaWidth / CGFloat(GameConstants.gridColumns))
        let gridHeight = tileSize * CGFloat(GameConstants.gridRows)
        
        // Grid
        gridRenderer = GridRenderer(
            columns: GameConstants.gridColumns,
            rows: GameConstants.gridRows,
            tileSize: tileSize
        )
        worldNode.addChild(gridRenderer.gridNode)
        
        // Anchor grid directly below HUD — no gap
        let gridTopY = gridAreaTop
        let gridCenterY = gridTopY - gridHeight / 2
        gridRenderer.gridNode.position = CGPoint(x: size.width / 2, y: gridCenterY)
        
        // Use remaining space below grid for status/event area
        let gridBottomY = gridCenterY - gridHeight / 2
        let extraSpace = gridBottomY - gridAreaBottom
        if extraSpace > 40 {
            addStatusArea(y: gridBottomY - extraSpace / 2, width: gridAreaWidth, height: extraSpace - 8)
        }
        
        // HUD (attached to camera)
        hudRenderer = HUDRenderer(sceneSize: size, safeTop: safeTop)
        cameraNode.addChild(hudRenderer.hudNode)
        
        // Build menu (attached to camera)
        // Filter available buildings based on tech unlocks
        let unlockedBuildings = BuildingType.allCases.filter { type in
            guard let techID = type.requiredTechID else { return true }
            return techEffects.meta.isUnlocked(techID)
        }
        buildMenu = BuildMenuRenderer(sceneSize: size, unlockedBuildings: unlockedBuildings)
        buildMenu.delegate = self
        cameraNode.addChild(buildMenu.menuNode)
        
        // Escalation system
        escalationSystem = EscalationSystem()
        
        // Red tint overlay for escalation
        let tint = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        tint.fillColor = SKColor.red
        tint.strokeColor = .clear
        tint.alpha = 0
        tint.zPosition = 150
        tint.name = "escalationTint"
        cameraNode.addChild(tint)
        escalationTintNode = tint
        
        // Event system
        eventSystem = EventSystem()
        eventSystem.setup(rng: &gameState.rng)
        eventOverlay = EventOverlayRenderer(sceneSize: size)
        eventOverlay.delegate = self
        cameraNode.addChild(eventOverlay.overlayNode)
        
        // Apply tech effects to starting state
        applyTechEffectsToState()
        
        // Start
        gameState.phase = .expansion
        gridRenderer.update(from: gridModel, state: gameState)
        hudRenderer.update(state: gameState)
        buildMenu.updateAffordability(state: gameState)
        
        // Tutorial system
        tutorial = TutorialSystem(sceneSize: size)
        tutorial.attach(to: cameraNode)
        tutorial.startWelcomeSequence()
        
        setupTemporalButtons()
        
        // Pinch gesture
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinch)
    }
    
    // MARK: - Status Area (uses extra vertical space below grid)
    
    private func addStatusArea(y: CGFloat, width: CGFloat, height: CGFloat = 50) {
        let panelH = min(height, 120)
        let panel = SKShapeNode(rectOf: CGSize(width: width - 4, height: panelH), cornerRadius: 10)
        panel.fillColor = SKColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.9)
        panel.strokeColor = SKColor(red: 0.12, green: 0.15, blue: 0.22, alpha: 0.5)
        panel.lineWidth = 1
        panel.position = CGPoint(x: size.width / 2, y: y)
        panel.zPosition = 5
        panel.name = "statusArea"
        addChild(panel)
        
        // Production summary
        let prodTitle = SKLabelNode(fontNamed: "Menlo-Bold")
        prodTitle.text = "PRODUCTION"
        prodTitle.fontSize = 10
        prodTitle.fontColor = SKColor(white: 0.4, alpha: 1)
        prodTitle.position = CGPoint(x: 0, y: panelH / 2 - 16)
        prodTitle.verticalAlignmentMode = .center
        panel.addChild(prodTitle)
        
        // Resource flow indicators
        let resources = ["⛏ +0/s", "⚡ +0/s", "🌱 +0/s", "🔬 +0/s"]
        let colW = width / CGFloat(resources.count + 1)
        let startX = -width / 2 + colW * 0.8
        
        for (i, res) in resources.enumerated() {
            let label = SKLabelNode(fontNamed: "Menlo")
            label.text = res
            label.fontSize = 11
            label.fontColor = .white
            label.position = CGPoint(x: startX + CGFloat(i) * colW, y: panelH / 2 - 34)
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .center
            label.name = "prodLabel_\(i)"
            panel.addChild(label)
        }
        
        // Event/status line
        let statusLine = SKLabelNode(fontNamed: "Menlo")
        statusLine.text = "⏱ Build quickly — collapse is coming"
        statusLine.fontSize = 10
        statusLine.fontColor = SKColor(white: 0.45, alpha: 1)
        statusLine.position = CGPoint(x: 0, y: -panelH / 2 + 14)
        statusLine.verticalAlignmentMode = .center
        statusLine.name = "statusLine"
        panel.addChild(statusLine)
    }
    
    /// Update status area with current production rates
    private func updateStatusArea() {
        guard let panel = childNode(withName: "statusArea") else { return }
        
        let deltas = [gameState.metalDelta, gameState.energyDelta, gameState.biomassDelta, gameState.researchDelta]
        let symbols = ["⛏", "⚡", "🌱", "🔬"]
        
        for (i, delta) in deltas.enumerated() {
            if let label = panel.childNode(withName: "prodLabel_\(i)") as? SKLabelNode {
                let sign = delta >= 0 ? "+" : ""
                label.text = "\(symbols[i]) \(sign)\(String(format: "%.0f", delta))/s"
                label.fontColor = delta < 0 ? SKColor(red: 1, green: 0.5, blue: 0.5, alpha: 1) : .white
            }
        }
        
        // Update status line based on phase + event scanner
        if let statusLine = panel.childNode(withName: "statusLine") as? SKLabelNode {
            if let preview = eventSystem.upcomingEventPreview {
                statusLine.text = preview
                statusLine.fontColor = SKColor(red: 1, green: 0.8, blue: 0.3, alpha: 1)
            } else {
                statusLine.fontColor = SKColor(white: 0.45, alpha: 1)
                switch gameState.phase {
                case .expansion:
                    let buildings = gridModel.allBuildings().count
                    statusLine.text = "🏗 \(buildings) buildings • \(gameState.availableColonists) workers free"
                case .escalation:
                    statusLine.text = "⚠ Stellar instability — systems failing!"
                    statusLine.fontColor = .orange
                default:
                    statusLine.text = ""
                }
            }
        }
    }
    
    // MARK: - Tutorial
    
    // showTutorialHint replaced by TutorialSystem
    
    // MARK: - Temporal Abilities
    
    private func setupTemporalButtons() {
        if techEffects.timeDilationAvailable {
            let btn = SKShapeNode(rectOf: CGSize(width: 90, height: 30), cornerRadius: 8)
            btn.fillColor = SKColor(red: 0.3, green: 0.15, blue: 0.4, alpha: 0.9)
            btn.strokeColor = SKColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1)
            btn.lineWidth = 1.5
            btn.position = CGPoint(x: -size.width / 2 + 60, y: size.height / 2 - safeTop - 120)
            btn.zPosition = 110
            btn.name = "timeDilationBtn"
            cameraNode.addChild(btn)
            
            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.text = "⏳ SLOW"
            label.fontSize = 11
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.name = "timeDilationLabel"
            btn.addChild(label)
        }
        
        if techEffects.timeRewindAvailable {
            let btn = SKShapeNode(rectOf: CGSize(width: 90, height: 30), cornerRadius: 8)
            btn.fillColor = SKColor(red: 0.15, green: 0.2, blue: 0.4, alpha: 0.9)
            btn.strokeColor = SKColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1)
            btn.lineWidth = 1.5
            btn.position = CGPoint(x: -size.width / 2 + 60, y: size.height / 2 - safeTop - 155)
            btn.zPosition = 110
            btn.name = "timeRewindBtn"
            cameraNode.addChild(btn)
            
            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.text = "⏪ REWIND"
            label.fontSize = 11
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.name = "timeRewindLabel"
            btn.addChild(label)
        }
    }
    
    private func activateTimeDilation() {
        guard techEffects.timeDilationAvailable,
              !gameState.timeDilationUsed,
              gameState.phase == .expansion || gameState.phase == .escalation else { return }
        
        gameState.timeDilationUsed = true
        gameState.timeScale = 0.5
        gameState.timeDilationRemaining = 30.0
        run(SoundManager.shared.event)
        
        if let btn = cameraNode.childNode(withName: "timeDilationBtn") as? SKShapeNode {
            btn.fillColor = SKColor(red: 0.15, green: 0.08, blue: 0.2, alpha: 0.5)
            if let lbl = btn.childNode(withName: "timeDilationLabel") as? SKLabelNode {
                lbl.text = "⏳ ACTIVE"
                lbl.fontColor = SKColor(red: 0.7, green: 0.4, blue: 1, alpha: 1)
            }
        }
        
        let flash = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        flash.fillColor = SKColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 0.2)
        flash.strokeColor = .clear
        flash.zPosition = 200
        cameraNode.addChild(flash)
        flash.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent()]))
        
        let msg = SKLabelNode(fontNamed: "Menlo-Bold")
        msg.text = "TIME DILATED — 50% SPEED"
        msg.fontSize = 14
        msg.fontColor = SKColor(red: 0.7, green: 0.4, blue: 1, alpha: 1)
        msg.position = CGPoint(x: 0, y: size.height * 0.2)
        msg.zPosition = 201
        cameraNode.addChild(msg)
        msg.run(SKAction.sequence([
            SKAction.wait(forDuration: 2),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Time Rewind Snapshots
    
    private struct GameSnapshot {
        let timestamp: TimeInterval
        let metal: Double
        let energy: Double
        let biomass: Double
        let research: Double
        let stability: Double
        let totalColonists: Int
        let assignedColonists: Int
        let phase: GamePhase
    }
    
    private var snapshots: [GameSnapshot] = []
    private var lastSnapshotTime: TimeInterval = 0
    private let snapshotInterval: TimeInterval = 5.0
    
    private func takeSnapshotIfNeeded() {
        guard techEffects.timeRewindAvailable else { return }
        if gameState.elapsedTime - lastSnapshotTime >= snapshotInterval {
            lastSnapshotTime = gameState.elapsedTime
            let snap = GameSnapshot(
                timestamp: gameState.elapsedTime,
                metal: gameState.metal,
                energy: gameState.energy,
                biomass: gameState.biomass,
                research: gameState.research,
                stability: gameState.stability,
                totalColonists: gameState.totalColonists,
                assignedColonists: gameState.assignedColonists,
                phase: gameState.phase
            )
            snapshots.append(snap)
            // Keep last 60 seconds of snapshots (12 snapshots at 5s interval)
            if snapshots.count > 12 { snapshots.removeFirst() }
        }
    }
    
    private func activateTimeRewind() {
        guard techEffects.timeRewindAvailable,
              !gameState.timeRewindUsed,
              gameState.phase == .expansion || gameState.phase == .escalation,
              !snapshots.isEmpty else { return }
        
        gameState.timeRewindUsed = true
        run(SoundManager.shared.event)
        
        // Find snapshot closest to 30s ago
        let targetTime = gameState.elapsedTime - 30
        let snap = snapshots.min(by: { abs($0.timestamp - targetTime) < abs($1.timestamp - targetTime) })!
        
        // Restore state
        gameState.elapsedTime = snap.timestamp
        gameState.metal = snap.metal
        gameState.energy = snap.energy
        gameState.biomass = snap.biomass
        gameState.research = snap.research
        gameState.stability = snap.stability
        gameState.totalColonists = snap.totalColonists
        gameState.phase = snap.phase
        
        // Clear snapshots after rewind point
        snapshots.removeAll { $0.timestamp > snap.timestamp }
        
        // Visual: blue rewind flash
        let flash = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        flash.fillColor = SKColor(red: 0.2, green: 0.3, blue: 0.8, alpha: 0.3)
        flash.strokeColor = .clear
        flash.zPosition = 200
        cameraNode.addChild(flash)
        flash.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.8), SKAction.removeFromParent()]))
        
        let msg = SKLabelNode(fontNamed: "Menlo-Bold")
        msg.text = "⏪ TIME REWOUND — \(Int(gameState.elapsedTime / 60)):\(String(format: "%02d", Int(gameState.elapsedTime) % 60))"
        msg.fontSize = 14
        msg.fontColor = SKColor(red: 0.4, green: 0.6, blue: 1, alpha: 1)
        msg.position = CGPoint(x: 0, y: size.height * 0.2)
        msg.zPosition = 201
        cameraNode.addChild(msg)
        msg.run(SKAction.sequence([
            SKAction.wait(forDuration: 2),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        
        // Dim the button
        if let btn = cameraNode.childNode(withName: "timeRewindBtn") as? SKShapeNode {
            btn.fillColor = SKColor(red: 0.08, green: 0.1, blue: 0.2, alpha: 0.5)
            if let lbl = btn.childNode(withName: "timeRewindLabel") as? SKLabelNode {
                lbl.text = "⏪ USED"
                lbl.fontColor = SKColor(white: 0.4, alpha: 1)
            }
        }
        
        gridRenderer.update(from: gridModel, state: gameState)
        hudRenderer.update(state: gameState)
    }
    
    private func updateTemporalButtons() {
        if let btn = cameraNode.childNode(withName: "timeDilationBtn") as? SKShapeNode,
           let lbl = btn.childNode(withName: "timeDilationLabel") as? SKLabelNode {
            if gameState.timeDilationRemaining > 0 {
                lbl.text = "⏳ \(Int(gameState.timeDilationRemaining))s"
            } else if gameState.timeDilationUsed {
                lbl.text = "⏳ USED"
                lbl.fontColor = SKColor(white: 0.4, alpha: 1)
            }
        }
    }
    
    // MARK: - Camera
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let camera = self.camera else { return }
        if gesture.state == .changed {
            let newScale = camera.xScale / gesture.scale
            camera.setScale(min(maxZoom, max(minZoom, newScale)))
            gesture.scale = 1.0
        }
    }
    
    // MARK: - Game Loop
    
    override func update(_ currentTime: TimeInterval) {
        guard gameState.phase != .collapse && gameState.phase != .summary else { return }
        
        if lastTickTime == 0 { lastTickTime = currentTime }
        let rawDt = min(currentTime - lastTickTime, 0.1)
        lastTickTime = currentTime
        
        // Time Dilation: apply time scale
        let dt = rawDt * gameState.timeScale
        
        // Update time dilation countdown
        if gameState.timeDilationRemaining > 0 {
            gameState.timeDilationRemaining -= rawDt // Uses real time, not scaled
            if gameState.timeDilationRemaining <= 0 {
                gameState.timeDilationRemaining = 0
                gameState.timeScale = 1.0
            }
        }
        
        gameState.elapsedTime += dt
        
        let effectiveLoopDuration = techEffects.loopDuration
        let effectiveEscalationStart = techEffects.escalationStart
        
        if gameState.elapsedTime >= effectiveLoopDuration {
            triggerCollapse()
            return
        } else if gameState.elapsedTime >= effectiveEscalationStart && gameState.phase == .expansion {
            gameState.phase = .escalation
            showEscalationWarning()
        }
        
        if gameState.stability <= 0 {
            triggerCollapse()
            return
        }
        
        // Event system — check for new events (pauses resource ticks while showing)
        if !eventSystem.isShowingEvent {
            tickAccumulator += dt
            if tickAccumulator >= GameConstants.simulationTickRate {
                tickAccumulator -= GameConstants.simulationTickRate
                resourceSystem.tick(grid: gridModel, state: gameState, techEffects: techEffects)
                // Escalation effects on each sim tick
                escalationSystem.tick(grid: gridModel, state: gameState, rng: &gameState.rng)
                // Paradox Shield: enforce minimum stability
                resourceSystem.enforceParadoxShield(state: gameState, techEffects: techEffects)
            }
        }
        
        // Take snapshots for Time Rewind
        takeSnapshotIfNeeded()
        
        // Update temporal ability buttons
        updateTemporalButtons()
        
        // Update Medical Bay status for event filtering
        eventSystem.hasMedicalBay = gridModel.allBuildings().contains { $0.tile.buildingType == .medicalBay && $0.tile.isActive }
        eventSystem.hasEventScanner = techEffects.meta.isUnlocked("RES-02")
        eventOverlay.canDismissEvents = techEffects.canDismissEvents
        
        if let event = eventSystem.update(dt: dt, state: gameState, rng: &gameState.rng) {
            run(SoundManager.shared.event)
            eventOverlay.show(event: event)
        }
        
        // Escalation visual effects
        updateEscalationVisuals(dt: dt)
        
        gridRenderer.update(from: gridModel, state: gameState)
        hudRenderer.update(state: gameState)
        buildMenu.updateAffordability(state: gameState)
        updateStatusArea()
    }
    
    private func showEscalationWarning() {
        run(SoundManager.shared.escalation)
        let warning = SKLabelNode(fontNamed: "Menlo-Bold")
        warning.text = "⚠ STELLAR INSTABILITY ⚠"
        warning.fontSize = 15
        warning.fontColor = .orange
        warning.position = CGPoint(x: 0, y: 0)
        warning.zPosition = 200
        warning.setScale(0.5)
        cameraNode.addChild(warning)
        
        warning.run(SKAction.sequence([
            SKAction.scale(to: 1.0, duration: 0.4),
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Touch Input
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // Summary screen — only check restart button
        if gameState.phase == .summary {
            return
        }
        
        let uiLocation = touch.location(in: cameraNode)
        
        // Temporal ability buttons
        if let dilBtn = cameraNode.childNode(withName: "timeDilationBtn"), dilBtn.contains(uiLocation) {
            activateTimeDilation()
            return
        }
        if let rewBtn = cameraNode.childNode(withName: "timeRewindBtn"), rewBtn.contains(uiLocation) {
            activateTimeRewind()
            return
        }
        
        // Event overlay takes priority
        if eventOverlay.handleTap(at: uiLocation) {
            return
        }
        
        // Build menu
        if buildMenu.handleTap(at: uiLocation) {
            return
        }
        
        // Dismiss info panel
        if let panel = infoPanel {
            panel.dismiss()
            infoPanel = nil
        }
        
        lastPanPoint = touch.location(in: self)
        isPanning = false
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState.phase != .summary else { return }
        guard let touch = touches.first, let lastPoint = lastPanPoint else { return }
        let currentPoint = touch.location(in: self)
        let dx = currentPoint.x - lastPoint.x
        let dy = currentPoint.y - lastPoint.y
        
        if !isPanning && (abs(dx) > 5 || abs(dy) > 5) {
            isPanning = true
        }
        
        if isPanning, let camera = self.camera {
            camera.position.x -= dx
            camera.position.y -= dy
        }
        
        lastPanPoint = currentPoint
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // Summary — check buttons
        if gameState.phase == .summary {
            let loc = touch.location(in: cameraNode)
            if let techBtn = cameraNode.childNode(withName: "techTreeButton"), techBtn.contains(loc) {
                openTechTree()
                return
            }
            if let restart = cameraNode.childNode(withName: "restartButton"), restart.contains(loc) {
                restartLoop()
                return
            }
            return
        }
        
        if isPanning {
            isPanning = false
            lastPanPoint = nil
            return
        }
        lastPanPoint = nil
        
        let worldLocation = touch.location(in: worldNode)
        let gridLocal = gridRenderer.gridNode.convert(worldLocation, from: worldNode)
        
        if let pos = gridRenderer.gridPosition(from: gridLocal) {
            handleGridTap(col: pos.col, row: pos.row)
        }
    }
    
    private func handleGridTap(col: Int, row: Int) {
        // Tutorial hint is managed by TutorialSystem
        
        if let buildingType = buildMenu.selectedBuildingType {
            if gridModel.placeBuilding(buildingType, at: col, row: row, state: gameState) {
                run(SoundManager.shared.build)
                gridRenderer.highlightTile(col: col, row: row, color: .green)
                if gameState.availableColonists > 0 {
                    gridModel.assignWorker(at: col, row: row, state: gameState)
                }
                // Echo Memory: first building is free
                if techEffects.firstBuildingFree && !gameState.firstBuildingPlacedThisLoop {
                    gameState.firstBuildingPlacedThisLoop = true
                    gameState.metal += buildingType.metalCost // Refund
                    showFloatingText("FREE (Echo) ⛏", at: col, row: row, color: SKColor(red: 0.7, green: 0.4, blue: 1, alpha: 1))
                } else {
                    showFloatingText("-\(Int(buildingType.metalCost)) ⛏", at: col, row: row, color: .orange)
                }
                gridRenderer.animatePlacement(col: col, row: row)
                tutorial.onBuildingPlaced(type: buildingType)
            } else {
                gridRenderer.highlightTile(col: col, row: row, color: .red)
                if let tile = gridModel.tile(at: col, row: row), tile.content != .empty {
                    showFloatingText("Occupied", at: col, row: row, color: .red)
                } else {
                    showFloatingText("Can't afford", at: col, row: row, color: .red)
                }
            }
        } else if buildMenu.isDemolishMode {
            if let tile = gridModel.tile(at: col, row: row), tile.buildingType != nil {
                let refund = tile.buildingType!.demolishRefund
                gridModel.demolishBuilding(at: col, row: row, state: gameState)
                run(SoundManager.shared.demolish)
                gridRenderer.highlightTile(col: col, row: row, color: .orange)
                showFloatingText("+\(Int(refund)) ⛏", at: col, row: row, color: .green)
            }
        } else if buildMenu.isAssignWorkerMode {
            if let tile = gridModel.tile(at: col, row: row), let bType = tile.buildingType {
                if tile.assignedWorkers >= bType.maxWorkers {
                    // At max — remove a worker instead
                    gridModel.removeWorker(at: col, row: row, state: gameState)
                    showFloatingText("-1 👤", at: col, row: row, color: .orange)
                } else if gameState.availableColonists > 0 {
                    let wasWorkers = tile.assignedWorkers
                    gridModel.assignWorker(at: col, row: row, state: gameState)
                    run(SoundManager.shared.assign)
                    tutorial.onWorkerAssigned()
                    if wasWorkers == 0 {
                        showFloatingText("+1 👤 Active!", at: col, row: row, color: .green)
                    } else {
                        showFloatingText("+1 👤 (60% eff)", at: col, row: row, color: SKColor(red: 0.5, green: 0.9, blue: 0.5, alpha: 1))
                    }
                } else {
                    showFloatingText("No workers", at: col, row: row, color: .red)
                }
            } else if let tile = gridModel.tile(at: col, row: row), tile.buildingType == nil, tile.assignedWorkers == 0 {
                // Tapping empty tile in worker mode — no action
            }
        } else if buildMenu.isToggleMode {
            if let tile = gridModel.tile(at: col, row: row), tile.buildingType != nil {
                let nowDisabled = gridModel.toggleBuilding(at: col, row: row)
                run(SoundManager.shared.tap)
                if nowDisabled {
                    showFloatingText("⏸ Disabled", at: col, row: row, color: .orange)
                } else {
                    showFloatingText("▶ Enabled", at: col, row: row, color: .green)
                }
            }
        } else {
            // No mode — show building info
            if let tile = gridModel.tile(at: col, row: row), let bt = tile.buildingType {
                showBuildingInfo(type: bt, tile: tile, col: col, row: row)
            }
            selectedTilePos = (col, row)
            gridRenderer.selectTile(col: col, row: row)
        }
        
        gridRenderer.update(from: gridModel, state: gameState)
    }
    
    // MARK: - Floating Text
    
    private func showFloatingText(_ text: String, at col: Int, row: Int, color: SKColor) {
        guard let worldPos = gridRenderer.worldPosition(col: col, row: row) else { return }
        
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.fontSize = 13
        label.fontColor = color
        label.position = worldPos
        label.zPosition = 50
        worldNode.addChild(label)
        
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 35, duration: 0.7),
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.3),
                    SKAction.fadeOut(withDuration: 0.4)
                ])
            ]),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Building Info
    
    private func showBuildingInfo(type: BuildingType, tile: Tile, col: Int, row: Int) {
        infoPanel?.dismiss()
        let mult = gridModel.adjacencyMultiplier(col: col, row: row)
        let panel = InfoPanelRenderer(buildingType: type, tile: tile, adjacencyMultiplier: mult, sceneSize: size)
        cameraNode.addChild(panel.node)
        infoPanel = panel
    }
    
    // MARK: - Tech Effects
    
    private func applyTechEffectsToState() {
        // Apply starting colonists
        gameState.totalColonists = techEffects.startingColonists
        
        // Apply Loop Echo (carry over resources from last loop)
        if let echo = techEffects.loopEchoResources {
            gameState.metal += echo.metal
            gameState.energy += echo.energy
            gameState.biomass += echo.biomass
            gameState.research += echo.research
        }
        
        // Chrono Mastery: extended loop duration
        gameState.effectiveLoopDuration = techEffects.loopDuration
    }
    
    // MARK: - Escalation Visuals
    
    private func updateEscalationVisuals(dt: TimeInterval) {
        let visuals = escalationSystem.visualParams(state: gameState)
        
        // Red tint overlay
        escalationTintNode?.alpha = visuals.screenTintAlpha
        
        // Camera micro-shake during escalation
        if visuals.shakeIntensity > 0.1 {
            let shake = visuals.shakeIntensity
            let ox = CGFloat.random(in: -shake...shake)
            let oy = CGFloat.random(in: -shake...shake)
            cameraNode.position = CGPoint(
                x: size.width / 2 + ox,
                y: size.height / 2 + oy
            )
        }
        
        // Periodic warning flash
        if gameState.phase == .escalation {
            lastWarningFlash += dt
            if lastWarningFlash >= visuals.warningFlashInterval {
                lastWarningFlash = 0
                showEscalationFlash()
            }
        }
    }
    
    private func showEscalationFlash() {
        run(SoundManager.shared.warning)
        let power = escalationSystem.intensity(state: gameState)
        let messages = power > 0.7
            ? ["⚠ CRITICAL INSTABILITY", "SYSTEMS FAILING", "EVACUATE?"]
            : ["⚠ Stellar instability rising", "Structure integrity declining", "Energy reserves draining"]
        
        let msg = messages[Int.random(in: 0..<messages.count)]
        let flash = SKLabelNode(fontNamed: "Menlo-Bold")
        flash.text = msg
        flash.fontSize = power > 0.7 ? 14 : 12
        flash.fontColor = power > 0.7 ? .red : .orange
        flash.position = CGPoint(x: 0, y: size.height * 0.15)
        flash.zPosition = 190
        flash.alpha = 0
        cameraNode.addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.15),
            SKAction.wait(forDuration: 1.5),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Collapse
    
    private func triggerCollapse() {
        gameState.phase = .collapse
        run(SoundManager.shared.collapse)
        tutorial.onCollapseStarted()
        
        // Dismiss any active event overlay
        eventOverlay.dismiss()
        eventSystem.isShowingEvent = false
        
        // Phase 1: Escalating camera shake (2 seconds)
        let shakePhase1 = SKAction.customAction(withDuration: 2.0) { [weak self] _, elapsed in
            guard let self = self else { return }
            let intensity = elapsed / 2.0 * 6.0  // 0 → 6 pixels
            let ox = CGFloat.random(in: -intensity...intensity)
            let oy = CGFloat.random(in: -intensity...intensity)
            self.cameraNode.position = CGPoint(
                x: self.size.width / 2 + ox,
                y: self.size.height / 2 + oy
            )
        }
        
        // Phase 2: Violent shake (1 second)
        let shakePhase2 = SKAction.customAction(withDuration: 1.0) { [weak self] _, _ in
            guard let self = self else { return }
            let ox = CGFloat.random(in: -8...8)
            let oy = CGFloat.random(in: -8...8)
            self.cameraNode.position = CGPoint(
                x: self.size.width / 2 + ox,
                y: self.size.height / 2 + oy
            )
        }
        
        cameraNode.run(SKAction.sequence([
            shakePhase1,
            shakePhase2,
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.cameraNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
            }
        ]))
        
        // Red flash — pulses 3 times, intensifying
        for i in 0..<3 {
            let flash = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
            flash.fillColor = SKColor.red.withAlphaComponent(0.15 + Double(i) * 0.15)
            flash.strokeColor = .clear
            flash.zPosition = 200
            flash.alpha = 0
            flash.name = "collapseEffect"
            cameraNode.addChild(flash)
            
            flash.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.8),
                SKAction.fadeIn(withDuration: 0.15),
                SKAction.fadeOut(withDuration: 0.6),
                i == 2 ? SKAction.removeFromParent() : SKAction.removeFromParent()
            ]))
        }
        
        // "STELLAR COLLAPSE" text — dramatic entrance
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = "STELLAR COLLAPSE"
        label.fontSize = 24
        label.fontColor = .red
        label.position = CGPoint(x: 0, y: 20)
        label.zPosition = 201
        label.setScale(0.1)
        label.alpha = 0
        label.name = "collapseEffect"
        cameraNode.addChild(label)
        
        // Subtitle
        let subtitle = SKLabelNode(fontNamed: "Menlo")
        subtitle.text = "The star has died."
        subtitle.fontSize = 12
        subtitle.fontColor = SKColor(red: 1, green: 0.6, blue: 0.5, alpha: 1)
        subtitle.position = CGPoint(x: 0, y: -5)
        subtitle.zPosition = 201
        subtitle.alpha = 0
        subtitle.name = "collapseEffect"
        cameraNode.addChild(subtitle)
        
        label.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.6),
                SKAction.fadeIn(withDuration: 0.3)
            ])
        ]))
        
        subtitle.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.fadeIn(withDuration: 0.8)
        ]))
        
        // Transition to summary after collapse sequence
        run(SKAction.sequence([
            SKAction.wait(forDuration: 3.5),
            SKAction.run { [weak self] in
                self?.cameraNode.children.filter { $0.name == "collapseEffect" }.forEach {
                    $0.run(SKAction.sequence([
                        SKAction.fadeOut(withDuration: 0.5),
                        SKAction.removeFromParent()
                    ]))
                }
            },
            SKAction.wait(forDuration: 0.6),
            SKAction.run { [weak self] in self?.showSummary() }
        ]))
        
        // Grid collapse — buildings crumble outward from center
        gridRenderer.animateCollapse()
    }
    
    // MARK: - Summary
    
    private func showSummary() {
        gameState.phase = .summary
        tutorial.onSummaryShown()
        
        // *** Hide game UI ***
        hudRenderer.hudNode.isHidden = true
        buildMenu.menuNode.isHidden = true
        
        let buildings = gridModel.allBuildings()
        let buildingCount = buildings.count
        let activeCount = buildings.filter { $0.tile.isActive }.count
        let knowledgeFromResearch = Int(gameState.research * 0.3)
        let knowledgeFromBuildings = buildingCount * 5
        let efficiencyBonus = activeCount * 3  // Reward for keeping buildings staffed
        let survivalBonus = gameState.elapsedTime >= gameState.effectiveLoopDuration ? 50 : 0  // Full loop bonus
        let stabilityBonus = Int(gameState.stability * 0.2)  // Reward for ending with stability
        let timeBonus = Int(gameState.elapsedTime / 60) * 10
        let total = knowledgeFromResearch + knowledgeFromBuildings + efficiencyBonus + survivalBonus + stabilityBonus + timeBonus
        
        // Award KP to meta progression
        let meta = MetaState.load()
        meta.awardKnowledge(total)
        meta.saveLastLoopResources(metal: gameState.metal, energy: gameState.energy, biomass: gameState.biomass, research: gameState.research)
        
        // Full-screen opaque overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        overlay.fillColor = SKColor(red: 0.03, green: 0.03, blue: 0.06, alpha: 0.92)
        overlay.strokeColor = .clear
        overlay.zPosition = 300
        overlay.name = "summary"
        cameraNode.addChild(overlay)
        
        // Summary card
        let cardWidth: CGFloat = size.width * 0.85
        let cardHeight: CGFloat = 440
        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 16)
        card.fillColor = SKColor(red: 0.08, green: 0.08, blue: 0.14, alpha: 1)
        card.strokeColor = SKColor(red: 0.2, green: 0.25, blue: 0.4, alpha: 1)
        card.lineWidth = 1.5
        card.position = CGPoint(x: 0, y: 20)
        card.zPosition = 301
        card.name = "summary"
        cameraNode.addChild(card)
        
        // Title
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "LOOP COMPLETE"
        title.fontSize = 22
        title.fontColor = SKColor(red: 0.4, green: 0.75, blue: 1, alpha: 1)
        title.position = CGPoint(x: 0, y: cardHeight / 2 - 40)
        title.zPosition = 1
        card.addChild(title)
        
        // Divider
        let divider = SKShapeNode(rectOf: CGSize(width: cardWidth - 40, height: 1))
        divider.fillColor = SKColor(white: 0.2, alpha: 1)
        divider.strokeColor = .clear
        divider.position = CGPoint(x: 0, y: cardHeight / 2 - 55)
        divider.zPosition = 1
        card.addChild(divider)
        
        // Stats
        let stats: [(String, String)] = [
            ("Research", "\(Int(gameState.research))"),
            ("Buildings", "\(buildingCount) (\(activeCount) active)"),
            ("Stability", "\(Int(gameState.stability))%"),
            ("Survived", gameState.remainingTime < 1 ? "Full loop ✓" : "\(Int(gameState.elapsedTime))s"),
            ("", ""),
            ("Research →", "+\(knowledgeFromResearch)"),
            ("Buildings →", "+\(knowledgeFromBuildings)"),
            ("Efficiency →", "+\(efficiencyBonus)"),
            ("Stability →", "+\(stabilityBonus)"),
            ("Time →", "+\(timeBonus)"),
            (survivalBonus > 0 ? "Full loop! →" : "", survivalBonus > 0 ? "+\(survivalBonus)" : ""),
        ]
        
        let startY = cardHeight / 2 - 75
        for (i, stat) in stats.enumerated() {
            if stat.0.isEmpty { continue }
            
            let nameLabel = SKLabelNode(fontNamed: "Menlo")
            nameLabel.text = stat.0
            nameLabel.fontSize = 13
            nameLabel.fontColor = SKColor(white: 0.6, alpha: 1)
            nameLabel.position = CGPoint(x: -cardWidth / 2 + 30, y: startY - CGFloat(i) * 24)
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.zPosition = 1
            card.addChild(nameLabel)
            
            let valueLabel = SKLabelNode(fontNamed: "Menlo-Bold")
            valueLabel.text = stat.1
            valueLabel.fontSize = 13
            valueLabel.fontColor = .white
            valueLabel.position = CGPoint(x: cardWidth / 2 - 30, y: startY - CGFloat(i) * 24)
            valueLabel.horizontalAlignmentMode = .right
            valueLabel.zPosition = 1
            card.addChild(valueLabel)
            
            // Stagger in
            nameLabel.alpha = 0
            valueLabel.alpha = 0
            let delay = Double(i) * 0.1
            nameLabel.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.fadeIn(withDuration: 0.2)]))
            valueLabel.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.fadeIn(withDuration: 0.2)]))
        }
        
        // Total divider
        let totalDivider = SKShapeNode(rectOf: CGSize(width: cardWidth - 40, height: 1))
        totalDivider.fillColor = SKColor(red: 0.4, green: 0.75, blue: 1, alpha: 0.4)
        totalDivider.strokeColor = .clear
        totalDivider.position = CGPoint(x: 0, y: startY - CGFloat(stats.count) * 24 + 10)
        totalDivider.zPosition = 1
        card.addChild(totalDivider)
        
        // Total
        let totalLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        totalLabel.text = "Total Knowledge"
        totalLabel.fontSize = 14
        totalLabel.fontColor = SKColor(red: 0.4, green: 0.75, blue: 1, alpha: 1)
        totalLabel.position = CGPoint(x: -cardWidth / 2 + 30, y: startY - CGFloat(stats.count) * 24 - 12)
        totalLabel.horizontalAlignmentMode = .left
        totalLabel.zPosition = 1
        card.addChild(totalLabel)
        
        let totalValue = SKLabelNode(fontNamed: "Menlo-Bold")
        totalValue.text = "+\(total)"
        totalValue.fontSize = 18
        totalValue.fontColor = SKColor(red: 0.4, green: 0.9, blue: 1, alpha: 1)
        totalValue.position = CGPoint(x: cardWidth / 2 - 30, y: startY - CGFloat(stats.count) * 24 - 12)
        totalValue.horizontalAlignmentMode = .right
        totalValue.zPosition = 1
        card.addChild(totalValue)
        
        // Tech Tree button (primary)
        let btnY = -cardHeight / 2 + 55
        let techBtnBg = SKShapeNode(rectOf: CGSize(width: 200, height: 42), cornerRadius: 12)
        techBtnBg.fillColor = SKColor(red: 0.15, green: 0.35, blue: 0.6, alpha: 1)
        techBtnBg.strokeColor = SKColor(red: 0.3, green: 0.55, blue: 0.9, alpha: 1)
        techBtnBg.lineWidth = 1.5
        techBtnBg.position = CGPoint(x: 0, y: btnY)
        techBtnBg.zPosition = 1
        techBtnBg.name = "techTreeButtonInner"
        card.addChild(techBtnBg)
        
        let techLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        techLabel.text = "💡 SPEND KNOWLEDGE"
        techLabel.fontSize = 13
        techLabel.fontColor = .white
        techLabel.verticalAlignmentMode = .center
        techBtnBg.addChild(techLabel)
        
        // Quick restart button (secondary, below)
        let restartBtnY = btnY - 48
        let restartBg = SKShapeNode(rectOf: CGSize(width: 140, height: 32), cornerRadius: 10)
        restartBg.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1)
        restartBg.strokeColor = SKColor(white: 0.25, alpha: 1)
        restartBg.lineWidth = 1
        restartBg.position = CGPoint(x: 0, y: restartBtnY)
        restartBg.zPosition = 1
        restartBg.name = "quickRestartInner"
        card.addChild(restartBg)
        
        let skipLabel = SKLabelNode(fontNamed: "Menlo")
        skipLabel.text = "Quick Restart"
        skipLabel.fontSize = 11
        skipLabel.fontColor = SKColor(white: 0.5, alpha: 1)
        skipLabel.verticalAlignmentMode = .center
        restartBg.addChild(skipLabel)
        
        // Hit targets in camera space
        let techHit = SKShapeNode(rectOf: CGSize(width: 200, height: 42))
        techHit.fillColor = .clear
        techHit.strokeColor = .clear
        techHit.position = CGPoint(x: 0, y: 20 + btnY)
        techHit.zPosition = 302
        techHit.name = "techTreeButton"
        cameraNode.addChild(techHit)
        
        let restartHit = SKShapeNode(rectOf: CGSize(width: 140, height: 32))
        restartHit.fillColor = .clear
        restartHit.strokeColor = .clear
        restartHit.position = CGPoint(x: 0, y: 20 + restartBtnY)
        restartHit.zPosition = 302
        restartHit.name = "restartButton"
        cameraNode.addChild(restartHit)
        
        // Animate card in
        card.setScale(0.9)
        card.alpha = 0
        card.run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.3),
            SKAction.fadeIn(withDuration: 0.3)
        ]))
    }
    
    private func openTechTree() {
        guard let skView = self.view else { return }
        run(SoundManager.shared.tap)
        tutorial.onTechTreeOpened()
        
        let techScene = TechTreeScene(size: self.size)
        techScene.scaleMode = .resizeFill
        techScene.onStartLoop = { [weak skView] in
            let newGameScene = GameScene(size: skView?.bounds.size ?? CGSize(width: 320, height: 480))
            newGameScene.scaleMode = .resizeFill
            skView?.presentScene(newGameScene, transition: SKTransition.fade(withDuration: 0.5))
        }
        skView.presentScene(techScene, transition: SKTransition.fade(withDuration: 0.3))
    }
    
    private func restartLoop() {
        run(SoundManager.shared.newloop)
        // Remove all summary nodes
        cameraNode.children.filter { $0.name == "summary" || $0.name == "restartButton" || $0.name == "techTreeButton" || $0.name == "collapseEffect" }.forEach { $0.removeFromParent() }
        
        // Show game UI again
        hudRenderer.hudNode.isHidden = false
        buildMenu.menuNode.isHidden = false
        
        // Reset camera
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        cameraNode.setScale(1.0)
        
        // Reset state with tech effects
        gameState = GameState()
        gridModel = GridModel()
        gridModel.generateMap(rng: &gameState.rng)
        eventSystem.setup(rng: &gameState.rng)
        eventOverlay.dismiss()
        escalationTintNode?.alpha = 0
        lastWarningFlash = 0
        
        // Reload tech effects
        let meta = MetaState.load()
        techEffects = TechEffects(meta: meta)
        applyTechEffectsToState()
        
        gameState.phase = .expansion
        lastTickTime = 0
        tickAccumulator = 0
        
        gridRenderer.update(from: gridModel, state: gameState)
        hudRenderer.update(state: gameState)
        buildMenu.clearSelection()
        buildMenu.updateAffordability(state: gameState)
    }
    
    // MARK: - BuildMenuDelegate
    
    func buildMenuDidSelect(buildingType: BuildingType) {
        gridRenderer.clearSelection()
        infoPanel?.dismiss()
        infoPanel = nil
        tutorial.onBuildingSelected()
    }
    
    func buildMenuDidSelectDemolish() { gridRenderer.clearSelection() }
    func buildMenuDidSelectAssignWorker() { gridRenderer.clearSelection() }
    func buildMenuDidSelectToggle() { gridRenderer.clearSelection() }
    
    // MARK: - EventOverlayDelegate
    
    func eventOverlayDidChoose(choiceIndex: Int) {
        run(SoundManager.shared.choice)
        eventSystem.resolveChoice(choiceIndex: choiceIndex, grid: gridModel, state: gameState, rng: &gameState.rng)
        eventOverlay.dismiss()
        
        // Flash effect for feedback
        let flash = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        flash.fillColor = SKColor.white.withAlphaComponent(0.15)
        flash.strokeColor = .clear
        flash.zPosition = 350
        cameraNode.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }
    
    func eventOverlayDidDismiss() {
        run(SoundManager.shared.tap)
        // Emergency Protocols: dismiss costs 5 stability
        gameState.stability = max(0, gameState.stability - (techEffects.eventDismissCost))
        eventSystem.currentEvent = nil
        eventSystem.isShowingEvent = false
        eventOverlay.dismiss()
        
        showFloatingText("-5 Stability", at: GameConstants.gridColumns / 2, row: GameConstants.gridRows / 2, color: .orange)
    }
}
