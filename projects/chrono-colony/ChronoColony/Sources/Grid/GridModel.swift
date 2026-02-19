import Foundation

/// Represents what's on a single tile
enum TileContent: Equatable {
    case empty
    case building(BuildingType)
    case resourceDeposit(ResourceDepositType)
    case blocked // impassable terrain
}

/// Natural resource deposits on the map
enum ResourceDepositType: Equatable {
    case metalVein    // Boosts adjacent Metal Extractor output
    case biomassZone  // Boosts adjacent Farm output
    case anomaly      // Special interaction point (future)
}

/// A single tile in the grid
struct Tile {
    let col: Int
    let row: Int
    var content: TileContent = .empty
    var assignedWorkers: Int = 0
    var isActive: Bool { // Building with at least 1 worker
        if case .building = content, assignedWorkers > 0 { return true }
        return false
    }
    
    var buildingType: BuildingType? {
        if case .building(let type) = content { return type }
        return nil
    }
}

/// The grid model — source of truth for tile state
final class GridModel {
    let columns: Int
    let rows: Int
    private(set) var tiles: [[Tile]]
    
    init(columns: Int = GameConstants.gridColumns, rows: Int = GameConstants.gridRows) {
        self.columns = columns
        self.rows = rows
        self.tiles = (0..<rows).map { row in
            (0..<columns).map { col in
                Tile(col: col, row: row)
            }
        }
    }
    
    // MARK: - Access
    
    func tile(at col: Int, row: Int) -> Tile? {
        guard col >= 0, col < columns, row >= 0, row < rows else { return nil }
        return tiles[row][col]
    }
    
    // MARK: - Building Placement
    
    func canPlace(building: BuildingType, at col: Int, row: Int, state: GameState) -> Bool {
        guard let tile = tile(at: col, row: row) else { return false }
        guard tile.content == .empty else { return false }
        guard state.metal >= building.metalCost else { return false }
        return true
    }
    
    @discardableResult
    func placeBuilding(_ type: BuildingType, at col: Int, row: Int, state: GameState) -> Bool {
        guard canPlace(building: type, at: col, row: row, state: state) else { return false }
        tiles[row][col].content = .building(type)
        state.metal -= type.metalCost
        return true
    }
    
    func demolishBuilding(at col: Int, row: Int, state: GameState) {
        guard let tile = tile(at: col, row: row),
              let buildingType = tile.buildingType else { return }
        state.metal += buildingType.demolishRefund
        state.assignedColonists -= tile.assignedWorkers
        tiles[row][col].content = .empty
        tiles[row][col].assignedWorkers = 0
    }
    
    // MARK: - Worker Assignment
    
    @discardableResult
    func assignWorker(at col: Int, row: Int, state: GameState) -> Bool {
        guard tiles[row][col].buildingType != nil else { return false }
        guard state.availableColonists > 0 else { return false }
        guard tiles[row][col].assignedWorkers < 1 else { return false } // 1 worker max for now
        tiles[row][col].assignedWorkers += 1
        state.assignedColonists += 1
        return true
    }
    
    @discardableResult
    func removeWorker(at col: Int, row: Int, state: GameState) -> Bool {
        guard tiles[row][col].assignedWorkers > 0 else { return false }
        tiles[row][col].assignedWorkers -= 1
        state.assignedColonists -= 1
        return true
    }
    
    // MARK: - Queries
    
    func allBuildings() -> [(col: Int, row: Int, tile: Tile)] {
        var result: [(Int, Int, Tile)] = []
        for row in 0..<rows {
            for col in 0..<columns {
                if tiles[row][col].buildingType != nil {
                    result.append((col, row, tiles[row][col]))
                }
            }
        }
        return result
    }
    
    // MARK: - Map Generation
    
    func generateMap(rng: inout SeededRandomGenerator) {
        // Reset all tiles
        for row in 0..<rows {
            for col in 0..<columns {
                tiles[row][col].content = .empty
            }
        }
        
        // Place 2-3 metal veins
        let metalCount = Int.random(in: 2...3, using: &rng)
        placeDeposits(.metalVein, count: metalCount, rng: &rng)
        
        // Place 2-3 biomass zones
        let biomassCount = Int.random(in: 2...3, using: &rng)
        placeDeposits(.biomassZone, count: biomassCount, rng: &rng)
        
        // Place 1 anomaly
        placeDeposits(.anomaly, count: 1, rng: &rng)
    }
    
    private func placeDeposits(_ type: ResourceDepositType, count: Int, rng: inout SeededRandomGenerator) {
        var placed = 0
        var attempts = 0
        while placed < count && attempts < 50 {
            let col = Int.random(in: 0..<columns, using: &rng)
            let row = Int.random(in: 0..<rows, using: &rng)
            if tiles[row][col].content == .empty {
                tiles[row][col].content = .resourceDeposit(type)
                placed += 1
            }
            attempts += 1
        }
    }
    
    func reset(rng: inout SeededRandomGenerator) {
        generateMap(rng: &rng)
    }
}
