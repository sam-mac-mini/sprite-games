import SpriteKit

/// Centralized sound playback — keeps sound actions cached
final class SoundManager {
    static let shared = SoundManager()
    
    // Pre-built sound actions for performance
    let build = SKAction.playSoundFileNamed("build.caf", waitForCompletion: false)
    let demolish = SKAction.playSoundFileNamed("demolish.caf", waitForCompletion: false)
    let tap = SKAction.playSoundFileNamed("tap.caf", waitForCompletion: false)
    let event = SKAction.playSoundFileNamed("event.caf", waitForCompletion: false)
    let choice = SKAction.playSoundFileNamed("choice.caf", waitForCompletion: false)
    let warning = SKAction.playSoundFileNamed("warning.caf", waitForCompletion: false)
    let collapse = SKAction.playSoundFileNamed("collapse.caf", waitForCompletion: false)
    let assign = SKAction.playSoundFileNamed("assign.caf", waitForCompletion: false)
    let escalation = SKAction.playSoundFileNamed("escalation.caf", waitForCompletion: false)
    let newloop = SKAction.playSoundFileNamed("newloop.caf", waitForCompletion: false)
    
    private init() {}
}
