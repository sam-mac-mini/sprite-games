import Foundation

/// Persistent progression state — survives across loops
/// Saved to UserDefaults as JSON
final class MetaState: Codable {
    
    /// Knowledge Points available to spend
    var knowledgePoints: Int = 0
    /// Total KP earned across all loops (never decreases)
    var totalKnowledgeEarned: Int = 0
    /// IDs of unlocked tech nodes
    var unlockedTechIDs: Set<String> = []
    /// Total loops completed
    var totalLoops: Int = 0
    /// Best single-loop KP score
    var bestLoopScore: Int = 0
    /// Resources at end of last loop (for Loop Echo tech)
    var lastLoopEndResources: LoopResources?
    
    struct LoopResources: Codable {
        var metal: Double
        var energy: Double
        var biomass: Double
        var research: Double
    }
    
    // MARK: - Queries
    
    func isUnlocked(_ techID: String) -> Bool {
        unlockedTechIDs.contains(techID)
    }
    
    func canAfford(_ node: TechNode) -> Bool {
        knowledgePoints >= node.cost
    }
    
    func meetsPrerequisites(_ node: TechNode) -> Bool {
        node.prerequisites.allSatisfy { unlockedTechIDs.contains($0) }
    }
    
    func canPurchase(_ node: TechNode) -> Bool {
        !isUnlocked(node.id) && canAfford(node) && meetsPrerequisites(node)
    }
    
    /// State of a node for UI display
    func nodeState(_ node: TechNode) -> TechNodeState {
        if isUnlocked(node.id) { return .unlocked }
        if !meetsPrerequisites(node) { return .locked }
        if canAfford(node) { return .affordable }
        return .tooExpensive
    }
    
    // MARK: - Mutations
    
    @discardableResult
    func purchase(_ node: TechNode) -> Bool {
        guard canPurchase(node) else { return false }
        knowledgePoints -= node.cost
        unlockedTechIDs.insert(node.id)
        save()
        return true
    }
    
    func awardKnowledge(_ amount: Int) {
        let effectiveAmount: Int
        if isUnlocked("RES-07") {
            effectiveAmount = Int(Double(amount) * 1.3) // Knowledge Amplifier: +30%
        } else {
            effectiveAmount = amount
        }
        knowledgePoints += effectiveAmount
        totalKnowledgeEarned += effectiveAmount
        bestLoopScore = max(bestLoopScore, effectiveAmount)
        totalLoops += 1
        save()
    }
    
    func saveLastLoopResources(metal: Double, energy: Double, biomass: Double, research: Double) {
        lastLoopEndResources = LoopResources(metal: metal, energy: energy, biomass: biomass, research: research)
        save()
    }
    
    // MARK: - Persistence
    
    private static let storageKey = "ChronoColony_MetaState"
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
    
    static func load() -> MetaState {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let state = try? JSONDecoder().decode(MetaState.self, from: data)
        else { return MetaState() }
        return state
    }
    
    static func reset() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

/// Visual state for tech tree UI
enum TechNodeState {
    case unlocked       // Purchased — green
    case affordable     // Can buy now — white/bright
    case tooExpensive   // Prerequisites met but not enough KP — dim
    case locked         // Prerequisites not met — dark/grayed
}
