import Foundation
import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var gameState = GameState()
    @Published var isNewGame = true {
        didSet {
            print("🎮 GameViewModel: isNewGame changed from \(oldValue) to \(isNewGame)")
        }
    }
    @Published var highscore: Int = UserDefaults.standard.integer(forKey: "highscore")
    @Published var showingContinueAd = false // Continue reklam durumunu takip et
    
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
        print("🎮 GameViewModel: isNewGame before continue: \(isNewGame)")
        
        // Game Over durumunu kaldır ve oyunu devam ettir
        objectWillChange.send() // SwiftUI'ya değişiklik bildir
        gameState.gameOver = false
        
        // isNewGame durumunu korumaya dikkat et - değiştirme!
        // isNewGame zaten false olmalı, değişmemeli
        
        // Continue bonusları:
        // 1. Yeni shape'ler üret
        gameState.generateNextShapes()
        print("🎮 GameViewModel: Generated fresh shapes for continue")
        
        // 2. Tahtanın alt yarısını temizle (oyuncuya avantaj sağla)
        clearBottomHalfOfBoard()
        print("🎮 GameViewModel: Cleared bottom half of board for continue bonus")
        
        print("🎮 GameViewModel: Game continued, gameOver = \(gameState.gameOver)")
        print("🎮 GameViewModel: isNewGame after continue: \(isNewGame)")
    }
    
    private func clearBottomHalfOfBoard() {
        let gridSize = GameState.gridSize
        let startRow = gridSize / 2 // Alt yarıdan başla (satır 4'ten itibaren)
        
        for row in startRow..<gridSize {
            for column in 0..<gridSize {
                gameState.grid[row][column] = nil
            }
        }
        print("🎮 GameViewModel: Cleared rows \(startRow) to \(gridSize-1)")
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
