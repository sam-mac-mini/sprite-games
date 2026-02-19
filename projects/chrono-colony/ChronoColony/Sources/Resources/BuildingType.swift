import Foundation
import SpriteKit

/// All building types available in the game
enum BuildingType: String, CaseIterable, Identifiable {
    case metalExtractor = "Metal Extractor"
    case farm = "Farm"
    case solarArray = "Solar Array"
    case researchLab = "Research Lab"
    
    var id: String { rawValue }
    
    // MARK: - Construction Cost
    var metalCost: Double {
        switch self {
        case .metalExtractor: return 40
        case .farm: return 30
        case .solarArray: return 60
        case .researchLab: return 50
        }
    }
    
    // MARK: - Production per tick (with 1 colonist assigned)
    var production: ResourceBundle {
        switch self {
        case .metalExtractor:
            return ResourceBundle(metal: 3, energy: 0, biomass: 0, research: 0)
        case .farm:
            return ResourceBundle(metal: 0, energy: 0, biomass: 2, research: 0)
        case .solarArray:
            return ResourceBundle(metal: 0, energy: 4, biomass: 0, research: 0)
        case .researchLab:
            return ResourceBundle(metal: 0, energy: 0, biomass: 0, research: 2)
        }
    }
    
    // MARK: - Consumption per tick
    var consumption: ResourceBundle {
        switch self {
        case .metalExtractor:
            return ResourceBundle(metal: 0, energy: 1, biomass: 0, research: 0)
        case .farm:
            return ResourceBundle(metal: 0, energy: 0.5, biomass: 0, research: 0)
        case .solarArray:
            return ResourceBundle(metal: 0, energy: 0, biomass: 0, research: 0)
        case .researchLab:
            return ResourceBundle(metal: 0, energy: 2, biomass: 0.5, research: 0)
        }
    }
    
    // MARK: - Workers
    var maxWorkers: Int { 2 }
    
    /// Second worker efficiency (diminishing returns)
    var secondWorkerEfficiency: Double { 0.6 }
    
    // MARK: - Demolish refund (partial)
    var demolishRefund: Double { metalCost * 0.5 }
    
    // MARK: - Placeholder visual
    var color: SKColor {
        switch self {
        case .metalExtractor: return SKColor(red: 0.6, green: 0.6, blue: 0.7, alpha: 1)
        case .farm: return SKColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1)
        case .solarArray: return SKColor(red: 0.9, green: 0.8, blue: 0.2, alpha: 1)
        case .researchLab: return SKColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1)
        }
    }
    
    var symbol: String {
        switch self {
        case .metalExtractor: return "⛏"
        case .farm: return "🌱"
        case .solarArray: return "☀"
        case .researchLab: return "🔬"
        }
    }
    
    /// Asset catalog image name for this building
    var imageName: String {
        switch self {
        case .metalExtractor: return "metalExtractor"
        case .farm: return "farm"
        case .solarArray: return "solarArray"
        case .researchLab: return "researchLab"
        }
    }
}

/// A bundle of resource amounts (used for production/consumption)
struct ResourceBundle {
    let metal: Double
    let energy: Double
    let biomass: Double
    let research: Double
    
    static let zero = ResourceBundle(metal: 0, energy: 0, biomass: 0, research: 0)
}
