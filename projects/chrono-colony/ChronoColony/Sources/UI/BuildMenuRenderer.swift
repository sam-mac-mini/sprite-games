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
    private var isButtonAffordable: [Bool] = []
    private var selectedIndex: Int? = nil
    private var buttonSize: CGFloat = 46
    private var buttonSpacing: CGFloat = 6
    private var symbolFontSize: CGFloat = 22
    private var subtitleFontSize: CGFloat = 9
    private var symbolYOffset: CGFloat = 5
    private var subtitleYOffset: CGFloat = -16
    private var isUltraCompactMenu: Bool = false
    private var selectedScale: CGFloat = 1.05
    private let minimumTapTarget: CGFloat = 64
    private let maxSingleRowItems = 6
    
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

        // Tight screens need smaller gutters and sometimes an extra row.
        buttonSpacing = sceneSize.width < 360 ? 4 : 6

        var rowCount = allItems > maxSingleRowItems ? 2 : 1
        // Dense menus (11+ entries) are always 3 rows to avoid icon/text clipping.
        if allItems >= 11 {
            rowCount = 3
        } else if sceneSize.width < 360, allItems >= 9 {
            rowCount = 3
        }
        let itemsPerRow = Int(ceil(Double(allItems) / Double(rowCount)))

        // Adapt button size to screen width (based on widest row).
        let sideInset: CGFloat = sceneSize.width < 360 ? 28 : 20
        let maxWidth = sceneSize.width - sideInset
        let rowSpacingWidth = CGFloat(max(0, itemsPerRow - 1)) * buttonSpacing
        let idealRowWidth = CGFloat(itemsPerRow) * buttonSize + rowSpacingWidth
        if idealRowWidth > maxWidth {
            buttonSize = (maxWidth - rowSpacingWidth) / CGFloat(itemsPerRow)
        }
        let minButtonSize: CGFloat = sceneSize.width < 360 ? 36 : 34
        buttonSize = max(minButtonSize, buttonSize)

        isUltraCompactMenu = sceneSize.width < 360 || buttonSize <= 40
        selectedScale = isUltraCompactMenu ? 1.04 : 1.05

        // Keep icon/text readable as item count increases.
        symbolFontSize = max(12, min(22, buttonSize * (isUltraCompactMenu ? 0.44 : 0.48)))
        subtitleFontSize = max(8, min(11, buttonSize * (isUltraCompactMenu ? 0.22 : 0.24)))
        symbolYOffset = max(2, buttonSize * 0.1)
        subtitleYOffset = max(-15, -buttonSize * 0.30)

        let rowHeight = buttonSize + buttonSpacing
        let panelHeight: CGFloat
        if rowCount == 1 {
            panelHeight = max(buttonSize + 24, minimumTapTarget + 16)
        } else {
            panelHeight = max(rowHeight * CGFloat(rowCount) + 16, minimumTapTarget + 16)
        }

        // Keep controls clear of home indicator / bottom unsafe area.
        let bottomPadding: CGFloat = 20
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
                let totalRowsHeight = CGFloat(rowCount - 1) * rowHeight
                yOffset = totalRowsHeight / 2 - CGFloat(row) * rowHeight
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
                title: $0.menuTitle,
                subtitle: Self.compactCostString($0.metalCost, ultraCompact: isUltraCompactMenu),
                color: $0.color
            )
        }

        let demolishTitle = isUltraCompactMenu ? "DEMO" : "DEMOLISH"
        let workersTitle = isUltraCompactMenu ? "CREW" : "WORKERS"
        let powerTitle = isUltraCompactMenu ? "PWR" : "POWER"

        let demolishSubtitle = isUltraCompactMenu ? "RMV" : "REMOVE"
        let workersSubtitle = isUltraCompactMenu ? "WRK" : "ASSIGN"
        let powerSubtitle = isUltraCompactMenu ? "TGL" : "ON/OFF"

        // Action controls use Kenney-style textured cards + clear text (no emojis)
        menuItems.append(MenuItem(iconName: "anomaly", title: demolishTitle, subtitle: demolishSubtitle, color: SKColor(red: 0.6, green: 0.2, blue: 0.2, alpha: 1)))
        menuItems.append(MenuItem(iconName: "cloneVats", title: workersTitle, subtitle: workersSubtitle, color: SKColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1)))
        menuItems.append(MenuItem(iconName: "shieldGenerator", title: powerTitle, subtitle: powerSubtitle, color: SKColor(red: 0.5, green: 0.4, blue: 0.15, alpha: 1)))

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

        // Build options default to affordable until updateAffordability(state:) runs.
        isButtonAffordable = Array(repeating: true, count: buttons.count)
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
            resetButtonStyle(at: prev)
            buttons[prev].setScale(1.0)
        }
        
        // Toggle if same button
        if selectedIndex == index {
            selectedIndex = nil
            return
        }
        
        selectedIndex = index
        let selectedButton = buttons[index]
        let isUnaffordableSelection = index < isButtonAffordable.count
            ? !isButtonAffordable[index]
            : (selectedButton.alpha < 0.99)
        selectedButton.strokeColor = isUnaffordableSelection
            ? SKColor(red: 0.74, green: 0.50, blue: 0.50, alpha: 1)
            : SKColor(red: 0.45, green: 0.82, blue: 1.0, alpha: 1)
        selectedButton.lineWidth = isUnaffordableSelection
            ? (isUltraCompactMenu ? 1.2 : 1.4)
            : (isUltraCompactMenu ? 1.7 : 2)
        selectedButton.setScale(selectedScale)
        
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
            resetButtonStyle(at: prev)
            buttons[prev].setScale(1.0)
        }
        selectedIndex = nil
    }

    private func resetButtonStyle(at index: Int) {
        guard index >= 0 && index < buttons.count else { return }
        let button = buttons[index]
        let isUnaffordable = index < isButtonAffordable.count ? !isButtonAffordable[index] : (button.alpha < 0.99)

        button.lineWidth = isUnaffordable ? (isUltraCompactMenu ? 1.0 : 1.1) : 1
        button.strokeColor = isUnaffordable
            ? (isUltraCompactMenu
                ? SKColor(red: 0.56, green: 0.42, blue: 0.42, alpha: 1)
                : SKColor(red: 0.50, green: 0.36, blue: 0.36, alpha: 1))
            : SKColor(red: 0.25, green: 0.25, blue: 0.35, alpha: 1)
    }
    
    private func makeButton(iconName: String?, title: String, subtitle: String, color: SKColor, x: CGFloat, y: CGFloat) -> SKShapeNode {
        let cornerRadius: CGFloat = isUltraCompactMenu ? 8 : 10
        let btn = SKShapeNode(rectOf: CGSize(width: buttonSize, height: buttonSize), cornerRadius: cornerRadius)
        btn.position = CGPoint(x: x, y: y)
        btn.fillColor = color.withAlphaComponent(0.24)
        btn.strokeColor = SKColor(red: 0.25, green: 0.25, blue: 0.35, alpha: 1)
        btn.lineWidth = 1
        
        // Kenney textured underlay
        let bgTex = SKSpriteNode(imageNamed: "groundTile")
        bgTex.size = CGSize(width: buttonSize - 4, height: buttonSize - 4)
        bgTex.color = color
        bgTex.colorBlendFactor = 0.35
        bgTex.alpha = 0.40
        bgTex.zPosition = -1
        bgTex.name = "textureBg"
        btn.addChild(bgTex)
        
        if let iconName {
            let icon = SKSpriteNode(imageNamed: iconName)
            let iconScale = isUltraCompactMenu ? 0.38 : 0.45
            icon.size = CGSize(width: buttonSize * iconScale, height: buttonSize * iconScale)
            icon.position = CGPoint(x: 0, y: symbolYOffset + 2)
            icon.name = "iconSprite"
            btn.addChild(icon)
        }
        
        let titleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        let maxTitleChars = isUltraCompactMenu ? (buttonSize <= 38 ? 5 : 7) : 9
        let titleText = Self.truncatedTitle(title, maxChars: maxTitleChars)
        titleLabel.text = titleText
        let baseTitleSize = max(isUltraCompactMenu ? 6.5 : 7, subtitleFontSize - 1)
        titleLabel.fontSize = fittedMenuLabelFontSize(
            text: titleText,
            fontNamed: "Menlo-Bold",
            baseSize: baseTitleSize,
            minSize: isUltraCompactMenu ? 6.0 : 6.5,
            maxWidth: buttonSize - (isUltraCompactMenu ? 8 : 10)
        )
        titleLabel.fontColor = SKColor(white: 0.8, alpha: 1)
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: subtitleYOffset + 9)
        titleLabel.name = "titleLabel"
        btn.addChild(titleLabel)
        
        let costLabel = SKLabelNode(fontNamed: isUltraCompactMenu ? "Menlo-Bold" : "Menlo")
        costLabel.text = subtitle
        let baseSubtitleSize = isUltraCompactMenu ? max(6.2, subtitleFontSize - 0.5) : subtitleFontSize
        costLabel.fontSize = fittedMenuLabelFontSize(
            text: subtitle,
            fontNamed: isUltraCompactMenu ? "Menlo-Bold" : "Menlo",
            baseSize: baseSubtitleSize,
            minSize: isUltraCompactMenu ? 5.8 : 6.4,
            maxWidth: buttonSize - (isUltraCompactMenu ? 8 : 10)
        )
        costLabel.fontColor = isUltraCompactMenu
            ? SKColor(white: 0.86, alpha: 1)
            : SKColor(white: 0.82, alpha: 1)
        costLabel.verticalAlignmentMode = .center
        let subtitleY = isUltraCompactMenu ? (subtitleYOffset - 1.3) : (subtitleYOffset - 1)
        costLabel.position = CGPoint(x: 0, y: subtitleY)
        costLabel.name = "subtitleLabel"
        btn.addChild(costLabel)
        
        return btn
    }
    
    private static func compactCostString(_ cost: Double, ultraCompact: Bool) -> String {
        let rounded = Int(cost.rounded())
        return ultraCompact ? "\(rounded)" : "\(rounded) MTL"
    }

    private static func truncatedTitle(_ title: String, maxChars: Int) -> String {
        guard title.count > maxChars else { return title }
        guard maxChars > 1 else { return "…" }
        return String(title.prefix(maxChars - 1)) + "…"
    }

    private func fittedMenuLabelFontSize(
        text: String,
        fontNamed: String,
        baseSize: CGFloat,
        minSize: CGFloat,
        maxWidth: CGFloat
    ) -> CGFloat {
        guard maxWidth > 0 else { return baseSize }

        let probe = SKLabelNode(fontNamed: fontNamed)
        var candidate = baseSize
        let floor = min(minSize, baseSize)

        while candidate > floor {
            probe.fontSize = candidate
            probe.text = text
            if probe.frame.width <= maxWidth {
                return candidate
            }
            candidate -= 0.3
        }

        return floor
    }

    func updateAffordability(state: GameState) {
        for (i, type) in availableBuildings.enumerated() {
            guard i < buttons.count else { break }
            let canAfford = state.metal >= type.metalCost
            if i < isButtonAffordable.count {
                isButtonAffordable[i] = canAfford
            }
            let button = buttons[i]
            button.alpha = canAfford ? 1.0 : 0.5
            button.fillColor = type.color.withAlphaComponent(canAfford ? 0.24 : 0.1)
            
            if let subtitle = button.childNode(withName: "subtitleLabel") as? SKLabelNode {
                subtitle.fontColor = canAfford
                    ? (isUltraCompactMenu
                        ? SKColor(white: 0.86, alpha: 1)
                        : SKColor(white: 0.82, alpha: 1))
                    : SKColor(red: 0.92, green: 0.6, blue: 0.6, alpha: 1)
            }

            if let title = button.childNode(withName: "titleLabel") as? SKLabelNode {
                title.fontColor = canAfford
                    ? SKColor(white: 0.8, alpha: 1)
                    : SKColor(red: 0.86, green: 0.54, blue: 0.54, alpha: 1)
            }

            if let icon = button.childNode(withName: "iconSprite") as? SKSpriteNode {
                icon.alpha = canAfford ? 1.0 : 0.5
            }

            if let texture = button.childNode(withName: "textureBg") as? SKSpriteNode {
                texture.alpha = canAfford ? 0.40 : 0.25
            }

            // Selected item keeps emphasis, but reflects affordability state.
            if selectedIndex == i {
                if canAfford {
                    button.strokeColor = SKColor(red: 0.45, green: 0.82, blue: 1.0, alpha: 1)
                    button.lineWidth = isUltraCompactMenu ? 1.7 : 2
                } else {
                    button.strokeColor = SKColor(red: 0.74, green: 0.50, blue: 0.50, alpha: 1)
                    button.lineWidth = isUltraCompactMenu ? 1.2 : 1.4
                }
            } else {
                resetButtonStyle(at: i)
            }
        }
    }
}
