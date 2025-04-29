import Foundation
import Combine

class GameState: ObservableObject {
    static let gridSize = 8
    
    @Published var score: Int = 0
    @Published var gameOver: Bool = false
    @Published var grid: [[BlockColor?]] = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)
    @Published var nextShapes: [BlockShape] = []
    
    private let shapesPerTurn = 3
    
    init() {
        resetGame()
    }
    
    func resetGame() {
        score = 0
        gameOver = false
        grid = Array(repeating: Array(repeating: nil, count: Self.gridSize), count: Self.gridSize)
        generateNextShapes()
    }
    
    func generateNextShapes() {
        nextShapes = (0..<shapesPerTurn).map { _ in BlockShape.random() }
    }
    
    func canPlace(shape: BlockShape, at origin: GridPosition) -> Bool {
        for pos in shape.positions {
            let row = origin.row + pos.row
            let column = origin.column + pos.column
            if row < 0 || row >= Self.gridSize || column < 0 || column >= Self.gridSize {
                return false
            }
            if grid[row][column] != nil {
                return false
            }
        }
        return true
    }
    
    func place(shape: BlockShape, at origin: GridPosition) -> Bool {
        guard canPlace(shape: shape, at: origin) else { return false }
        for pos in shape.positions {
            let row = origin.row + pos.row
            let column = origin.column + pos.column
            grid[row][column] = shape.color
        }
        removeNextShape(shape)
        clearCompletedLines()
        if nextShapes.isEmpty { generateNextShapes() }
        if !canPlaceAnyShape() { gameOver = true }
        return true
    }
    
    func removeNextShape(_ shape: BlockShape) {
        if let idx = nextShapes.firstIndex(where: { $0.id == shape.id }) {
            nextShapes.remove(at: idx)
        }
    }
    
    func clearCompletedLines() {
        var cleared = 0
        // Satırları kontrol et
        for row in 0..<Self.gridSize {
            if grid[row].allSatisfy({ $0 != nil }) {
                for column in 0..<Self.gridSize { grid[row][column] = nil }
                cleared += 1
            }
        }
        // Sütunları kontrol et
        for column in 0..<Self.gridSize {
            if (0..<Self.gridSize).allSatisfy({ grid[$0][column] != nil }) {
                for row in 0..<Self.gridSize { grid[row][column] = nil }
                cleared += 1
            }
        }
        score += cleared * 100
    }
    
    func canPlaceAnyShape() -> Bool {
        for shape in nextShapes {
            for row in 0..<Self.gridSize {
                for column in 0..<Self.gridSize {
                    if canPlace(shape: shape, at: GridPosition(row: row, column: column)) {
                        return true
                    }
                }
            }
        }
        return false
    }
} 
