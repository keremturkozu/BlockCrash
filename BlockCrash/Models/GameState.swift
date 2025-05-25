import Foundation
import Combine

class GameState: ObservableObject {
    static let gridSize = 8
    
    @Published var score: Int = 0
    @Published var gameOver: Bool = false {
        didSet {
            if oldValue != gameOver {
                print("🎯 GameState: gameOver: \(oldValue) → \(gameOver)")
            }
        }
    }
    @Published var grid: [[BlockColor?]] = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)
    @Published var nextShapes: [BlockShape] = []
    
    private let shapesPerTurn = 3
    
    init() {
        resetGame()
    }
    
    func resetGame() {
        print("🎯 GameState: resetGame() called")
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
    
    func place(shape: BlockShape, at origin: GridPosition) -> (placed: Bool, clearedRows: [Int], clearedColumns: [Int], scoreGained: Int) {
        guard canPlace(shape: shape, at: origin) else { return (false, [], [], 0) }
        for pos in shape.positions {
            let row = origin.row + pos.row
            let column = origin.column + pos.column
            grid[row][column] = shape.color
        }
        removeNextShape(shape)
        let (clearedRows, clearedColumns) = clearCompletedLines()
        let gained = (clearedRows.count + clearedColumns.count) * 100
        if nextShapes.isEmpty { generateNextShapes() }
        if !canPlaceAnyShape() { gameOver = true }
        return (true, clearedRows, clearedColumns, gained)
    }
    
    func removeNextShape(_ shape: BlockShape) {
        if let idx = nextShapes.firstIndex(where: { $0.id == shape.id }) {
            nextShapes.remove(at: idx)
        }
    }
    
    func clearCompletedLines() -> ([Int], [Int]) {
        var clearedRows: [Int] = []
        var clearedColumns: [Int] = []
        // Satırları kontrol et
        for row in 0..<Self.gridSize {
            if grid[row].allSatisfy({ $0 != nil }) {
                for column in 0..<Self.gridSize { grid[row][column] = nil }
                clearedRows.append(row)
            }
        }
        // Sütunları kontrol et
        for column in 0..<Self.gridSize {
            if (0..<Self.gridSize).allSatisfy({ grid[$0][column] != nil }) {
                for row in 0..<Self.gridSize { grid[row][column] = nil }
                clearedColumns.append(column)
            }
        }
        let gained = (clearedRows.count + clearedColumns.count) * 100
        score += gained
        return (clearedRows, clearedColumns)
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
