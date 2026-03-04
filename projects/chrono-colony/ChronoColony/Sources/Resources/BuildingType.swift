import Foundation
import SpriteKit

/// All building types available in the game
enum BuildingType: String, CaseIterable, Identifiable {
    case metalExtractor = "Metal Extractor"
    case farm = "Farm"
    case solarArray = "Solar Array"
    case researchLab = "Research Lab"
    // Tech tree unlocks
    case storageDepot = "Storage Depot"
    case medicalBay = "Medical Bay"
    case shieldGenerator = "Shield Generator"
    case cloneVats = "Clone Vats"
    case temporalRift = "Temporal Rift"
    case megaStructure = "Mega-Structure"
    
    var id: String { rawValue }
    
    // MARK: - Construction Cost
    /// Tech ID required to unlock this building (nil = always available)
    var requiredTechID: String? {
        switch self {
        case .storageDepot: return "INF-03"
        case .medicalBay: return "COL-04"
        case .shieldGenerator: return "RES-05"
        case .cloneVats: return "COL-07"
        case .temporalRift: return "TMP-05"
        case .megaStructure: return "INF-07"
        default: return nil
        }
    }
    
    /// Starter buildings always available
    static var starterBuildings: [BuildingType] {
        [.metalExtractor, .farm, .solarArray, .researchLab]
    }
    
    var metalCost: Double {
        switch self {
        case .metalExtractor: return 40
        case .farm: return 30
        case .solarArray: return 60
        case .researchLab: return 50
        case .storageDepot: return 45
        case .medicalBay: return 55
        case .shieldGenerator: return 70
        case .cloneVats: return 80
        case .temporalRift: return 90
        case .megaStructure: return 120
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
        case .storageDepot:
            return ResourceBundle(metal: 0, energy: 0, biomass: 0, research: 0)
        case .medicalBay:
            return ResourceBundle(metal: 0, energy: 0, biomass: 0, research: 0)
        case .shieldGenerator:
            return ResourceBundle(metal: 0, energy: 0, biomass: 0, research: 0)
        case .cloneVats:
            return ResourceBundle(metal: 0, energy: 0, biomass: 0, research: 0)
        case .temporalRift:
            return ResourceBundle(metal: 2, energy: 3, biomass: 1, research: 2)
        case .megaStructure:
            return ResourceBundle(metal: 5, energy: 6, biomass: 3, research: 3)
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
        case .storageDepot:
            return ResourceBundle(metal: 0, energy: 0, biomass: 0, research: 0)
        case .medicalBay:
            return ResourceBundle(metal: 0, energy: 1.5, biomass: 0.5, research: 0)
        case .shieldGenerator:
            return ResourceBundle(metal: 0, energy: 3, biomass: 0, research: 0)
        case .cloneVats:
            return ResourceBundle(metal: 0, energy: 2, biomass: 2, research: 0)
        case .temporalRift:
            return ResourceBundle(metal: 0, energy: 0, biomass: 0, research: 0) // Drains stability instead
        case .megaStructure:
            return ResourceBundle(metal: 0, energy: 4, biomass: 2, research: 0)
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
        case .storageDepot: return SKColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1)
        case .medicalBay: return SKColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1)
        case .shieldGenerator: return SKColor(red: 0.3, green: 0.8, blue: 0.8, alpha: 1)
        case .cloneVats: return SKColor(red: 0.7, green: 0.3, blue: 0.7, alpha: 1)
        case .temporalRift: return SKColor(red: 0.5, green: 0.3, blue: 0.8, alpha: 1)
        case .megaStructure: return SKColor(red: 0.8, green: 0.7, blue: 0.3, alpha: 1)
        }
    }
    
    var symbol: String {
        switch self {
        case .metalExtractor: return "⛏"
        case .farm: return "🌱"
        case .solarArray: return "☀"
        case .researchLab: return "🔬"
        case .storageDepot: return "📦"
        case .medicalBay: return "🏥"
        case .shieldGenerator: return "🛡"
        case .cloneVats: return "🧬"
        case .temporalRift: return "🌀"
        case .megaStructure: return "🏛"
        }
    }

    /// Compact menu title to preserve readability on small control cards.
    var menuTitle: String {
        switch self {
        case .metalExtractor: return "EXTRACT"
        case .farm: return "FARM"
        case .solarArray: return "SOLAR"
        case .researchLab: return "LAB"
        case .storageDepot: return "DEPOT"
        case .medicalBay: return "MED BAY"
        case .shieldGenerator: return "SHIELD"
        case .cloneVats: return "CLONE"
        case .temporalRift: return "RIFT"
        case .megaStructure: return "MEGA"
        }
    }
    
    /// Asset catalog image name for this building
    var imageName: String {
        switch self {
        case .metalExtractor: return "metalExtractor"
        case .farm: return "farm"
        case .solarArray: return "solarArray"
        case .researchLab: return "researchLab"
        // Tech-unlocked buildings use Kenney structures
        case .storageDepot: return "storageDepot"
        case .medicalBay: return "medicalBay"
        case .shieldGenerator: return "shieldGenerator"
        case .cloneVats: return "cloneVats"
        case .temporalRift: return "temporalRift"
        case .megaStructure: return "megaStructure"
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
