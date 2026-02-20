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
    private var buttonSpacing: CGFloat = 6
    private var symbolFontSize: CGFloat = 22
    private var subtitleFontSize: CGFloat = 9
    private var symbolYOffset: CGFloat = 5
    private var subtitleYOffset: CGFloat = -16
    private let minimumTapTarget: CGFloat = 60
    private let maxSingleRowItems = 9
    
    /// Buildings available for this loop (filtered by tech unlocks)
    private(set) var availableBuildings: [BuildingType] = BuildingType.starterBuildings
    
    var selectedBuildingType: BuildingType? {
        guard let idx = selectedIndex, idx < availableBuildings.count else { return nil }
        return availableBuildings[idx]
    }
    
    var isDemolishMode: Bool {
        selectedIndex == availableBuildings.count
    }
    
    var isAssignWorkerMode: Bool {
        selectedIndex == availableBuildings.count + 1
    }
    
    var isToggleMode: Bool {
        selectedIndex == availableBuildings.count + 2
    }
    
    init(sceneSize: CGSize, safeBottom: CGFloat = 0, unlockedBuildings: [BuildingType]? = nil) {
        menuNode = SKNode()
        menuNode.name = "buildMenu"
        menuNode.zPosition = 100
        
        // Set available buildings
        availableBuildings = unlockedBuildings ?? BuildingType.starterBuildings
        
        let allItems = availableBuildings.count + 3 // +demolish +assign +toggle
        let rowCount = allItems > maxSingleRowItems ? 2 : 1
        let itemsPerRow = Int(ceil(Double(allItems) / Double(rowCount)))

        // Adapt button size to screen width (based on widest row).
        let maxWidth = sceneSize.width - 20
        let rowSpacingWidth = CGFloat(max(0, itemsPerRow - 1)) * buttonSpacing
        let idealRowWidth = CGFloat(itemsPerRow) * buttonSize + rowSpacingWidth
        if idealRowWidth > maxWidth {
            buttonSize = (maxWidth - rowSpacingWidth) / CGFloat(itemsPerRow)
        }
        buttonSize = max(34, buttonSize)

        // Keep icon/text readable as item count increases.
        symbolFontSize = max(13, min(22, buttonSize * 0.48))
        subtitleFontSize = max(8, min(11, buttonSize * 0.24))
        symbolYOffset = max(2, buttonSize * 0.1)
        subtitleYOffset = max(-15, -buttonSize * 0.30)

        // Build rows (two rows when lots of unlocked buildings, one row otherwise).
        let rowHeight = buttonSize + buttonSpacing
        let panelHeight: CGFloat
        if rowCount == 1 {
            panelHeight = max(buttonSize + 24, minimumTapTarget + 16)
        } else {
            panelHeight = max(rowHeight * 2 + 16, minimumTapTarget + 16)
        }

        // Keep controls clear of home indicator / bottom unsafe area.
        let bottomPadding: CGFloat = 12
        let panelCenterY = -sceneSize.height / 2 + safeBottom + bottomPadding + panelHeight / 2

        // Background panel
        let widestRowCount = itemsPerRow
        let panelWidth = CGFloat(widestRowCount) * buttonSize + CGFloat(max(0, widestRowCount - 1)) * buttonSpacing + 24
        let bgPanel = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 14)
        bgPanel.fillColor = SKColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.95)
        bgPanel.strokeColor = SKColor(red: 0.15, green: 0.18, blue: 0.28, alpha: 0.8)
        bgPanel.lineWidth = 1
        bgPanel.position = CGPoint(x: 0, y: panelCenterY)
        bgPanel.zPosition = -1
        menuNode.addChild(bgPanel)

        func positionForIndex(_ index: Int) -> CGPoint {
            let row = index / itemsPerRow
            let col = index % itemsPerRow
            let countInRow = min(itemsPerRow, allItems - row * itemsPerRow)
            let rowWidth = CGFloat(countInRow) * buttonSize + CGFloat(max(0, countInRow - 1)) * buttonSpacing
            let startX = -rowWidth / 2 + buttonSize / 2

            let yOffset: CGFloat
            if rowCount == 1 {
                yOffset = 0
            } else {
                yOffset = row == 0 ? rowHeight / 2 : -rowHeight / 2
            }

            return CGPoint(
                x: startX + CGFloat(col) * (buttonSize + buttonSpacing),
                y: panelCenterY + yOffset
            )
        }

        // Build all menu items in index order.
        struct MenuItem {
            let iconName: String?
            let title: String
            let subtitle: String
            let color: SKColor
        }
        var menuItems: [MenuItem] = availableBuildings.map {
            MenuItem(
                iconName: $0.imageName,
                title: $0.rawValue,
                subtitle: "\(Int($0.metalCost)) MTL",
                color: $0.color
            )
        }

        // Action controls use Kenney-style textured cards + clear text (no emojis)
        menuItems.append(MenuItem(iconName: "anomaly", title: "DEMOLISH", subtitle: "Demo", color: SKColor(red: 0.6, green: 0.2, blue: 0.2, alpha: 1)))
        menuItems.append(MenuItem(iconName: "cloneVats", title: "WORKERS", subtitle: "Staff", color: SKColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1)))
        menuItems.append(MenuItem(iconName: "shieldGenerator", title: "POWER", subtitle: "Toggle", color: SKColor(red: 0.5, green: 0.4, blue: 0.15, alpha: 1)))

        for (index, item) in menuItems.enumerated() {
            let pos = positionForIndex(index)
            let btn = makeButton(
                iconName: item.iconName,
                title: item.title,
                subtitle: item.subtitle,
                color: item.color,
                x: pos.x,
                y: pos.y
            )
            btn.name = "build_\(index)"
            menuNode.addChild(btn)
            buttons.append(btn)
        }
    }
    
    func handleTap(at point: CGPoint) -> Bool {
        for (i, btn) in buttons.enumerated() {
            // Use frame-based hit testing with an expanded target for thumb-friendly controls.
            let halfW = max(buttonSize, minimumTapTarget) / 2
            let halfH = max(buttonSize, minimumTapTarget) / 2
            let bx = btn.position.x
            let by = btn.position.y
            if point.x >= bx - halfW && point.x <= bx + halfW &&
               point.y >= by - halfH && point.y <= by + halfH {
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
            buttons[prev].setScale(1.0)
        }
        
        // Toggle if same button
        if selectedIndex == index {
            selectedIndex = nil
            return
        }
        
        selectedIndex = index
        buttons[index].strokeColor = SKColor(red: 0.45, green: 0.82, blue: 1.0, alpha: 1)
        buttons[index].lineWidth = 2
        buttons[index].setScale(1.05)
        
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
            buttons[prev].setScale(1.0)
        }
        selectedIndex = nil
    }
    
    private func makeButton(iconName: String?, title: String, subtitle: String, color: SKColor, x: CGFloat, y: CGFloat) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: CGSize(width: buttonSize, height: buttonSize), cornerRadius: 10)
        btn.position = CGPoint(x: x, y: y)
        btn.fillColor = color.withAlphaComponent(0.22)
        btn.strokeColor = SKColor(red: 0.25, green: 0.25, blue: 0.35, alpha: 1)
        btn.lineWidth = 1
        
        // Kenney textured underlay
        let bgTex = SKSpriteNode(imageNamed: "groundTile")
        bgTex.size = CGSize(width: buttonSize - 4, height: buttonSize - 4)
        bgTex.color = color
        bgTex.colorBlendFactor = 0.35
        bgTex.alpha = 0.45
        bgTex.zPosition = -1
        btn.addChild(bgTex)
        
        if let iconName {
            let icon = SKSpriteNode(imageNamed: iconName)
            icon.size = CGSize(width: buttonSize * 0.45, height: buttonSize * 0.45)
            icon.position = CGPoint(x: 0, y: symbolYOffset + 2)
            icon.name = "iconSprite"
            btn.addChild(icon)
        }
        
        let titleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        titleLabel.text = title.count > 8 ? String(title.prefix(8)) : title
        titleLabel.fontSize = max(7, subtitleFontSize - 1)
        titleLabel.fontColor = SKColor(white: 0.8, alpha: 1)
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: subtitleYOffset + 9)
        titleLabel.name = "titleLabel"
        btn.addChild(titleLabel)
        
        let costLabel = SKLabelNode(fontNamed: "Menlo")
        costLabel.text = subtitle
        costLabel.fontSize = subtitleFontSize
        costLabel.fontColor = SKColor(white: 0.82, alpha: 1)
        costLabel.verticalAlignmentMode = .center
        costLabel.position = CGPoint(x: 0, y: subtitleYOffset - 1)
        costLabel.name = "subtitleLabel"
        btn.addChild(costLabel)
        
        return btn
    }
    
    func updateAffordability(state: GameState) {
        for (i, type) in availableBuildings.enumerated() {
            guard i < buttons.count else { break }
            let canAfford = state.metal >= type.metalCost
            let button = buttons[i]
            button.alpha = canAfford ? 1.0 : 0.45
            
            if let subtitle = button.childNode(withName: "subtitleLabel") as? SKLabelNode {
                subtitle.fontColor = canAfford
                    ? SKColor(white: 0.82, alpha: 1)
                    : SKColor(red: 1.0, green: 0.45, blue: 0.45, alpha: 1)
            }
        }
    }
}
