import Foundation
import CoreGraphics

/// Central game constants — single source of truth for tuning
enum GameConstants {
    // MARK: - Grid
    static let gridColumns = 10
    static let gridRows = 10
    static let tileSize: CGFloat = 48.0
    
    // MARK: - Timer
    static let loopDuration: TimeInterval = 600.0 // 10 minutes
    static let escalationStart: TimeInterval = 480.0 // 8:00 mark
    static let warningStart: TimeInterval = 540.0 // 9:00 mark
    
    // MARK: - Starting Resources
    static let startingMetal: Double = 100
    static let startingEnergy: Double = 50
    static let startingBiomass: Double = 50
    static let startingResearch: Double = 0
    static let startingStability: Double = 100
    static let startingColonists: Int = 5
    
    // MARK: - Stability
    static let maxStability: Double = 100
    static let stabilityWarningThreshold: Double = 40
    static let stabilityCriticalThreshold: Double = 20
    static let stabilityDecayPerSecondNoEnergy: Double = 0.5
    
    // MARK: - Simulation
    static let simulationTickRate: TimeInterval = 1.0 // 1 tick per second
    
    // MARK: - UI
    static let buildMenuHeight: CGFloat = 120
    static let resourceBarHeight: CGFloat = 60
}
