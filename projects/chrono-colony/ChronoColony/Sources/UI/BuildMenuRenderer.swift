import SpriteKit

/// Delegate for build menu actions
protocol BuildMenuDelegate: AnyObject {
    func buildMenuDidSelect(buildingType: BuildingType)
    func buildMenuDidSelectDemolish()
    func buildMenuDidSelectAssignWorker()
    func buildMenuDidSelectToggle()
}

/// Bottom build menu — tap to select a building type, then tap grid to place
final class BuildMenuRenderer {
    let menuNode: SKNode
    weak var delegate: BuildMenuDelegate?
    
    private var buttons: [SKShapeNode] = []
    private var selectedIndex: Int? = nil
    private var buttonSize: CGFloat = 46
    private var buttonSpacing: CGFloat = 4
    
    var selectedBuildingType: BuildingType? {
        guard let idx = selectedIndex, idx < BuildingType.allCases.count else { return nil }
        return BuildingType.allCases[idx]
    }
    
    var isDemolishMode: Bool {
        selectedIndex == BuildingType.allCases.count
    }
    
    var isAssignWorkerMode: Bool {
        selectedIndex == BuildingType.allCases.count + 1
    }
    
    var isToggleMode: Bool {
        selectedIndex == BuildingType.allCases.count + 2
    }
    
    init(sceneSize: CGSize) {
        menuNode = SKNode()
        menuNode.name = "buildMenu"
        menuNode.zPosition = 100
        
        // Adapt button size to screen width
        let allItems = BuildingType.allCases.count + 3 // +demolish +assign +toggle
        let maxWidth = sceneSize.width - 20
        let idealTotal = CGFloat(allItems) * buttonSize + CGFloat(allItems - 1) * buttonSpacing
        if idealTotal > maxWidth {
            buttonSize = (maxWidth - CGFloat(allItems - 1) * buttonSpacing) / CGFloat(allItems)
        }
        
        let bottomY = -sceneSize.height / 2 + 50
        let totalWidth = CGFloat(allItems) * buttonSize + CGFloat(allItems - 1) * buttonSpacing
        let startX = -totalWidth / 2 + buttonSize / 2
        
        // Background panel
        let bgPanel = SKShapeNode(rectOf: CGSize(width: totalWidth + 24, height: buttonSize + 24), cornerRadius: 14)
        bgPanel.fillColor = SKColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.95)
        bgPanel.strokeColor = SKColor(red: 0.15, green: 0.18, blue: 0.28, alpha: 0.8)
        bgPanel.lineWidth = 1
        bgPanel.position = CGPoint(x: 0, y: bottomY)
        bgPanel.zPosition = -1
        menuNode.addChild(bgPanel)
        
        // Building buttons
        for (i, type) in BuildingType.allCases.enumerated() {
            let btn = makeButton(
                symbol: type.symbol,
                subtitle: "\(Int(type.metalCost))⛏",
                color: type.color,
                x: startX + CGFloat(i) * (buttonSize + buttonSpacing),
                y: bottomY
            )
            btn.name = "build_\(i)"
            menuNode.addChild(btn)
            buttons.append(btn)
        }
        
        // Demolish button
        let demolishIdx = BuildingType.allCases.count
        let demolishBtn = makeButton(
            symbol: "🗑",
            subtitle: "Demo",
            color: SKColor(red: 0.6, green: 0.2, blue: 0.2, alpha: 1),
            x: startX + CGFloat(demolishIdx) * (buttonSize + buttonSpacing),
            y: bottomY
        )
        demolishBtn.name = "build_\(demolishIdx)"
        menuNode.addChild(demolishBtn)
        buttons.append(demolishBtn)
        
        // Assign worker button
        let workerIdx = demolishIdx + 1
        let workerBtn = makeButton(
            symbol: "👤",
            subtitle: "Staff",
            color: SKColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1),
            x: startX + CGFloat(workerIdx) * (buttonSize + buttonSpacing),
            y: bottomY
        )
        workerBtn.name = "build_\(workerIdx)"
        menuNode.addChild(workerBtn)
        buttons.append(workerBtn)
        
        // Toggle (enable/disable) button
        let toggleIdx = workerIdx + 1
        let toggleBtn = makeButton(
            symbol: "⏸",
            subtitle: "Toggle",
            color: SKColor(red: 0.5, green: 0.4, blue: 0.15, alpha: 1),
            x: startX + CGFloat(toggleIdx) * (buttonSize + buttonSpacing),
            y: bottomY
        )
        toggleBtn.name = "build_\(toggleIdx)"
        menuNode.addChild(toggleBtn)
        buttons.append(toggleBtn)
    }
    
    func handleTap(at point: CGPoint) -> Bool {
        for (i, btn) in buttons.enumerated() {
            let localPoint = btn.convert(point, from: menuNode)
            if btn.contains(localPoint) {
                selectButton(i)
                return true
            }
        }
        return false
    }
    
    private func selectButton(_ index: Int) {
        // Deselect previous
        if let prev = selectedIndex {
            buttons[prev].strokeColor = SKColor(red: 0.25, green: 0.25, blue: 0.35, alpha: 1)
            buttons[prev].lineWidth = 1
        }
        
        // Toggle if same button
        if selectedIndex == index {
            selectedIndex = nil
            return
        }
        
        selectedIndex = index
        buttons[index].strokeColor = .white
        buttons[index].lineWidth = 2
        
        // Notify delegate
        if let type = selectedBuildingType {
            delegate?.buildMenuDidSelect(buildingType: type)
        } else if isDemolishMode {
            delegate?.buildMenuDidSelectDemolish()
        } else if isAssignWorkerMode {
            delegate?.buildMenuDidSelectAssignWorker()
        } else if isToggleMode {
            delegate?.buildMenuDidSelectToggle()
        }
    }
    
    func clearSelection() {
        if let prev = selectedIndex {
            buttons[prev].strokeColor = SKColor(red: 0.25, green: 0.25, blue: 0.35, alpha: 1)
            buttons[prev].lineWidth = 1
        }
        selectedIndex = nil
    }
    
    private func makeButton(symbol: String, subtitle: String, color: SKColor, x: CGFloat, y: CGFloat) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: CGSize(width: buttonSize, height: buttonSize), cornerRadius: 10)
        btn.position = CGPoint(x: x, y: y)
        btn.fillColor = color.withAlphaComponent(0.25)
        btn.strokeColor = SKColor(red: 0.25, green: 0.25, blue: 0.35, alpha: 1)
        btn.lineWidth = 1
        
        let symbolLabel = SKLabelNode(text: symbol)
        symbolLabel.fontSize = 22
        symbolLabel.verticalAlignmentMode = .center
        symbolLabel.position = CGPoint(x: 0, y: 5)
        btn.addChild(symbolLabel)
        
        let costLabel = SKLabelNode(fontNamed: "Menlo")
        costLabel.text = subtitle
        costLabel.fontSize = 9
        costLabel.fontColor = SKColor(white: 0.6, alpha: 1)
        costLabel.verticalAlignmentMode = .center
        costLabel.position = CGPoint(x: 0, y: -16)
        btn.addChild(costLabel)
        
        return btn
    }
    
    func updateAffordability(state: GameState) {
        for (i, type) in BuildingType.allCases.enumerated() {
            let canAfford = state.metal >= type.metalCost
            buttons[i].alpha = canAfford ? 1.0 : 0.4
        }
    }
}
