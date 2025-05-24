import Foundation
import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var gameState = GameState()
    @Published var isNewGame = true
    @Published var highscore: Int = UserDefaults.standard.integer(forKey: "highscore")
    
    // Forward game properties for easy access from views
    var score: Int { gameState.score }
    var gameOver: Bool { gameState.gameOver }
    var nextShapes: [BlockShape] { gameState.nextShapes }
    
    private var cancellables = Set<AnyCancellable>()
    
    func startNewGame() {
        updateHighscoreIfNeeded()
        gameState.resetGame()
        isNewGame = false
    }
    
    func resetGame() {
        updateHighscoreIfNeeded()
        gameState.resetGame()
        isNewGame = true
    }
    
    func continueGame() {
        print("🎮 GameViewModel: continueGame() called")
        // Game Over durumunu kaldır ve oyunu devam ettir
        objectWillChange.send() // SwiftUI'ya değişiklik bildir
        gameState.gameOver = false
        // Skor ve grid durumu korunur
        print("🎮 GameViewModel: Game continued, gameOver = \(gameState.gameOver)")
        
        // Eğer hiç shape yoksa yeni shape'ler üret
        if gameState.nextShapes.isEmpty {
            gameState.generateNextShapes()
            print("🎮 GameViewModel: Generated new shapes for continue")
        }
    }
    
    func placeShape(_ shape: BlockShape, at position: GridPosition) -> Bool {
        let result = gameState.place(shape: shape, at: position)
        return result.placed
    }
    
    func canPlaceShape(_ shape: BlockShape, at position: GridPosition) -> Bool {
        gameState.canPlace(shape: shape, at: position)
    }
    
    private func updateHighscoreIfNeeded() {
        if gameState.score > highscore {
            highscore = gameState.score
            UserDefaults.standard.set(highscore, forKey: "highscore")
        }
    }
} 
