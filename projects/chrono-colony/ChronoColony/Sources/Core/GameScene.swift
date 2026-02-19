import SpriteKit
import GameplayKit

/// Main game scene — owns the simulation loop
class GameScene: SKScene, BuildMenuDelegate {
    
    // MARK: - Core
    private var gameState: GameState!
    private var gridModel: GridModel!
    private var resourceSystem: ResourceSystem!
    
    // MARK: - Renderers
    private var gridRenderer: GridRenderer!
    private var hudRenderer: HUDRenderer!
    private var buildMenu: BuildMenuRenderer!
    
    // MARK: - Timing
    private var lastTickTime: TimeInterval = 0
    private var tickAccumulator: TimeInterval = 0
    
    // MARK: - Scene Setup
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)
        
        // Initialize systems
        gameState = GameState()
        gridModel = GridModel()
        resourceSystem = ResourceSystem()
        
        // Generate map
        gridModel.generateMap(rng: &gameState.rng)
        
        // Grid renderer
        gridRenderer = GridRenderer(
            columns: GameConstants.gridColumns,
            rows: GameConstants.gridRows,
            tileSize: GameConstants.tileSize
        )
        addChild(gridRenderer.gridNode)
        
        // Position grid slightly above center to make room for build menu
        gridRenderer.gridNode.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        
        // HUD
        hudRenderer = HUDRenderer(sceneSize: size)
        hudRenderer.hudNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(hudRenderer.hudNode)
        
        // Build menu
        buildMenu = BuildMenuRenderer(sceneSize: size)
        buildMenu.menuNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        buildMenu.delegate = self
        addChild(buildMenu.menuNode)
        
        // Start the loop
        gameState.phase = .expansion
        
        // Initial render
        gridRenderer.update(from: gridModel)
        hudRenderer.update(state: gameState)
        buildMenu.updateAffordability(state: gameState)
    }
    
    // MARK: - Game Loop
    
    override func update(_ currentTime: TimeInterval) {
        guard gameState.phase != .collapse && gameState.phase != .summary else { return }
        
        // Delta time
        if lastTickTime == 0 { lastTickTime = currentTime }
        let dt = currentTime - lastTickTime
        lastTickTime = currentTime
        
        // Advance game time
        gameState.elapsedTime += dt
        
        // Phase transitions
        if gameState.elapsedTime >= GameConstants.loopDuration {
            triggerCollapse()
            return
        } else if gameState.elapsedTime >= GameConstants.escalationStart && gameState.phase == .expansion {
            gameState.phase = .escalation
        }
        
        // Stability death check
        if gameState.stability <= 0 {
            triggerCollapse()
            return
        }
        
        // Simulation tick (1/sec)
        tickAccumulator += dt
        if tickAccumulator >= GameConstants.simulationTickRate {
            tickAccumulator -= GameConstants.simulationTickRate
            resourceSystem.tick(grid: gridModel, state: gameState)
        }
        
        // Update visuals
        gridRenderer.update(from: gridModel)
        hudRenderer.update(state: gameState)
        buildMenu.updateAffordability(state: gameState)
    }
    
    // MARK: - Touch Input
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check build menu first
        if buildMenu.handleTap(at: location) {
            return
        }
        
        // Check grid tap
        let gridLocal = touch.location(in: gridRenderer.gridNode)
        if let pos = gridRenderer.gridPosition(from: gridLocal) {
            handleGridTap(col: pos.col, row: pos.row)
        }
    }
    
    private func handleGridTap(col: Int, row: Int) {
        if let buildingType = buildMenu.selectedBuildingType {
            // Place building
            if gridModel.placeBuilding(buildingType, at: col, row: row, state: gameState) {
                gridRenderer.highlightTile(col: col, row: row)
                // Auto-assign worker if available
                if gameState.availableColonists > 0 {
                    gridModel.assignWorker(at: col, row: row, state: gameState)
                }
            }
        } else if buildMenu.isDemolishMode {
            // Demolish
            gridModel.demolishBuilding(at: col, row: row, state: gameState)
        } else if buildMenu.isAssignWorkerMode {
            // Toggle worker
            if let tile = gridModel.tile(at: col, row: row), tile.assignedWorkers > 0 {
                gridModel.removeWorker(at: col, row: row, state: gameState)
            } else {
                gridModel.assignWorker(at: col, row: row, state: gameState)
            }
        }
        
        gridRenderer.update(from: gridModel)
    }
    
    // MARK: - Collapse
    
    private func triggerCollapse() {
        gameState.phase = .collapse
        
        // Flash screen red
        let flash = SKShapeNode(rectOf: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.fillColor = SKColor.red.withAlphaComponent(0.5)
        flash.strokeColor = .clear
        flash.zPosition = 200
        addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 1.5),
            SKAction.removeFromParent()
        ]))
        
        // Show collapse label
        let collapseLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        collapseLabel.text = "STELLAR COLLAPSE"
        collapseLabel.fontSize = 28
        collapseLabel.fontColor = .red
        collapseLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        collapseLabel.zPosition = 201
        collapseLabel.setScale(0.1)
        addChild(collapseLabel)
        
        collapseLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.0, duration: 0.5),
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.run { [weak self] in
                self?.showSummary()
            },
            SKAction.removeFromParent()
        ]))
    }
    
    private func showSummary() {
        gameState.phase = .summary
        
        let knowledgeEarned = Int(gameState.research * 0.3 + Double(gridModel.allBuildings().count) * 5)
        
        let summaryLabel = SKLabelNode(fontNamed: "Menlo")
        summaryLabel.text = "Knowledge earned: +\(knowledgeEarned)"
        summaryLabel.fontSize = 18
        summaryLabel.fontColor = SKColor(red: 0.5, green: 0.8, blue: 1, alpha: 1)
        summaryLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        summaryLabel.zPosition = 201
        addChild(summaryLabel)
        
        let restartLabel = SKLabelNode(fontNamed: "Menlo")
        restartLabel.text = "Tap to start new loop"
        restartLabel.fontSize = 14
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        restartLabel.zPosition = 201
        restartLabel.name = "restart"
        addChild(restartLabel)
        
        // Pulse the restart label
        restartLabel.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        ])))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState.phase == .summary else { return }
        restartLoop()
    }
    
    private func restartLoop() {
        // Remove summary UI
        children.filter { $0.zPosition >= 201 }.forEach { $0.removeFromParent() }
        
        // Reset state with new seed
        gameState = GameState()
        gridModel = GridModel()
        gridModel.generateMap(rng: &gameState.rng)
        gameState.phase = .expansion
        lastTickTime = 0
        tickAccumulator = 0
        
        gridRenderer.update(from: gridModel)
        hudRenderer.update(state: gameState)
        buildMenu.clearSelection()
        buildMenu.updateAffordability(state: gameState)
    }
    
    // MARK: - BuildMenuDelegate
    
    func buildMenuDidSelect(buildingType: BuildingType) {
        // Could show placement preview in the future
    }
    
    func buildMenuDidSelectDemolish() {}
    func buildMenuDidSelectAssignWorker() {}
}
