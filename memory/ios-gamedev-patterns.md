# iOS Game Dev Patterns — Research Notes
> Sources: Hacking with Swift (Paul Hudson), Kodeco, Apple docs
> Compiled: 2026-02-18

## Performance & Optimization

### Cache Physics Bodies
Calculate pixel-perfect collision shapes once, then `.copy()` for instances:
```swift
let rockTexture = SKTexture(imageNamed: "rock")
var rockPhysics: SKPhysicsBody!

// Calculate once in didMove(to:)
rockPhysics = SKPhysicsBody(texture: rockTexture, size: rockTexture.size())

// Reuse via copying
topRock.physicsBody = rockPhysics.copy() as? SKPhysicsBody
```

### Preload Particle Effects
Create instances as properties even if unused initially — forces SpriteKit to preload textures:
```swift
let explosion = SKEmitterNode(fileNamed: "PlayerExplosion") // Forces preload
```

### Physics Body Cost Hierarchy
```swift
// Rectangle (cheapest)
sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)

// Circle (cheap)
sprite.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)

// Pixel-perfect (expensive, use sparingly)
sprite.physicsBody = SKPhysicsBody(texture: texture, size: texture.size())
```

### Physics Optimization Tips
- `usesPreciseCollisionDetection = true` only for small, fast-moving objects (bullets)
- `linearDamping = 0` and `angularDamping = 0` for frictionless space environments
- `isDynamic = false` for static collision objects — prevents unnecessary physics calculations

## Collision Detection

### Contact vs Collision Philosophy
- `contactTestBitMask`: Notifications only (detect touch for scoring/triggers)
- `collisionBitMask`: Physical bounce/response
- Pattern: Set contact for scoring, disable collision to prevent momentum loss:
```swift
player.physicsBody?.contactTestBitMask = player.physicsBody!.collisionBitMask
player.physicsBody?.collisionBitMask = 0 // No bounce, just detect
```

### Collision Delegate — Sort by Category
Always sort by bitmask to eliminate duplicate checks:
```swift
func didBegin(_ contact: SKPhysicsContact) {
    let firstBody: SKPhysicsBody
    let secondBody: SKPhysicsBody
    
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
        firstBody = contact.bodyA
        secondBody = contact.bodyB
    } else {
        firstBody = contact.bodyB
        secondBody = contact.bodyA
    }
    
    guard let firstNode = firstBody.node else { return }
    guard let secondNode = secondBody.node else { return }
    // Now check in predictable order
}
```

### Prevent Double-Collision Bugs
```swift
banana.name = "" // Clear name after first hit — didBegin() won't trigger again
```

### Guard for Destroyed Nodes
```swift
guard contact.bodyA.node != nil && contact.bodyB.node != nil else { return }
```

## Visual Effects & Animation

### Parallax Scrolling
```swift
let moveLeft = SKAction.moveBy(x: -texture.size().width, y: 0, duration: 20)
let moveReset = SKAction.moveBy(x: texture.size().width, y: 0, duration: 0)
let moveLoop = SKAction.sequence([moveLeft, moveReset])
background.run(SKAction.repeatForever(moveLoop))
```
- Faster movement = closer layer (ground: 5s, mountains: 20s, sky: static)
- Use zPosition for depth (-40, -30, -10, etc.)

### Dynamic Sprite Recoloring (Zero-Cost GPU)
```swift
sprite.color = .red
sprite.colorBlendFactor = 1 // 0=original, 1=full recolor
```

### Path-Based Movement
```swift
let path = UIBezierPath()
path.move(to: .zero)
path.addLine(to: CGPoint(x: xMovement, y: 1000))
let move = SKAction.follow(path.cgPath, asOffset: true, orientToPath: true, speed: 200)
node.run(move)
```
- `asOffset: true` = relative to node position
- `orientToPath: true` = auto-rotate to face travel direction

### Rotation from Velocity (natural tilt)
```swift
override func update(_ currentTime: TimeInterval) {
    let value = player.physicsBody!.velocity.dy * 0.001
    let rotate = SKAction.rotate(toAngle: value, duration: 0.1)
    player.run(rotate)
}
```

## Destructible Terrain
```swift
func hit(at point: CGPoint) {
    let convertedPoint = CGPoint(
        x: point.x + size.width / 2.0,
        y: abs(point.y - (size.height / 2.0))
    )
    let renderer = UIGraphicsImageRenderer(size: size)
    let img = renderer.image { ctx in
        currentImage.draw(at: .zero)
        ctx.cgContext.addEllipse(in: CGRect(x: convertedPoint.x - 32, 
            y: convertedPoint.y - 32, width: 64, height: 64))
        ctx.cgContext.setBlendMode(.clear)
        ctx.cgContext.drawPath(using: .fill)
    }
    texture = SKTexture(image: img)
    currentImage = img
    configurePhysics() // Recalculate physics shape
}
```

## Architecture Patterns

### Scene Transitions
```swift
let newGame = GameScene(size: self.size)
let transition = SKTransition.doorway(withDuration: 1.5)
self.view?.presentScene(newGame, transition: transition)
```

### UIKit + SpriteKit Communication
```swift
// In scene:
weak var viewController: GameViewController!
// In view controller:
var currentGame: GameScene!
```

### Property Observers for UI Updates
```swift
var score = 0 {
    didSet { scoreLabel.text = "Score: \(score)" }
}
```

### Sound Throttling
```swift
var isSwooshSoundActive = false

func playSwooshSound() {
    isSwooshSoundActive = true
    let swooshSound = SKAction.playSoundFileNamed("swoosh.wav", waitForCompletion: true)
    run(swooshSound) { [weak self] in
        self?.isSwooshSoundActive = false
    }
}
```

### Physics Impulse — Reset Velocity First
```swift
player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 20))
```

### Game Over via Scene Speed
```swift
speed = 0 // Halts all actions on scene and children
```

## Common Pitfalls

1. **Anchor points matter** — default (0.5, 0.5) is center. Use (0.5, 1) for top-center stacking, .zero for scrolling math
2. **Node cleanup** — remove offscreen nodes in update() to prevent memory bloat
3. **iPad simulator is extremely slow for games** — always test on device
4. **Enable physics debug**: `view.showsPhysics = true` during development
5. **Blend modes**: `.replace` for backgrounds (fastest), `.clear` for cutouts
6. **Named nodes > tag systems**: `sprite.name = "enemy"` is cleaner

## Kodeco Patterns (from general knowledge)

### Physics Bitmask Setup
- `categoryBitMask` — what this node IS
- `contactTestBitMask` — what triggers contact notifications
- `collisionBitMask` — what physically bounces off this node

### Node Hierarchy Optimization
- Use bare `SKNode` as organizational containers (no rendering cost)
- Use `SKSpriteNode` only when you need to display something
- Fewer draw calls = better frame rate

### SKAction Chaining vs Update Loop
- **SKActions**: fire-and-forget animations, timed sequences, visual effects
- **Update loop**: continuous game logic, AI decisions, input processing
- Don't fight the framework — use both where each is strongest

---

## Apple Sample Projects

### DemoBots (SpriteKit + GameplayKit) — THE Blueprint
Apple's flagship game sample. Production-grade 2D game architecture.

**Entity-Component-System (ECS)**:
```swift
class PlayerBot: GKEntity {
    // Components added in init:
    // - RenderComponent (visual representation)
    // - PhysicsComponent (collision & physics)
    // - AnimationComponent (sprite animations)
    // - MovementComponent (2D movement)
    // - IntelligenceComponent (state machine)
    // - InputComponent (player input)
    // - ChargeComponent (health/energy)
}
```
Key principle: **Component composition > inheritance**. Build entities from reusable components.

**State Machine Pattern**:
```swift
IntelligenceComponent(states: [
    PlayerBotAppearState,
    PlayerBotPlayerControlledState,
    PlayerBotHitState,
    PlayerBotRechargingState
])
```

**Async Resource Loading Protocol**:
```swift
protocol ResourceLoadableType {
    static var resourcesNeedLoading: Bool { get }
    static func loadResources(withCompletionHandler: () -> ())
    static func purgeResources()
}
```

Also demonstrates: agent-based AI (`GKAgent2D`), .sks scene files, Metal shader integration, cross-platform (iOS/macOS/tvOS).

### Fox (SceneKit 3D Game)
- Metal vs OpenGL ES renderer selection
- Positional audio triggers
- Light maps via material properties
- Game controller support

### FourInARow (GameplayKit AI)
- `GKMinmaxStrategist` for AI opponents
- `GKGameModel` protocol for game state representation
- Turn-based game architecture

### MetalShaderShowcase
- 7 unique Metal shaders (Phong, wood, fog, cel, normal map, particle system)
- Metal reflection API for dynamic shader parameter discovery
- `MTKTextureLoader` for asset loading

### Key Architecture Takeaways from Apple Samples
1. **Use GameplayKit ECS** for anything beyond a trivial prototype
2. **Component composition > inheritance** — reusable components
3. **State machines** for character behavior management
4. **Xcode Scene Editor (.sks files)** is the official way to design levels
5. **Async resource loading** is built in from the start
6. **Cross-platform** is first-class (shared code, platform-specific UI layers)

---

## Apple Official Docs & WWDC Sessions

### SpriteKit Advanced Patterns

**SKRenderer** — use instead of `SKView` when you need manual control over update/render timing. Enables fixed time steps, update-without-render, render-without-update. Critical for Metal integration.

**SpriteKit + SceneKit mixing** — set `SKScene` as `diffuse.contents` on `SCNGeometry` material for 2D sprites in 3D scenes. Use `SKTransformNode` for x/y/z rotation.

**SpriteKit + Metal** — render SpriteKit to Metal texture via `SKRenderer` for custom pipelines.

### Metal Performance (when we need it)

**Fast Math — ALWAYS enable** unless you need NaN/Inf handling:
- `-ffast-math` flag → typical 15-21% frame time reduction
- No reason not to use it for games

**Register Pressure Management**:
- Split complex shaders into focused variants (25-84% register reduction)
- Use `half` types to halve register consumption vs `float`
- Fewer registers → more parallel threads → better occupancy
- Symptom: ALU limiter + low occupancy = register pressure

**Texture Optimization Hierarchy**:
1. 16-bit half-precision formats when possible
2. Single-channel alpha over RGBA for masks
3. Block compression (ASTC/BC) for read-only textures
4. Lossy compression (A15+) for quality-preserving memory savings

**Memoryless textures** — `MTLStorageModeMemoryless` for single-pass targets (depth/stencil/MSAA). Free memory savings.

**Redundant Binding Elimination** — cache bound resources, compare before re-binding. Use `setFragmentTextures(_:range:)` for batch binding. Impact: 30-50% encoding time reduction.

### Memory Profiling Workflow

**Tools Hierarchy** (in order of use):
1. Xcode Memory Gauge — first-look footprint
2. Instruments Game Memory Template — allocation density spikes, Metal resource events
3. Memory Graph Analysis — enable `MallocStackLogging`, use `footprint`, `vmmap`, `heap --sortBySize`

**Key metric**: Footprint = dirty + compressed + swapped. Unified memory means CPU + GPU objects both count.

**Metal Debugger Memory Viewer** — sort by "Time Since Last Bound" to find unused resources. Set purgeable state to `.volatile` for infrequent assets.

### Multi-frame Rendering (Apple Silicon)

Ring buffer pattern for frame overlap:
```swift
let maxFrames = 3
let sharedBufferCount = device.hasUnifiedMemory ? maxFrames + 1 : maxFrames
let privateBufferCount = device.hasUnifiedMemory ? 0 : 1
```
Extra buffer eliminates CPU-GPU wait time. Gains: 1-2ms from vertex/fragment overlap.

### Cross-Platform (Game Porting Toolkit 2, 2024)
- Single project: macOS + iOS with `#if os(iOS)` / `#if os(macOS)`
- Unified Metal shaders compile once, deploy everywhere
- Game Mode on iOS 18: `GCSupportsGameMode = true` in Info.plist

### First 30 Minutes Profiling Checklist
1. Capture GPU frame → check Summary page insights
2. Group by Pipeline State → audit top 3 most expensive shaders
3. Memory Viewer → sort by Allocated Size + Time Since Last Bound
4. Metal System Trace → look for vertex/fragment/compute gaps
5. Verify Fast Math enabled, lossless compression on, no redundant bindings

### Real-World Wins (Apple Arcade)
- 33% frame time improvement (Baldur's Gate 3)
- 21% from Fast Math alone (Metro Exodus)
- 1-8ms shader optimizations from register pressure fixes
- 30-50% encoding time cuts from binding elimination

---

## Reference Projects (Hacking with Swift)
| Project | Technique |
|---------|-----------|
| 11 (Pachinko) | Basic SpriteKit, physics, collision |
| 14 (Whack-a-Penguin) | SKCropNode, texture swapping |
| 17 (Space Race) | Per-pixel collision, Timer, damping |
| 20 (Fireworks) | Particle systems, UIBezierPath, color blend |
| 23 (Swifty Ninja) | SKShapeNode, touch tracking |
| 26 (Marble Maze) | Core Motion, accelerometer physics, level loading |
| 29 (Exploding Monkeys) | UIKit + SpriteKit, destructible terrain |
| 36 (Crashy Plane) | Parallax scrolling, optimization |
