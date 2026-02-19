import Foundation

/// The current phase of a loop
enum GamePhase: Equatable {
    case landing        // 0:00 — initial placement
    case expansion      // 0:00 - 8:00 — build and grow
    case escalation     // 8:00 - 10:00 — stellar instability ramps
    case collapse       // 10:00 — colony destroyed, award knowledge
    case summary        // Post-collapse results screen
}

/// Deterministic RNG using a seed for reproducible runs
struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

/// Central game state — owned by GameScene, read by all systems
final class GameState: ObservableObject {
    // MARK: - Loop
    var phase: GamePhase = .landing
    var elapsedTime: TimeInterval = 0
    var seed: UInt64
    var rng: SeededRandomGenerator
    
    // MARK: - Resources
    var metal: Double = GameConstants.startingMetal
    var energy: Double = GameConstants.startingEnergy
    var biomass: Double = GameConstants.startingBiomass
    var research: Double = GameConstants.startingResearch
    var stability: Double = GameConstants.startingStability
    
    // MARK: - Colonists
    var totalColonists: Int = GameConstants.startingColonists
    var assignedColonists: Int = 0
    var availableColonists: Int { totalColonists - assignedColonists }
    
    // MARK: - Timer
    var remainingTime: TimeInterval {
        max(0, GameConstants.loopDuration - elapsedTime)
    }
    
    var remainingTimeFormatted: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Clone Vats
    var cloneVatAccumulator: Double = 0
    
    // MARK: - Resource Deltas (per tick, for UI display)
    var metalDelta: Double = 0
    var energyDelta: Double = 0
    var biomassDelta: Double = 0
    var researchDelta: Double = 0
    var stabilityDelta: Double = 0
    
    // MARK: - Init
    init(seed: UInt64 = UInt64.random(in: 0...UInt64.max)) {
        self.seed = seed
        self.rng = SeededRandomGenerator(seed: seed)
    }
    
    func reset() {
        phase = .landing
        elapsedTime = 0
        rng = SeededRandomGenerator(seed: seed)
        metal = GameConstants.startingMetal
        energy = GameConstants.startingEnergy
        biomass = GameConstants.startingBiomass
        research = GameConstants.startingResearch
        stability = GameConstants.startingStability
        totalColonists = GameConstants.startingColonists
        assignedColonists = 0
        metalDelta = 0
        energyDelta = 0
        biomassDelta = 0
        researchDelta = 0
        stabilityDelta = 0
    }
}
