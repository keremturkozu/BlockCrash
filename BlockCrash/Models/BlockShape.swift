import Foundation
import SwiftUI

enum BlockColor: CaseIterable {
    case red, blue, green, yellow, orange, purple
    
    var color: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        case .purple: return .purple
        }
    }
}

struct GridPosition: Hashable, Equatable {
    let row: Int
    let column: Int
}

struct BlockShape: Identifiable, Equatable {
    let id = UUID()
    let color: BlockColor
    let positions: [GridPosition] // Şeklin kendi grid'i (ör: [(0,0), (1,0), (2,0)] bir çubuk)
    let size: Int // max(width, height)
    static func == (lhs: BlockShape, rhs: BlockShape) -> Bool {
        lhs.id == rhs.id
    }
}

extension BlockShape {
    static let allShapes: [BlockShape] = [
        // Dikey çubuk (4) - 2x
        BlockShape(color: .blue, positions: [GridPosition(row:0,column:0), GridPosition(row:1,column:0), GridPosition(row:2,column:0), GridPosition(row:3,column:0)], size: 4),
        BlockShape(color: .blue, positions: [GridPosition(row:0,column:0), GridPosition(row:1,column:0), GridPosition(row:2,column:0), GridPosition(row:3,column:0)], size: 4),
        // Dikey çubuk (2)
        BlockShape(color: .red, positions: [GridPosition(row:0,column:0), GridPosition(row:1,column:0)], size: 2),
        // Yatay çubuk (4) - 2x
        BlockShape(color: .blue, positions: [GridPosition(row:0,column:0), GridPosition(row:0,column:1), GridPosition(row:0,column:2), GridPosition(row:0,column:3)], size: 4),
        BlockShape(color: .blue, positions: [GridPosition(row:0,column:0), GridPosition(row:0,column:1), GridPosition(row:0,column:2), GridPosition(row:0,column:3)], size: 4),
        // Yatay çubuk (2) - 2x
        BlockShape(color: .red, positions: [GridPosition(row:0,column:0), GridPosition(row:0,column:1)], size: 2),
        BlockShape(color: .red, positions: [GridPosition(row:0,column:0), GridPosition(row:0,column:1)], size: 2),
        // Kare (2x2) - 2x
        BlockShape(color: .yellow, positions: [GridPosition(row:0,column:0), GridPosition(row:0,column:1), GridPosition(row:1,column:0), GridPosition(row:1,column:1)], size: 2),
        BlockShape(color: .yellow, positions: [GridPosition(row:0,column:0), GridPosition(row:0,column:1), GridPosition(row:1,column:0), GridPosition(row:1,column:1)], size: 2),
        // Kare (3x3) - 2x
        BlockShape(color: .green, positions: [
            GridPosition(row:0,column:0), GridPosition(row:0,column:1), GridPosition(row:0,column:2),
            GridPosition(row:1,column:0), GridPosition(row:1,column:1), GridPosition(row:1,column:2),
            GridPosition(row:2,column:0), GridPosition(row:2,column:1), GridPosition(row:2,column:2)
        ], size: 3),
        BlockShape(color: .green, positions: [
            GridPosition(row:0,column:0), GridPosition(row:0,column:1), GridPosition(row:0,column:2),
            GridPosition(row:1,column:0), GridPosition(row:1,column:1), GridPosition(row:1,column:2),
            GridPosition(row:2,column:0), GridPosition(row:2,column:1), GridPosition(row:2,column:2)
        ], size: 3),
        // L
        BlockShape(color: .green, positions: [GridPosition(row:0,column:0), GridPosition(row:1,column:0), GridPosition(row:2,column:0), GridPosition(row:2,column:1)], size: 3),
        // L (üstten ters)
        BlockShape(color: .purple, positions: [GridPosition(row:0,column:1), GridPosition(row:1,column:1), GridPosition(row:2,column:1), GridPosition(row:2,column:0)], size: 3),
        // T
        BlockShape(color: .purple, positions: [GridPosition(row:0,column:1), GridPosition(row:1,column:0), GridPosition(row:1,column:1), GridPosition(row:1,column:2)], size: 3),
        // S
        BlockShape(color: .red, positions: [GridPosition(row:0,column:1), GridPosition(row:0,column:2), GridPosition(row:1,column:0), GridPosition(row:1,column:1)], size: 3),
        // Z
        BlockShape(color: .orange, positions: [GridPosition(row:0,column:0), GridPosition(row:0,column:1), GridPosition(row:1,column:1), GridPosition(row:1,column:2)], size: 3),
        // Z (dikey)
        BlockShape(color: .orange, positions: [GridPosition(row:0,column:1), GridPosition(row:1,column:0), GridPosition(row:1,column:1), GridPosition(row:2,column:0)], size: 3),
        // C şekli
        BlockShape(color: .blue, positions: [GridPosition(row:0,column:0), GridPosition(row:1,column:0), GridPosition(row:2,column:0), GridPosition(row:2,column:1), GridPosition(row:2,column:2)], size: 3),
        // Tekli blok (nokta) - 2x
        BlockShape(color: .blue, positions: [GridPosition(row:0,column:0)], size: 1),
        BlockShape(color: .blue, positions: [GridPosition(row:0,column:0)], size: 1)
    ]
    
    static func random() -> BlockShape {
        allShapes.randomElement()!
    }
} 