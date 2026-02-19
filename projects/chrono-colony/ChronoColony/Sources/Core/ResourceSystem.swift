import Foundation

/// Processes resource production/consumption each tick
final class ResourceSystem {
    
    /// Run one simulation tick — called every `simulationTickRate` seconds
    func tick(grid: GridModel, state: GameState, techEffects: TechEffects? = nil) {
        var metalDelta: Double = 0
        var energyDelta: Double = 0
        var biomassDelta: Double = 0
        var researchDelta: Double = 0
        
        // Process all active buildings
        for (col, row, tile) in grid.allBuildings() {
            guard tile.isActive, let buildingType = tile.buildingType else { continue }
            
            let workerCount = tile.assignedWorkers
            let prod = buildingType.production
            let cons = buildingType.consumption
            let adjacencyMult = grid.adjacencyMultiplier(col: col, row: row)
            let techProdMult = techEffects?.productionMultiplier(for: buildingType) ?? 1.0
            
            // Worker efficiency: first = 1.0x, second = diminishing, optional third
            let secondEff = techEffects?.secondWorkerEfficiency ?? buildingType.secondWorkerEfficiency
            let workerMult: Double
            if workerCount >= 3 {
                let thirdEff = techEffects?.thirdWorkerEfficiency ?? 0.4
                workerMult = 1.0 + secondEff + thirdEff
            } else if workerCount >= 2 {
                workerMult = 1.0 + secondEff
            } else if workerCount >= 1 {
                workerMult = 1.0
            } else {
                // Automation Protocol: unstaffed production
                workerMult = techEffects?.automationRate ?? 0.0
            }
            
            // Production scaled by worker efficiency, adjacency, AND tech bonuses
            metalDelta += prod.metal * workerMult * adjacencyMult * techProdMult
            energyDelta += prod.energy * workerMult * adjacencyMult * techProdMult
            biomassDelta += prod.biomass * workerMult * adjacencyMult * techProdMult
            researchDelta += prod.research * workerMult * adjacencyMult * techProdMult
            
            // Consumption (always costs, NOT affected by adjacency)
            metalDelta -= cons.metal
            energyDelta -= cons.energy
            biomassDelta -= cons.biomass
            researchDelta -= cons.research
        }
        
        // Storage Depot: passive stability regeneration when staffed (+0.3/s per worker)
        for (_, _, tile) in grid.allBuildings() {
            guard tile.isActive, tile.buildingType == .storageDepot, tile.assignedWorkers > 0 else { continue }
            state.stability = min(GameConstants.maxStability, state.stability + 0.3 * Double(tile.assignedWorkers))
        }
        
        // Clone Vats: produce colonists (1 every 30 ticks = 30 seconds when staffed)
        for (_, _, tile) in grid.allBuildings() {
            guard tile.isActive, tile.buildingType == .cloneVats, tile.assignedWorkers > 0 else { continue }
            state.cloneVatAccumulator += Double(tile.assignedWorkers) * 0.033 // ~1 colonist per 30s per worker
            if state.cloneVatAccumulator >= 1.0 {
                state.cloneVatAccumulator -= 1.0
                state.totalColonists += 1
            }
        }
        
        // Colonist biomass consumption (0.5 per colonist per tick, reduced by tech)
        let foodMult = techEffects?.colonistFoodMultiplier ?? 1.0
        let colonistBiomassCost = Double(state.totalColonists) * 0.5 * foodMult
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
    
    /// Enforce Paradox Shield minimum (call after all stability changes including escalation)
    func enforceParadoxShield(state: GameState, techEffects: TechEffects?) {
        guard let effects = techEffects else { return }
        let minStab = effects.minimumStability(elapsedTime: state.elapsedTime)
        if state.stability < minStab {
            state.stability = minStab
        }
    }
}
