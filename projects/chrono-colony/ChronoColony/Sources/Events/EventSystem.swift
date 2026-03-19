import Foundation

/// Manages event timing and application
final class EventSystem {
    
    private let deck = EventDeck()
    
    /// Time until next event fires
    private var nextEventTimer: TimeInterval = 0
    /// Time accumulator
    private var accumulator: TimeInterval = 0
    /// Whether an event is currently being displayed (pauses timer)
    var isShowingEvent: Bool = false
    /// The currently displayed event (if any)
    var currentEvent: GameEvent?
    
    // MARK: - Timing Constants
    
    /// Base interval between events during expansion (seconds)
    private let expansionInterval: TimeInterval = 70
    /// Base interval during escalation (faster)
    private let escalationInterval: TimeInterval = 40
    /// Random variance ± seconds
    private let intervalVariance: TimeInterval = 15
    /// Minimum time before first event
    private let firstEventDelay: TimeInterval = 30
    
    // MARK: - Setup
    
    func setup(rng: inout SeededRandomGenerator) {
        deck.shuffle(rng: &rng)
        accumulator = 0
        isShowingEvent = false
        currentEvent = nil
        // First event comes a bit early to hook the player
        nextEventTimer = firstEventDelay
    }
    
    // MARK: - Tick
    
    /// Set of event IDs blocked by Medical Bay
    private let sicknessEventIDs: Set<String> = ["colonist_sickness"]
    
    /// Whether the colony has an active Medical Bay
    var hasMedicalBay: Bool = false
    
    /// Whether the Event Scanner tech is unlocked (RES-02)
    var hasEventScanner: Bool = false
    
    /// Preview of the next event (visible when scanner is active and event is within 30s)
    private(set) var upcomingEventPreview: String?
    
    /// Call every frame with delta time. Returns an event if one should be shown.
    func update(dt: TimeInterval, state: GameState, rng: inout SeededRandomGenerator) -> GameEvent? {
        guard !isShowingEvent else { return nil }
        guard state.phase == .expansion || state.phase == .escalation else { return nil }
        
        accumulator += dt
        
        // Event Scanner: show preview when within 30s of next event
        if hasEventScanner && !isShowingEvent {
            let timeUntilEvent = nextEventTimer - accumulator
            if timeUntilEvent <= 30 && timeUntilEvent > 0 {
                upcomingEventPreview = "EVENT INCOMING IN \(Int(timeUntilEvent))s"
            } else {
                upcomingEventPreview = nil
            }
        } else {
            upcomingEventPreview = nil
        }
        
        if accumulator >= nextEventTimer {
            accumulator = 0
            scheduleNextEvent(state: state, rng: &rng)
            
            if var event = deck.draw(state: state) {
                // Medical Bay blocks sickness events
                if hasMedicalBay && sicknessEventIDs.contains(event.id) {
                    // Skip — draw next event instead (or none)
                    if let replacement = deck.draw(state: state) {
                        event = replacement
                    } else {
                        return nil
                    }
                }
                currentEvent = event
                isShowingEvent = true
                return event
            }
        }
        
        return nil
    }
    
    /// Player made a choice — apply effects and dismiss
    func resolveChoice(choiceIndex: Int, grid: GridModel, state: GameState, rng: inout SeededRandomGenerator) {
        guard let event = currentEvent, choiceIndex < event.choices.count else { return }
        let effect = event.choices[choiceIndex].effect
        
        // Apply resource changes (clamped to 0)
        state.metal = max(0, state.metal + effect.metalChange)
        state.energy = max(0, state.energy + effect.energyChange)
        state.biomass = max(0, state.biomass + effect.biomassChange)
        state.research = max(0, state.research + effect.researchChange)
        state.stability = min(GameConstants.maxStability, max(0, state.stability + effect.stabilityChange))
        
        // Colonist changes
        if effect.colonistChange != 0 {
            state.totalColonists = max(1, state.totalColonists + effect.colonistChange)
            // If we lost colonists, unassign from random buildings
            if effect.colonistChange < 0 {
                let excess = state.assignedColonists - state.totalColonists
                if excess > 0 {
                    unassignRandom(count: excess, grid: grid, state: state, rng: &rng)
                }
            }
        }
        
        // Destroy random buildings
        if effect.destroyBuildings > 0 {
            destroyRandomBuildings(count: effect.destroyBuildings, grid: grid, state: state, rng: &rng)
        }
        
        // Clear
        currentEvent = nil
        isShowingEvent = false
    }
    
    // MARK: - Helpers
    
    private func scheduleNextEvent(state: GameState, rng: inout SeededRandomGenerator) {
        let base = state.phase == .escalation ? escalationInterval : expansionInterval
        let variance = Double.random(in: -intervalVariance...intervalVariance, using: &rng)
        nextEventTimer = max(20, base + variance)
    }
    
    private func destroyRandomBuildings(count: Int, grid: GridModel, state: GameState, rng: inout SeededRandomGenerator) {
        var buildings = grid.allBuildings()
        guard !buildings.isEmpty else { return }
        
        buildings.shuffle(using: &rng)
        let toDestroy = min(count, buildings.count)
        
        for i in 0..<toDestroy {
            let (col, row, _) = buildings[i]
            grid.demolishBuilding(at: col, row: row, state: state)
            // Note: demolishBuilding gives refund — for event destruction we take it back
            // Actually, event destruction should NOT give refund
            if let type = buildings[i].tile.buildingType {
                state.metal = max(0, state.metal - type.demolishRefund)
            }
        }
    }
    
    private func unassignRandom(count: Int, grid: GridModel, state: GameState, rng: inout SeededRandomGenerator) {
        var buildings = grid.allBuildings().filter { $0.tile.assignedWorkers > 0 }
        buildings.shuffle(using: &rng)
        
        var remaining = count
        for (col, row, _) in buildings {
            if remaining <= 0 { break }
            grid.removeWorker(at: col, row: row, state: state)
            remaining -= 1
        }
    }
}
