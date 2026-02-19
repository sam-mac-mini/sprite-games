import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    private var gameView: SKView!
    private var hasPresented = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // Create SKView as the full view
        gameView = SKView(frame: view.bounds)
        gameView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(gameView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasPresented, gameView.bounds.width > 0, gameView.bounds.height > 0 else { return }
        hasPresented = true
        
        let bounds = gameView.bounds
        let safeInsets = view.safeAreaInsets
        NSLog("📐 SKView bounds: \(bounds) safeArea: \(safeInsets)")
        
        // Create scene matching the view bounds
        let scene = GameScene(size: bounds.size)
        scene.scaleMode = .resizeFill
        
        // Tell scene where the actual safe areas are
        scene.safeTop = safeInsets.top
        scene.safeBottom = safeInsets.bottom
        
        gameView.presentScene(scene)
        gameView.ignoresSiblingOrder = true
        
        #if DEBUG
        gameView.showsFPS = true
        gameView.showsNodeCount = true
        #endif
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
