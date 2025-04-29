import SpriteKit
import SwiftUI
import Combine

class GameScene: SKScene {
    weak var gameViewModel: GameViewModel?
    static let gridSize = 8
    private var cancellables = Set<AnyCancellable>()
    
    private var gridNodes: [[SKShapeNode?]] = []
    private var blockSize: CGFloat = 0
    private var gridOrigin: CGPoint = .zero
    
    private var draggingShape: (shape: BlockShape, nodes: [SKShapeNode], offset: CGPoint)?
    private var nextShapeOrigins: [UUID: CGPoint] = [:]
    
    private var shapeNodes: [UUID: [SKShapeNode]] = [:] // Aktif şekil node'ları
    
    private var previewNodes: [SKShapeNode] = [] // Drag preview için
    
    override func didMove(to view: SKView) {
        print("GameScene: didMove(to:) called with size \(size)")
        backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1.0) // Modern koyu mavi
        
        // Add debug info
        let debugNode = SKLabelNode(text: "Loading game...")
        debugNode.position = CGPoint(x: size.width/2, y: size.height/2)
        debugNode.fontColor = .red
        debugNode.fontSize = 24
        addChild(debugNode)
        
        // Eğer boyutlar 0 ise, grid kurulumunu bir sonraki runloop'a bırak
        if size.width == 0 || size.height == 0 {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.setupGrid()
                self.setupSubscriptions()
                self.reload()
                debugNode.text = "Game loaded"
                debugNode.run(SKAction.fadeOut(withDuration: 1.0)) {
                    debugNode.removeFromParent()
                }
            }
        } else {
            setupGrid()
            setupSubscriptions()
            reload()
            debugNode.text = "Game loaded"
            debugNode.run(SKAction.fadeOut(withDuration: 1.0)) {
                debugNode.removeFromParent()
            }
        }
    }
    
    private func setupGrid() {
        let gridWidth = min(size.width, size.height) * 0.92
        blockSize = gridWidth / CGFloat(Self.gridSize)
        let gridHeight = blockSize * CGFloat(Self.gridSize)
        gridOrigin = CGPoint(
            x: (size.width - gridWidth) / 2,
            y: (size.height + gridHeight) / 2 + blockSize * 1.5
        )
        gridNodes = Array(repeating: Array(repeating: nil, count: Self.gridSize), count: Self.gridSize)
        shapeNodes = [:]
        nextShapeOrigins = [:]
        
        print("GameScene: Grid setup with origin \(gridOrigin), blockSize \(blockSize)")
        
        // Draw grid lines
        drawGridLines(gridSize: Self.gridSize, gridWidth: gridWidth)
        
        // Add a visible background to the grid area
        let gridBackground = SKShapeNode(rect: CGRect(
            x: gridOrigin.x, 
            y: gridOrigin.y - gridWidth,
            width: gridWidth, 
            height: gridWidth
        ))
        gridBackground.fillColor = .lightGray.withAlphaComponent(0.1)
        gridBackground.strokeColor = .white
        gridBackground.lineWidth = 2
        gridBackground.zPosition = 1
        addChild(gridBackground)
    }
    
    private func drawGridLines(gridSize: Int, gridWidth: CGFloat) {
        let gridNode = SKShapeNode()
        let path = CGMutablePath()
        
        // Draw horizontal lines
        for i in 0...gridSize {
            let y = gridOrigin.y - CGFloat(i) * blockSize
            path.move(to: CGPoint(x: gridOrigin.x, y: y))
            path.addLine(to: CGPoint(x: gridOrigin.x + gridWidth, y: y))
        }
        
        // Draw vertical lines
        for i in 0...gridSize {
            let x = gridOrigin.x + CGFloat(i) * blockSize
            path.move(to: CGPoint(x: x, y: gridOrigin.y))
            path.addLine(to: CGPoint(x: x, y: gridOrigin.y - gridWidth))
        }
        
        gridNode.path = path
        gridNode.strokeColor = .gray.withAlphaComponent(0.4)
        gridNode.lineWidth = 1
        gridNode.zPosition = 2
        
        addChild(gridNode)
    }
    
    private func setupSubscriptions() {
        guard let gameViewModel = gameViewModel else { 
            print("GameScene: gameViewModel is nil in setupSubscriptions")
            return 
        }
        
        print("GameScene: Setting up subscriptions")
        
        // Update grid when game state changes
        gameViewModel.$gameState
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)
    }
    
    func reload() {
        print("[DEBUG] reload çağrıldı")
        removeAllChildren()
        setupGrid()
        drawPlacedBlocks()
        drawNextShapes()
    }
    
    // --- Gradient Jewel Block Drawing ---
    private func createJewelBlockNode(color: BlockColor, size: CGFloat, highlight: Bool = true) -> SKNode {
        let node = SKNode()
        // Ana kare
        let base = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: size * 0.18)
        base.fillColor = UIColor(color.color)
        base.strokeColor = UIColor.white.withAlphaComponent(0.7)
        base.lineWidth = 2.5
        node.addChild(base)
        // Gradient overlay (üstten alta doğru)
        let gradient = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: size * 0.18)
        let tex = gradientTexture(size: CGSize(width: size, height: size), color: color)
        gradient.fillTexture = tex
        gradient.fillColor = .white
        gradient.strokeColor = .clear
        node.addChild(gradient)
        // Highlight (üstte parlaklık)
        if highlight {
            let highlightNode = SKShapeNode(rectOf: CGSize(width: size * 0.7, height: size * 0.28), cornerRadius: size * 0.14)
            highlightNode.position = CGPoint(x: 0, y: size * 0.18)
            highlightNode.fillColor = .white.withAlphaComponent(0.32)
            highlightNode.strokeColor = .clear
            node.addChild(highlightNode)
        }
        // Shadow (altta koyuluk)
        let shadowNode = SKShapeNode(rectOf: CGSize(width: size * 0.7, height: size * 0.18), cornerRadius: size * 0.09)
        shadowNode.position = CGPoint(x: 0, y: -size * 0.22)
        shadowNode.fillColor = .black.withAlphaComponent(0.18)
        shadowNode.strokeColor = .clear
        node.addChild(shadowNode)
        return node
    }
    private func gradientTexture(size: CGSize, color: BlockColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let context = ctx.cgContext
            let colors = [UIColor(color.color).withAlphaComponent(0.95).cgColor, UIColor.black.withAlphaComponent(0.18).cgColor] as CFArray
            let space = CGColorSpaceCreateDeviceRGB()
            let grad = CGGradient(colorsSpace: space, colors: colors, locations: [0.0, 1.0])!
            context.drawLinearGradient(grad, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: 0, y: 0), options: [])
        }
        return SKTexture(image: img)
    }
    
    private func drawPlacedBlocks() {
        print("[DEBUG] drawPlacedBlocks çağrıldı")
        guard let grid = gameViewModel?.gameState.grid else { print("[DEBUG] Grid yok veya nil"); return }
        print("[DEBUG] Grid: \(grid)")
        for row in 0..<Self.gridSize {
            for col in 0..<Self.gridSize {
                if let color = grid[row][col] {
                    let jewel = createJewelBlockNode(color: color, size: blockSize * 0.96)
                    jewel.position = gridPositionToPoint(row: row, col: col)
                    jewel.zPosition = 10
                    addChild(jewel)
                }
            }
        }
    }
    
    private func drawNextShapes() {
        print("[DEBUG] drawNextShapes çağrıldı")
        guard let shapes = gameViewModel?.gameState.nextShapes else { print("[DEBUG] NextShapes yok veya nil"); return }
        print("[DEBUG] NextShapes: \(shapes)")
        let previewBlockSize = blockSize * 0.7
        let spacing: CGFloat = blockSize * 0.5
        let totalWidth = CGFloat(shapes.count) * previewBlockSize * 4 + CGFloat(shapes.count - 1) * spacing
        let startX = (size.width - totalWidth) / 2
        let y = gridOrigin.y - blockSize * CGFloat(Self.gridSize) - blockSize * 2.2
        for (i, shape) in shapes.enumerated() {
            let origin = CGPoint(x: startX + CGFloat(i) * (previewBlockSize * 4 + spacing), y: y)
            let nodes = drawShapePreview(shape, at: origin, blockSize: previewBlockSize)
            shapeNodes[shape.id] = nodes
            nextShapeOrigins[shape.id] = origin
        }
    }
    
    // Küçük boyutlu jewel bloklarla preview çizimi
    private func drawShapePreview(_ shape: BlockShape, at origin: CGPoint, blockSize: CGFloat) -> [SKShapeNode] {
        var nodes: [SKShapeNode] = []
        for pos in shape.positions {
            let jewel = createJewelBlockNode(color: shape.color, size: blockSize, highlight: true)
            jewel.position = CGPoint(
                x: origin.x + CGFloat(pos.column) * blockSize,
                y: origin.y - CGFloat(pos.row) * blockSize
            )
            jewel.zPosition = 15
            addChild(jewel)
            if let mainShape = jewel.children.first as? SKShapeNode {
                nodes.append(mainShape)
            }
        }
        return nodes
    }
    
    private func drawShape(_ shape: BlockShape, at origin: CGPoint, forDrag: Bool) -> [SKShapeNode] {
        var nodes: [SKShapeNode] = []
        let jewelSize = forDrag ? blockSize * 1.08 : blockSize * 0.82
        for pos in shape.positions {
            let jewel = createJewelBlockNode(color: shape.color, size: jewelSize, highlight: true)
            jewel.position = CGPoint(
                x: origin.x + CGFloat(pos.column) * blockSize,
                y: origin.y - CGFloat(pos.row) * blockSize
            )
            jewel.zPosition = forDrag ? 100 : 20
            addChild(jewel)
            // Ana kareyi SKShapeNode olarak döndürmek için:
            if let mainShape = jewel.children.first as? SKShapeNode {
                nodes.append(mainShape)
            }
        }
        return nodes
    }
    
    private func gridPositionToPoint(row: Int, col: Int) -> CGPoint {
        return CGPoint(
            x: gridOrigin.x + blockSize * CGFloat(col) + blockSize / 2,
            y: gridOrigin.y - blockSize * CGFloat(row) - blockSize / 2
        )
    }
    
    private func pointToGridPosition(_ point: CGPoint) -> GridPosition? {
        let relativeX = point.x - gridOrigin.x
        let relativeY = gridOrigin.y - point.y
        
        guard relativeX >= 0, relativeY >= 0, 
              relativeX < blockSize * CGFloat(Self.gridSize),
              relativeY < blockSize * CGFloat(Self.gridSize) else {
            return nil
        }
        
        let col = Int(relativeX / blockSize)
        let row = Int(relativeY / blockSize)
        
        return GridPosition(row: row, column: col)
    }
    
    // MARK: - Touch Handling (Drag & Drop)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let shapes = gameViewModel?.gameState.nextShapes else { return }
        let location = touch.location(in: self)
        for shape in shapes {
            if let nodes = shapeNodes[shape.id], nodes.contains(where: { $0.contains(location) }) {
                // Drag başlat
                let offset = CGPoint(x: location.x - nodes[0].position.x, y: location.y - nodes[0].position.y)
                draggingShape = (shape, nodes, offset)
                for node in nodes { node.zPosition = 200; node.alpha = 0.7 }
                // Drag başlarken preview'u temizle
                clearPreviewNodes()
                break
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let dragging = draggingShape else { return }
        let location = touch.location(in: self)
        let newOrigin = CGPoint(x: location.x - dragging.offset.x, y: location.y - dragging.offset.y)
        for (i, pos) in dragging.shape.positions.enumerated() {
            let x = newOrigin.x + CGFloat(pos.column) * blockSize
            let y = newOrigin.y - CGFloat(pos.row) * blockSize
            dragging.nodes[i].position = CGPoint(x: x, y: y)
        }
        draggingShape = (dragging.shape, dragging.nodes, dragging.offset)
        // --- Drag preview ---
        clearPreviewNodes()
        if let gridPos = previewGridPosition(for: dragging.shape, at: location) {
            showPreview(for: dragging.shape, at: gridPos, canPlace: gameViewModel?.gameState.canPlace(shape: dragging.shape, at: gridPos) ?? false)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let dragging = draggingShape else { draggingShape = nil; clearPreviewNodes(); return }
        let location = touch.location(in: self)
        // Grid'e bırakılacak pozisyonu bul
        if let gridPos = previewGridPosition(for: dragging.shape, at: location), let gameViewModel = gameViewModel {
            // Şeklin tüm blokları grid içinde mi kontrolü zaten previewGridPosition'da var
            if gameViewModel.gameState.canPlace(shape: dragging.shape, at: gridPos) {
                // Yerleştir
                _ = gameViewModel.gameState.place(shape: dragging.shape, at: gridPos)
                gameViewModel.objectWillChange.send()
                reload()
            } else {
                // Geri döndür
                if let origin = nextShapeOrigins[dragging.shape.id] {
                    for (i, pos) in dragging.shape.positions.enumerated() {
                        let x = origin.x + CGFloat(pos.column) * blockSize
                        let y = origin.y - CGFloat(pos.row) * blockSize
                        dragging.nodes[i].run(SKAction.move(to: CGPoint(x: x, y: y), duration: 0.2))
                        dragging.nodes[i].zPosition = 20
                        dragging.nodes[i].alpha = 1.0
                    }
                }
            }
        } else {
            // Geri döndür
            if let origin = nextShapeOrigins[dragging.shape.id] {
                for (i, pos) in dragging.shape.positions.enumerated() {
                    let x = origin.x + CGFloat(pos.column) * blockSize
                    let y = origin.y - CGFloat(pos.row) * blockSize
                    dragging.nodes[i].run(SKAction.move(to: CGPoint(x: x, y: y), duration: 0.2))
                    dragging.nodes[i].zPosition = 20
                    dragging.nodes[i].alpha = 1.0
                }
            }
        }
        draggingShape = nil
        clearPreviewNodes()
    }
    
    // --- Drag Preview Yardımcıları ---
    private func previewGridPosition(for shape: BlockShape, at point: CGPoint) -> GridPosition? {
        // Drag edilen şeklin grid'e göre en küçük satır/sütununu bul
        let minRow = shape.positions.map { $0.row }.min() ?? 0
        let minCol = shape.positions.map { $0.column }.min() ?? 0
        // Tıklanan noktayı grid'e çevir
        guard let anchorGridPos = pointToGridPosition(point) else { return nil }
        // Şeklin anchor'u grid'e tam otursun diye offset uygula
        let gridPos = GridPosition(row: anchorGridPos.row - minRow, column: anchorGridPos.column - minCol)
        // Şeklin tüm blokları grid içinde mi kontrol et
        for pos in shape.positions {
            let row = gridPos.row + pos.row
            let col = gridPos.column + pos.column
            if row < 0 || row >= Self.gridSize || col < 0 || col >= Self.gridSize {
                return nil
            }
        }
        return gridPos
    }

    private func showPreview(for shape: BlockShape, at gridPos: GridPosition, canPlace: Bool) {
        for pos in shape.positions {
            let row = gridPos.row + pos.row
            let col = gridPos.column + pos.column
            guard row >= 0, row < Self.gridSize, col >= 0, col < Self.gridSize else { continue }
            let node = SKShapeNode(rectOf: CGSize(width: blockSize * 0.96, height: blockSize * 0.96), cornerRadius: 0)
            node.position = gridPositionToPoint(row: row, col: col)
            node.zPosition = 99
            node.fillColor = UIColor(shape.color.color).withAlphaComponent(canPlace ? 0.35 : 0.15)
            node.strokeColor = canPlace ? UIColor.green.withAlphaComponent(0.7) : UIColor.red.withAlphaComponent(0.7)
            node.lineWidth = 2.5
            addChild(node)
            previewNodes.append(node)
        }
    }

    private func clearPreviewNodes() {
        for node in previewNodes { node.removeFromParent() }
        previewNodes.removeAll()
    }
} 