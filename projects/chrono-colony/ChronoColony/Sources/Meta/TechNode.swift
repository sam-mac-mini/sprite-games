import Foundation

/// Which branch a tech node belongs to
enum TechBranch: String, CaseIterable, Codable {
    case infrastructure = "Infrastructure"
    case colony = "Colony"
    case research = "Research"
    case temporal = "Temporal Physics"
    
    var symbol: String {
        switch self {
        case .infrastructure: return "🔧"
        case .colony: return "👥"
        case .research: return "🔬"
        case .temporal: return "⏳"
        }
    }
    
    var shortName: String {
        switch self {
        case .infrastructure: return "Infra"
        case .colony: return "Colony"
        case .research: return "Research"
        case .temporal: return "Temporal"
        }
    }
    
    var colorHex: UInt32 {
        switch self {
        case .infrastructure: return 0x8B7355
        case .colony: return 0x4A9E4A
        case .research: return 0x4A7BBF
        case .temporal: return 0xBF6ABF
        }
    }
}

/// A single node in the tech tree
struct TechNode: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let branch: TechBranch
    let tier: Int          // 1-3
    let cost: Int          // Knowledge Points
    let prerequisites: [String]  // IDs of required unlocks
    
    /// Whether this unlock adds a new building type
    var unlocksBuilding: Bool {
        id == "INF-03" || id == "INF-07" || id == "COL-04" || id == "COL-07" || id == "RES-05" || id == "TMP-05"
    }
}

/// Central registry of all tech nodes
enum TechTree {
    
    static let allNodes: [TechNode] = infrastructure + colony + research + temporal
    
    static let nodeMap: [String: TechNode] = {
        Dictionary(uniqueKeysWithValues: allNodes.map { ($0.id, $0) })
    }()
    
    // MARK: - Infrastructure Branch
    
    static let infrastructure: [TechNode] = [
        TechNode(
            id: "INF-01", name: "Reinforced Foundations",
            description: "Buildings survive 2 escalation hits before destruction",
            branch: .infrastructure, tier: 1, cost: 15, prerequisites: []
        ),
        TechNode(
            id: "INF-02", name: "Recycling Protocol",
            description: "Demolish refund increased to 75%",
            branch: .infrastructure, tier: 1, cost: 20, prerequisites: []
        ),
        TechNode(
            id: "INF-03", name: "Storage Depot",
            description: "Unlock new building: stores excess resources",
            branch: .infrastructure, tier: 2, cost: 30, prerequisites: ["INF-01"]
        ),
        TechNode(
            id: "INF-04", name: "Advanced Drill Bits",
            description: "Metal Extractors produce +25%",
            branch: .infrastructure, tier: 2, cost: 35, prerequisites: ["INF-01"]
        ),
        TechNode(
            id: "INF-05", name: "Hydroponic Systems",
            description: "Farms produce +25%",
            branch: .infrastructure, tier: 2, cost: 35, prerequisites: ["INF-02"]
        ),
        TechNode(
            id: "INF-06", name: "Power Grid",
            description: "Solar Arrays reduce adjacent building energy consumption by 30%",
            branch: .infrastructure, tier: 3, cost: 50, prerequisites: ["INF-04", "INF-05"]
        ),
        TechNode(
            id: "INF-07", name: "Mega-Structure",
            description: "Unlock massive building: huge output, occupies 2x2",
            branch: .infrastructure, tier: 3, cost: 60, prerequisites: ["INF-06"]
        ),
    ]
    
    // MARK: - Colony Branch
    
    static let colony: [TechNode] = [
        TechNode(
            id: "COL-01", name: "Recruitment Drive",
            description: "Start each loop with 7 colonists (was 5)",
            branch: .colony, tier: 1, cost: 15, prerequisites: []
        ),
        TechNode(
            id: "COL-02", name: "Training Program",
            description: "Second worker efficiency: 80% (was 60%)",
            branch: .colony, tier: 1, cost: 20, prerequisites: []
        ),
        TechNode(
            id: "COL-03", name: "Automation Protocol",
            description: "Unstaffed buildings produce at 30% capacity",
            branch: .colony, tier: 2, cost: 30, prerequisites: ["COL-01"]
        ),
        TechNode(
            id: "COL-04", name: "Medical Bay",
            description: "Unlock new building: prevents sickness events",
            branch: .colony, tier: 2, cost: 35, prerequisites: ["COL-01"]
        ),
        TechNode(
            id: "COL-05", name: "Efficient Rations",
            description: "Colonist biomass consumption reduced 30%",
            branch: .colony, tier: 2, cost: 25, prerequisites: ["COL-02"]
        ),
        TechNode(
            id: "COL-06", name: "Leadership",
            description: "Buildings can hold 3 workers (3rd at 40%)",
            branch: .colony, tier: 3, cost: 45, prerequisites: ["COL-03", "COL-05"]
        ),
        TechNode(
            id: "COL-07", name: "Clone Vats",
            description: "Unlock new building: slowly produces colonists",
            branch: .colony, tier: 3, cost: 55, prerequisites: ["COL-06"]
        ),
    ]
    
    // MARK: - Research Branch
    
    static let research: [TechNode] = [
        TechNode(
            id: "RES-01", name: "Data Mining",
            description: "Research Labs produce +25%",
            branch: .research, tier: 1, cost: 15, prerequisites: []
        ),
        TechNode(
            id: "RES-02", name: "Event Scanner",
            description: "Preview next event 30s before it fires",
            branch: .research, tier: 1, cost: 20, prerequisites: []
        ),
        TechNode(
            id: "RES-03", name: "Anomaly Resonance",
            description: "Anomaly adjacency bonus doubled",
            branch: .research, tier: 2, cost: 30, prerequisites: ["RES-01"]
        ),
        TechNode(
            id: "RES-04", name: "Emergency Protocols",
            description: "Dismiss events without choosing (costs 5 stability)",
            branch: .research, tier: 2, cost: 35, prerequisites: ["RES-02"]
        ),
        TechNode(
            id: "RES-05", name: "Shield Generator",
            description: "Unlock building: reduces escalation damage in 3x3 area",
            branch: .research, tier: 2, cost: 40, prerequisites: ["RES-01"]
        ),
        TechNode(
            id: "RES-06", name: "Advanced Sensors",
            description: "Deposit locations highlighted before building",
            branch: .research, tier: 3, cost: 45, prerequisites: ["RES-03"]
        ),
        TechNode(
            id: "RES-07", name: "Knowledge Amplifier",
            description: "+30% Knowledge Points earned per loop",
            branch: .research, tier: 3, cost: 50, prerequisites: ["RES-05"]
        ),
        TechNode(
            id: "RES-08", name: "Temporal Signature",
            description: "Unlocks the Temporal Physics branch",
            branch: .research, tier: 3, cost: 60, prerequisites: ["RES-06", "RES-07"]
        ),
    ]
    
    // MARK: - Temporal Physics Branch
    
    static let temporal: [TechNode] = [
        TechNode(
            id: "TMP-01", name: "Echo Memory",
            description: "First building placed each loop is free",
            branch: .temporal, tier: 1, cost: 40, prerequisites: ["RES-08"]
        ),
        TechNode(
            id: "TMP-02", name: "Time Dilation",
            description: "Slow time to 50% for 30s (once per loop)",
            branch: .temporal, tier: 1, cost: 45, prerequisites: ["RES-08"]
        ),
        TechNode(
            id: "TMP-03", name: "Loop Echo",
            description: "Start with 20% of previous loop's ending resources",
            branch: .temporal, tier: 2, cost: 55, prerequisites: ["TMP-01"]
        ),
        TechNode(
            id: "TMP-04", name: "Paradox Shield",
            description: "Stability can't drop below 20 for first 5 minutes",
            branch: .temporal, tier: 2, cost: 60, prerequisites: ["TMP-02"]
        ),
        TechNode(
            id: "TMP-05", name: "Temporal Rift",
            description: "Unlock building: generates all resources, drains stability",
            branch: .temporal, tier: 3, cost: 70, prerequisites: ["TMP-03"]
        ),
        TechNode(
            id: "TMP-06", name: "Chrono Mastery",
            description: "Loop extended to 12 minutes",
            branch: .temporal, tier: 3, cost: 80, prerequisites: ["TMP-04"]
        ),
        TechNode(
            id: "TMP-07", name: "Time Rewind",
            description: "Once per loop: undo last 30 seconds",
            branch: .temporal, tier: 3, cost: 100, prerequisites: ["TMP-05", "TMP-06"]
        ),
    ]
}
