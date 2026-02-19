import Foundation

/// Processes resource production/consumption each tick
final class ResourceSystem {
    
    /// Run one simulation tick — called every `simulationTickRate` seconds
    func tick(grid: GridModel, state: GameState) {
        var metalDelta: Double = 0
        var energyDelta: Double = 0
        var biomassDelta: Double = 0
        var researchDelta: Double = 0
        
        // Process all active buildings
        for (_, _, tile) in grid.allBuildings() {
            guard tile.isActive, let buildingType = tile.buildingType else { continue }
            
            let workers = Double(tile.assignedWorkers)
            let prod = buildingType.production
            let cons = buildingType.consumption
            
            // Production scaled by worker count
            metalDelta += prod.metal * workers
            energyDelta += prod.energy * workers
            biomassDelta += prod.biomass * workers
            researchDelta += prod.research * workers
            
            // Consumption (always costs, even partial)
            metalDelta -= cons.metal
            energyDelta -= cons.energy
            biomassDelta -= cons.biomass
            researchDelta -= cons.research
        }
        
        // Colonist biomass consumption (0.5 per colonist per tick)
        let colonistBiomassCost = Double(state.totalColonists) * 0.5
        biomassDelta -= colonistBiomassCost
        
        // Apply deltas
        state.metal = max(0, state.metal + metalDelta)
        state.energy = max(0, state.energy + energyDelta)
        state.biomass = max(0, state.biomass + biomassDelta)
        state.research = max(0, state.research + researchDelta)
        
        // Store deltas for UI display
        state.metalDelta = metalDelta
        state.energyDelta = energyDelta
        state.biomassDelta = biomassDelta - colonistBiomassCost // Show net
        state.researchDelta = researchDelta
        
        // Stability effects
        updateStability(state: state)
    }
    
    private func updateStability(state: GameState) {
        var stabilityDelta: Double = 0
        
        // Energy deficit causes stability decay
        if state.energy <= 0 {
            stabilityDelta -= GameConstants.stabilityDecayPerSecondNoEnergy
        }
        
        // Biomass deficit (starvation) causes faster stability decay
        if state.biomass <= 0 {
            stabilityDelta -= 1.0
        }
        
        // Natural stability recovery when resources are healthy
        if state.energy > 10 && state.biomass > 10 && state.stability < GameConstants.maxStability {
            stabilityDelta += 0.2
        }
        
        // Escalation stability drain handled by EscalationSystem
        
        state.stability = min(GameConstants.maxStability, max(0, state.stability + stabilityDelta))
        state.stabilityDelta = stabilityDelta
    }
}
