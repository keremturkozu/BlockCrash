import SwiftUI
import SpriteKit

struct SpriteView: UIViewRepresentable {
    @ObservedObject var gameViewModel: GameViewModel
    
    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.preferredFramesPerSecond = 60
        view.showsFPS = false
        view.showsNodeCount = false
        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        scene.gameViewModel = gameViewModel
        view.presentScene(scene)
        return view
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        if let scene = uiView.scene as? GameScene {
            scene.gameViewModel = gameViewModel
            scene.reload()
        }
    }
} 