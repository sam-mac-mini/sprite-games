import SpriteKit

/// Manages escalation phase effects — visual + mechanical pressure from 8:00-10:00
final class EscalationSystem {
    
    // MARK: - Escalation Mechanics
    
    /// Intensity ramps from 0.0 at 8:00 to 1.0 at 10:00
    func intensity(state: GameState) -> Double {
        guard state.phase == .escalation else { return 0 }
        let escalationDuration = GameConstants.loopDuration - GameConstants.escalationStart
        let elapsed = state.elapsedTime - GameConstants.escalationStart
        return min(1.0, max(0, elapsed / escalationDuration))
    }
    
    /// Apply escalation effects each simulation tick
    func tick(grid: GridModel, state: GameState, rng: inout SeededRandomGenerator) {
        guard state.phase == .escalation else { return }
        let power = intensity(state: state)
        
        // 1. Accelerating stability decay (0.3 base → up to 1.5 at max)
        let stabilityDrain = 0.3 + power * 1.2
        state.stability = max(0, state.stability - stabilityDrain)
        
        // 2. Random resource drain — grows with intensity
        let drainAmount = power * 3.0
        switch Int.random(in: 0..<4, using: &rng) {
        case 0: state.metal = max(0, state.metal - drainAmount)
        case 1: state.energy = max(0, state.energy - drainAmount)
        case 2: state.biomass = max(0, state.biomass - drainAmount)
        default: break // Research is spared (reward for investing)
        }
        
        // 3. Random building damage — chance increases with intensity
        //    At intensity 0.5+, ~5% chance per tick to damage a building
        //    Shield Generators protect buildings in 3x3 area (halves damage chance)
        if power > 0.4 {
            let damageChance = (power - 0.4) * 0.08
            let roll = Double.random(in: 0..<1, using: &rng)
            if roll < damageChance {
                let buildings = grid.allBuildings()
                if !buildings.isEmpty {
                    let target = buildings[Int.random(in: 0..<buildings.count, using: &rng)]
                    // Shield Generator protection — 50% chance to block
                    if isShielded(col: target.col, row: target.row, grid: grid) {
                        let shieldRoll = Double.random(in: 0..<1, using: &rng)
                        if shieldRoll < 0.5 { /* shielded — skip damage */ }
                        else if target.tile.assignedWorkers > 0 {
                            grid.removeWorker(at: target.col, row: target.row, state: state)
                        }
                    } else if target.tile.assignedWorkers > 0 {
                        grid.removeWorker(at: target.col, row: target.row, state: state)
                    }
                }
            }
        }
        
        // 4. At high intensity (0.8+), chance to destroy a building outright
        if power > 0.8 {
            let destroyChance = (power - 0.8) * 0.03
            let roll = Double.random(in: 0..<1, using: &rng)
            if roll < destroyChance {
                let buildings = grid.allBuildings()
                if !buildings.isEmpty {
                    let target = buildings[Int.random(in: 0..<buildings.count, using: &rng)]
                    // Shield protects from destruction too
                    if isShielded(col: target.col, row: target.row, grid: grid) {
                        let shieldRoll = Double.random(in: 0..<1, using: &rng)
                        if shieldRoll < 0.5 { /* shielded */ }
                        else {
                            grid.demolishBuilding(at: target.col, row: target.row, state: state)
                            if let type = target.tile.buildingType {
                                state.metal = max(0, state.metal - type.demolishRefund)
                            }
                        }
                    } else {
                        grid.demolishBuilding(at: target.col, row: target.row, state: state)
                        if let type = target.tile.buildingType {
                            state.metal = max(0, state.metal - type.demolishRefund)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Shield Generator
    
    /// Check if a tile is within 3x3 range of an active Shield Generator
    private func isShielded(col: Int, row: Int, grid: GridModel) -> Bool {
        for dc in -1...1 {
            for dr in -1...1 {
                let nc = col + dc
                let nr = row + dr
                if let tile = grid.tile(at: nc, row: nr),
                   tile.buildingType == .shieldGenerator,
                   tile.isActive {
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: - Visual Effects
    
    /// Returns parameters for visual escalation effects based on intensity
    func visualParams(state: GameState) -> EscalationVisuals {
        let power = intensity(state: state)
        return EscalationVisuals(
            screenTintAlpha: CGFloat(power * 0.15),
            shakeIntensity: CGFloat(power * 2.0),
            pulseSpeed: 1.0 + power * 2.0,
            warningFlashInterval: max(3.0, 8.0 - power * 6.0)
        )
    }
}

/// Visual parameters driven by escalation intensity
struct EscalationVisuals {
    let screenTintAlpha: CGFloat    // Red tint overlay (0-0.15)
    let shakeIntensity: CGFloat     // Camera micro-shake pixels
    let pulseSpeed: Double          // HUD pulse rate multiplier
    let warningFlashInterval: Double // Seconds between warning flashes
}
