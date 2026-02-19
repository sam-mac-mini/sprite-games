import Foundation

/// Severity level affects when events can appear
enum EventSeverity: Int, Comparable {
    case minor = 0      // Can appear anytime
    case moderate = 1   // Appears after 2:00
    case severe = 2     // Escalation phase only
    
    static func < (lhs: EventSeverity, rhs: EventSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// What an event choice does to the game state
struct EventEffect {
    var metalChange: Double = 0
    var energyChange: Double = 0
    var biomassChange: Double = 0
    var researchChange: Double = 0
    var stabilityChange: Double = 0
    var colonistChange: Int = 0
    /// Destroy N random buildings
    var destroyBuildings: Int = 0
    /// Disable random buildings for this many seconds
    var disableDuration: TimeInterval = 0
    
    static let none = EventEffect()
}

/// A single choice the player can make
struct EventChoice {
    let label: String
    let description: String
    let effect: EventEffect
}

/// An event template — instantiated from the deck
struct GameEvent: Identifiable {
    let id: String
    let title: String
    let description: String
    let severity: EventSeverity
    let choices: [EventChoice]  // Always exactly 2
    /// Minimum elapsed time (seconds) before this event can fire
    let minTime: TimeInterval
    /// If true, only appears during escalation
    let escalationOnly: Bool
}

/// The event deck — shuffled pool of events drawn during a loop
final class EventDeck {
    private var drawPile: [GameEvent] = []
    private var discardPile: [GameEvent] = []
    
    /// All event templates
    private static let allEvents: [GameEvent] = [
        // === MINOR EVENTS (anytime) ===
        GameEvent(
            id: "supply_pod",
            title: "Supply Pod Detected",
            description: "Long-range scanners found a supply pod in the debris field. Retrieval will cost energy.",
            severity: .minor,
            choices: [
                EventChoice(
                    label: "Retrieve It",
                    description: "Spend 15 Energy → Gain 30 Metal",
                    effect: EventEffect(metalChange: 30, energyChange: -15)
                ),
                EventChoice(
                    label: "Ignore It",
                    description: "Save energy, lose nothing",
                    effect: .none
                )
            ],
            minTime: 30,
            escalationOnly: false
        ),
        GameEvent(
            id: "wandering_colonists",
            title: "Wandering Survivors",
            description: "A group of survivors spotted your colony. Taking them in means more mouths to feed.",
            severity: .minor,
            choices: [
                EventChoice(
                    label: "Welcome Them",
                    description: "+2 Colonists, -10 Biomass",
                    effect: EventEffect(biomassChange: -10, colonistChange: 2)
                ),
                EventChoice(
                    label: "Turn Away",
                    description: "No change, -5 Stability (morale hit)",
                    effect: EventEffect(stabilityChange: -5)
                )
            ],
            minTime: 60,
            escalationOnly: false
        ),
        GameEvent(
            id: "solar_flare_minor",
            title: "Minor Solar Flare",
            description: "A small solar flare is inbound. Your solar arrays could capture extra energy — or be damaged.",
            severity: .minor,
            choices: [
                EventChoice(
                    label: "Overclock Arrays",
                    description: "+20 Energy, -5 Stability (risk)",
                    effect: EventEffect(energyChange: 20, stabilityChange: -5)
                ),
                EventChoice(
                    label: "Shield Systems",
                    description: "-10 Metal for shielding, no damage",
                    effect: EventEffect(metalChange: -10)
                )
            ],
            minTime: 45,
            escalationOnly: false
        ),
        GameEvent(
            id: "research_breakthrough",
            title: "Research Anomaly",
            description: "An anomalous signal is boosting research instruments. Push harder or play it safe?",
            severity: .minor,
            choices: [
                EventChoice(
                    label: "Push Instruments",
                    description: "+15 Research, -10 Energy",
                    effect: EventEffect(energyChange: -10, researchChange: 15)
                ),
                EventChoice(
                    label: "Log & Continue",
                    description: "+5 Research, no risk",
                    effect: EventEffect(researchChange: 5)
                )
            ],
            minTime: 90,
            escalationOnly: false
        ),
        
        // === MODERATE EVENTS (after 2:00) ===
        GameEvent(
            id: "meteor_shower",
            title: "Meteor Shower Incoming",
            description: "Debris is raining down. Reinforce structures or brace for impact.",
            severity: .moderate,
            choices: [
                EventChoice(
                    label: "Reinforce",
                    description: "-25 Metal, no damage",
                    effect: EventEffect(metalChange: -25)
                ),
                EventChoice(
                    label: "Brace",
                    description: "1 random building destroyed, -10 Stability",
                    effect: EventEffect(stabilityChange: -10, destroyBuildings: 1)
                )
            ],
            minTime: 120,
            escalationOnly: false
        ),
        GameEvent(
            id: "colonist_sickness",
            title: "Colony Sickness",
            description: "A virus is spreading. Quarantine costs biomass. Ignoring it risks losing workers.",
            severity: .moderate,
            choices: [
                EventChoice(
                    label: "Quarantine",
                    description: "-20 Biomass, colony safe",
                    effect: EventEffect(biomassChange: -20)
                ),
                EventChoice(
                    label: "Risk It",
                    description: "50% chance: nothing happens or -1 Colonist, -8 Stability",
                    effect: EventEffect(stabilityChange: -8, colonistChange: -1)
                )
            ],
            minTime: 150,
            escalationOnly: false
        ),
        GameEvent(
            id: "power_surge",
            title: "Power Grid Surge",
            description: "Unstable energy flow detected. Vent excess or risk cascade failure.",
            severity: .moderate,
            choices: [
                EventChoice(
                    label: "Controlled Vent",
                    description: "-15 Energy, +5 Stability",
                    effect: EventEffect(energyChange: -15, stabilityChange: 5)
                ),
                EventChoice(
                    label: "Absorb It",
                    description: "+25 Energy, -12 Stability",
                    effect: EventEffect(energyChange: 25, stabilityChange: -12)
                )
            ],
            minTime: 120,
            escalationOnly: false
        ),
        
        // === SEVERE EVENTS (escalation only) ===
        GameEvent(
            id: "core_breach",
            title: "⚠ Core Breach",
            description: "Stellar core is fracturing. Massive energy required to stabilize or accept heavy losses.",
            severity: .severe,
            choices: [
                EventChoice(
                    label: "Emergency Power",
                    description: "-40 Energy, -20 Metal → Stabilize (+15 Stability)",
                    effect: EventEffect(metalChange: -20, energyChange: -40, stabilityChange: 15)
                ),
                EventChoice(
                    label: "Accept Losses",
                    description: "2 buildings destroyed, -20 Stability",
                    effect: EventEffect(stabilityChange: -20, destroyBuildings: 2)
                )
            ],
            minTime: 480,
            escalationOnly: true
        ),
        GameEvent(
            id: "gravitational_collapse",
            title: "⚠ Gravitational Anomaly",
            description: "Spacetime distortion pulling structures apart. Sacrifice resources or lose infrastructure.",
            severity: .severe,
            choices: [
                EventChoice(
                    label: "Counter-Pulse",
                    description: "-30 Energy, -15 Research → Save colony",
                    effect: EventEffect(energyChange: -30, researchChange: -15)
                ),
                EventChoice(
                    label: "Hunker Down",
                    description: "1 building destroyed, -1 Colonist, -15 Stability",
                    effect: EventEffect(stabilityChange: -15, colonistChange: -1, destroyBuildings: 1)
                )
            ],
            minTime: 500,
            escalationOnly: true
        ),
        GameEvent(
            id: "last_stand",
            title: "⚠ Final Warning",
            description: "The star is dying. Pour everything into survival or accept the end gracefully.",
            severity: .severe,
            choices: [
                EventChoice(
                    label: "All-In",
                    description: "-30 Metal, -30 Energy, -20 Biomass → +25 Stability",
                    effect: EventEffect(metalChange: -30, energyChange: -30, biomassChange: -20, stabilityChange: 25)
                ),
                EventChoice(
                    label: "Graceful End",
                    description: "+20 Research (data collection), -15 Stability",
                    effect: EventEffect(researchChange: 20, stabilityChange: -15)
                )
            ],
            minTime: 540,
            escalationOnly: true
        )
    ]
    
    // MARK: - Deck Management
    
    /// Shuffle and prepare the deck for a new loop
    func shuffle(rng: inout SeededRandomGenerator) {
        drawPile = Self.allEvents.shuffled(using: &rng)
        discardPile = []
    }
    
    /// Draw the next eligible event for the current game state
    func draw(state: GameState) -> GameEvent? {
        // Find first eligible event in draw pile
        for (index, event) in drawPile.enumerated() {
            if isEligible(event: event, state: state) {
                let drawn = drawPile.remove(at: index)
                discardPile.append(drawn)
                return drawn
            }
        }
        
        // If draw pile exhausted, reshuffle discard
        if drawPile.isEmpty && !discardPile.isEmpty {
            drawPile = discardPile
            discardPile = []
            // Don't reshuffle with RNG (would desync determinism) — just reverse
            drawPile.reverse()
            
            // Try again
            for (index, event) in drawPile.enumerated() {
                if isEligible(event: event, state: state) {
                    let drawn = drawPile.remove(at: index)
                    discardPile.append(drawn)
                    return drawn
                }
            }
        }
        
        return nil
    }
    
    private func isEligible(event: GameEvent, state: GameState) -> Bool {
        if state.elapsedTime < event.minTime { return false }
        if event.escalationOnly && state.phase != .escalation { return false }
        return true
    }
    
    /// How many events remain in draw pile
    var remaining: Int { drawPile.count }
}
