import Foundation

/// Reads unlocked techs and applies their effects to gameplay
/// Called at loop start and during simulation
struct TechEffects {
    let meta: MetaState
    
    // MARK: - Starting Conditions
    
    /// Number of colonists at loop start
    var startingColonists: Int {
        meta.isUnlocked("COL-01") ? 7 : GameConstants.startingColonists
    }
    
    /// Starting metal
    var startingMetal: Double {
        GameConstants.startingMetal
    }
    
    /// Starting resources from Loop Echo (TMP-03)
    var loopEchoResources: MetaState.LoopResources? {
        guard meta.isUnlocked("TMP-03"), let last = meta.lastLoopEndResources else { return nil }
        return MetaState.LoopResources(
            metal: last.metal * 0.2,
            energy: last.energy * 0.2,
            biomass: last.biomass * 0.2,
            research: last.research * 0.2
        )
    }
    
    /// Loop duration in seconds
    var loopDuration: TimeInterval {
        meta.isUnlocked("TMP-06") ? 720 : GameConstants.loopDuration // 12 min vs 10 min
    }
    
    /// Escalation start time (scales proportionally if loop is extended)
    var escalationStart: TimeInterval {
        meta.isUnlocked("TMP-06") ? 576 : GameConstants.escalationStart // 80% of loop
    }
    
    // MARK: - Building Effects
    
    /// Demolish refund multiplier
    var demolishRefundMultiplier: Double {
        meta.isUnlocked("INF-02") ? 0.75 : 0.5
    }
    
    /// Production multiplier for a building type
    func productionMultiplier(for type: BuildingType) -> Double {
        var mult = 1.0
        switch type {
        case .metalExtractor:
            if meta.isUnlocked("INF-04") { mult += 0.25 }
        case .farm:
            if meta.isUnlocked("INF-05") { mult += 0.25 }
        case .researchLab:
            if meta.isUnlocked("RES-01") { mult += 0.25 }
        case .solarArray, .storageDepot, .medicalBay, .shieldGenerator, .cloneVats:
            break
        }
        return mult
    }
    
    /// Second worker efficiency
    var secondWorkerEfficiency: Double {
        meta.isUnlocked("COL-02") ? 0.8 : 0.6
    }
    
    /// Max workers per building
    var maxWorkersPerBuilding: Int {
        meta.isUnlocked("COL-06") ? 3 : 2
    }
    
    /// Third worker efficiency (if Leadership unlocked)
    var thirdWorkerEfficiency: Double { 0.4 }
    
    /// Unstaffed building production rate (Automation Protocol)
    var automationRate: Double {
        meta.isUnlocked("COL-03") ? 0.3 : 0.0
    }
    
    /// Colonist biomass consumption multiplier
    var colonistFoodMultiplier: Double {
        meta.isUnlocked("COL-05") ? 0.7 : 1.0
    }
    
    // MARK: - Escalation Effects
    
    /// Buildings survive extra hits before destruction
    var buildingHitPoints: Int {
        meta.isUnlocked("INF-01") ? 2 : 1
    }
    
    /// Minimum stability (Paradox Shield)
    func minimumStability(elapsedTime: TimeInterval) -> Double {
        if meta.isUnlocked("TMP-04") && elapsedTime < 300 {
            return 20
        }
        return 0
    }
    
    // MARK: - Event Effects
    
    /// Can dismiss events
    var canDismissEvents: Bool {
        meta.isUnlocked("RES-04")
    }
    
    /// Event dismiss stability cost
    var eventDismissCost: Double { 5 }
    
    // MARK: - Anomaly
    
    /// Anomaly adjacency multiplier bonus
    var anomalyBonusMultiplier: Double {
        meta.isUnlocked("RES-03") ? 2.0 : 1.0 // doubles the base +75%
    }
    
    // MARK: - Temporal
    
    /// First building is free (Echo Memory)
    var firstBuildingFree: Bool {
        meta.isUnlocked("TMP-01")
    }
    
    /// Time dilation available
    var timeDilationAvailable: Bool {
        meta.isUnlocked("TMP-02")
    }
    
    /// Time rewind available
    var timeRewindAvailable: Bool {
        meta.isUnlocked("TMP-07")
    }
}
