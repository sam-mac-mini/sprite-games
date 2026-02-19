import SpriteKit

/// Delegate for build menu actions
protocol BuildMenuDelegate: AnyObject {
    func buildMenuDidSelect(buildingType: BuildingType)
    func buildMenuDidSelectDemolish()
    func buildMenuDidSelectAssignWorker()
}

/// Bottom build menu — tap to select a building type, then tap grid to place
final class BuildMenuRenderer {
    let menuNode: SKNode
    weak var delegate: BuildMenuDelegate?
    
    private var buttons: [SKShapeNode] = []
    private var selectedIndex: Int? = nil
    private let buttonSize: CGFloat = 64
    
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
    
    init(sceneSize: CGSize) {
        menuNode = SKNode()
        menuNode.name = "buildMenu"
        menuNode.zPosition = 100
        
        let bottomY = -sceneSize.height / 2 + 50
        let allItems = BuildingType.allCases.count + 2 // +demolish +assign
        let totalWidth = CGFloat(allItems) * (buttonSize + 8)
        let startX = -totalWidth / 2 + buttonSize / 2
        
        // Building buttons
        for (i, type) in BuildingType.allCases.enumerated() {
            let btn = makeButton(
                symbol: type.symbol,
                subtitle: "\(Int(type.metalCost))⛏",
                color: type.color,
                x: startX + CGFloat(i) * (buttonSize + 8),
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
            x: startX + CGFloat(demolishIdx) * (buttonSize + 8),
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
            x: startX + CGFloat(workerIdx) * (buttonSize + 8),
            y: bottomY
        )
        workerBtn.name = "build_\(workerIdx)"
        menuNode.addChild(workerBtn)
        buttons.append(workerBtn)
    }
    
    func handleTap(at point: CGPoint) -> Bool {
        let localPoint = menuNode.convert(point, from: menuNode.scene!)
        
        for (i, btn) in buttons.enumerated() {
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
            buttons[prev].strokeColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1)
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
        }
    }
    
    func clearSelection() {
        if let prev = selectedIndex {
            buttons[prev].strokeColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1)
            buttons[prev].lineWidth = 1
        }
        selectedIndex = nil
    }
    
    private func makeButton(symbol: String, subtitle: String, color: SKColor, x: CGFloat, y: CGFloat) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: CGSize(width: buttonSize, height: buttonSize), cornerRadius: 8)
        btn.position = CGPoint(x: x, y: y)
        btn.fillColor = color.withAlphaComponent(0.3)
        btn.strokeColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1)
        btn.lineWidth = 1
        
        let symbolLabel = SKLabelNode(text: symbol)
        symbolLabel.fontSize = 24
        symbolLabel.verticalAlignmentMode = .center
        symbolLabel.position = CGPoint(x: 0, y: 6)
        btn.addChild(symbolLabel)
        
        let costLabel = SKLabelNode(fontNamed: "Menlo")
        costLabel.text = subtitle
        costLabel.fontSize = 10
        costLabel.fontColor = SKColor(red: 0.7, green: 0.7, blue: 0.8, alpha: 1)
        costLabel.verticalAlignmentMode = .center
        costLabel.position = CGPoint(x: 0, y: -18)
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
