import Foundation
import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var gameState = GameState()
    @Published var isNewGame = true
    
    // Forward game properties for easy access from views
    var score: Int { gameState.score }
    var gameOver: Bool { gameState.gameOver }
    var nextShapes: [BlockShape] { gameState.nextShapes }
    
    private var cancellables = Set<AnyCancellable>()
    
    func startNewGame() {
        gameState.resetGame()
        isNewGame = false
    }
    
    func resetGame() {
        gameState.resetGame()
        isNewGame = true
    }
    
    func placeShape(_ shape: BlockShape, at position: GridPosition) -> Bool {
        let placed = gameState.place(shape: shape, at: position)
        return placed
    }
    
    func canPlaceShape(_ shape: BlockShape, at position: GridPosition) -> Bool {
        gameState.canPlace(shape: shape, at: position)
    }
} 