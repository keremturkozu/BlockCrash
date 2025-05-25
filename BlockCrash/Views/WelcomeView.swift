import SwiftUI
import AppTrackingTransparency
import AdSupport

struct WelcomeView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @State private var isPulsing = false
    @State private var particleSystem = ParticleSystem(numberOfParticles: 100)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(red: 0.3, green: 0.1, blue: 0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Grid background
                GridBackground()
                    .opacity(0.15)
                
                // Particle system
                particleSystem
                    .opacity(0.4)
                    .blendMode(.screen)
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Title
                    Text("Block Crush")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .cyan, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.6), radius: 15, x: 0, y: 5)
                        .scaleEffect(isPulsing ? 1.05 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                        .onAppear {
                            isPulsing = true
                            particleSystem.start()
                        }
                    
                    // Game illustrations - 2x2 Grid of Tetris-like shapes
                    HStack { // Centering HStack
                        Spacer()
                        VStack(spacing: 24) { // Container for the 2x2 grid and its background
                            // Row 1
                            HStack(spacing: 24) {
                                TetrominoShape(shape: .lShape)
                                    .frame(width: 80, height: 80)
                                TetrominoShape(shape: .zShape)
                                    .frame(width: 80, height: 80)
                            }
                            // Row 2
                            HStack(spacing: 24) {
                                TetrominoShape(shape: .square)
                                    .frame(width: 80, height: 80)
                                TetrominoShape(shape: .tShape)
                                    .frame(width: 80, height: 80)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // Center shapes within this VStack
                        .padding(20) // Padding inside the background box
                        .offset(x: 10, y: 10) // Offset shapes within the padded area, before background
                        .background( // Background for the 2x2 grid
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                                .background(
                                    .ultraThinMaterial,
                                    in: RoundedRectangle(cornerRadius: 16)
                                )
                                .shadow(color: .purple.opacity(0.3), radius: 10)
                        )
                        // Define the size of the box containing the grid
                        .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.6)
                        // .offset(x: 20, y: 20) // Offset by approx. one block size (80/4 = 20)
                        Spacer()
                    }
                    
                    // Play button
                    Button {
                        gameViewModel.startNewGame()
                    } label: {
                        Text("Play Game")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 240, height: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.4, green: 0.2, blue: 0.8),
                                                Color(red: 0.6, green: 0.1, blue: 0.9)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: Color.purple.opacity(0.5), radius: 10, x: 0, y: 5)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Remove Ads button (ana menüde)
                    if !AdManager.shared.adsRemoved {
                        Button {
                            print("🛒 Remove Ads tapped from main menu")
                            AdManager.shared.purchaseRemoveAds()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "nosign")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Remove Ads")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(width: 180, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.orange.opacity(0.8),
                                                Color.red.opacity(0.8)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .shadow(color: Color.orange.opacity(0.3), radius: 6, x: 0, y: 3)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    // How to play
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to Play:")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "hand.draw")
                                .foregroundColor(.cyan)
                            Text("Drag blocks to the grid")
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.square")
                                .foregroundColor(.cyan)
                            Text("Complete rows or columns to clear them")
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "star")
                                .foregroundColor(.cyan)
                            Text("Score points and try to last as long as possible!")
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.2))
                            .background(
                                .ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                    )
                    .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .fullScreenCover(isPresented: .init(
                get: { 
                    let shouldShow = !gameViewModel.isNewGame || gameViewModel.showingContinueAd
                    print("🏠 WelcomeView: isNewGame=\(gameViewModel.isNewGame), showingContinueAd=\(gameViewModel.showingContinueAd), shouldShow=\(shouldShow)")
                    return shouldShow
                },
                set: { newValue in
                    print("🏠 WelcomeView: fullScreenCover set to \(newValue)")
                    if !newValue && !gameViewModel.showingContinueAd { 
                        print("🏠 WelcomeView: Calling resetGame()")
                        gameViewModel.resetGame() 
                    }
                }
            )) {
                GameView(gameViewModel: gameViewModel)
            }
        }
    }
    
    // Bu fonksiyon AppDelegate'e taşındığı için buradan kaldırılabilir.
    /*
    func requestIDFAPermission() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { initialStatus in
                print("IDFA Initial Request Status: \(initialStatus)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { 
                    let currentStatus = ATTrackingManager.trackingAuthorizationStatus
                    print("IDFA Current Status (after 2s): \(currentStatus)")
                    if currentStatus == .authorized {
                        let idfa = ASIdentifierManager.shared().advertisingIdentifier
                        print("SUCCESS IDFA (after 2s): \(idfa.uuidString)")
                    } else {
                        print("IDFA not authorized after 2s. Status: \(currentStatus)")
                    }
                }
            }
        }
    }
    */
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Particle system for background sparkle effect
struct ParticleSystem: View {
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var size: CGFloat
        var opacity: Double
        var speed: Double
    }
    
    private var numberOfParticles: Int
    @State private var particles: [Particle] = []
    @State private var timer: Timer?
    
    init(numberOfParticles: Int) {
        self.numberOfParticles = numberOfParticles
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color.white)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                initializeParticles(in: geometry.size)
            }
            .onChange(of: geometry.size) { newSize in
                initializeParticles(in: newSize)
            }
        }
    }
    
    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.none) {
                updateParticles()
            }
        }
    }
    
    private func initializeParticles(in size: CGSize) {
        particles = (0..<numberOfParticles).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.1...0.5),
                speed: Double.random(in: 0.2...1.5)
            )
        }
    }
    
    private func updateParticles() {
        for i in 0..<particles.count {
            var particle = particles[i]
            particle.position.y -= particle.speed
            particle.opacity -= 0.002
            
            if particle.position.y < 0 || particle.opacity <= 0 {
                let screenHeight = UIScreen.main.bounds.height
                particle.position.y = screenHeight + particle.size
                particle.position.x = CGFloat.random(in: 0...UIScreen.main.bounds.width)
                particle.opacity = Double.random(in: 0.1...0.5)
            }
            
            particles[i] = particle
        }
    }
}

// Grid background effect
struct GridBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let spacing: CGFloat = 40
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Vertical lines
                for i in stride(from: 0, through: width, by: spacing) {
                    path.move(to: CGPoint(x: i, y: 0))
                    path.addLine(to: CGPoint(x: i, y: height))
                }
                
                // Horizontal lines
                for i in stride(from: 0, through: height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: i))
                    path.addLine(to: CGPoint(x: width, y: i))
                }
            }
            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        }
    }
}

// Tetromino shape types and view
enum TetrominoType {
    case lShape, zShape, square, tShape, iShape, sShape, jShape, lineShape, dotShape
}

struct TetrominoShape: View {
    let shape: TetrominoType
    
    var body: some View {
        ZStack {
            blockGrid
        }
        .shadow(color: shapeColor.opacity(0.7), radius: 10)
    }
    
    private var blockGrid: some View {
        GeometryReader { geo in
            let blockSize = min(geo.size.width, geo.size.height) / 4
            
            ZStack {
                ForEach(0..<blocks.count, id: \.self) { index in
                    let point = blocks[index]
                    RoundedRectangle(cornerRadius: 2)
                        .fill(shapeColor)
                        .frame(width: blockSize, height: blockSize)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(RadialGradient(
                                    gradient: Gradient(colors: [shapeColor.opacity(0.2), .clear]),
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: blockSize
                                ))
                        )
                        .offset(x: CGFloat(point.0) * blockSize - (geo.size.width / 2) + (blockSize / 2),
                                y: CGFloat(point.1) * blockSize - (geo.size.height / 2) + (blockSize / 2))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height) // Ensure ZStack uses full geo size
            .clipped() // Optional: To see if anything is drawn outside bounds
        }
    }
    
    private var blocks: [(Int, Int)] {
        switch shape {
        case .lShape:
            return [(0, 0), (0, 1), (0, 2), (1, 2)]
        case .zShape:
            return [(0, 0), (1, 0), (1, 1), (2, 1)]
        case .square:
            return [(0, 0), (1, 0), (0, 1), (1, 1)]
        case .tShape:
            return [(0, 1), (1, 0), (1, 1), (2, 1)]
        case .iShape:
            return [(0,0), (1,0), (2,0), (3,0)]
        case .sShape:
            return [(1,0), (2,0), (0,1), (1,1)]
        case .jShape:
            return [(1,0), (1,1), (1,2), (0,2)]
        case .lineShape:
            return [(0,0), (0,1), (0,2), (0,3)]
        case .dotShape:
            return [(0,0)]
        }
    }
    
    private var shapeColor: Color {
        switch shape {
        case .lShape:
            return Color.orange
        case .zShape:
            return Color.red
        case .square:
            return Color.yellow
        case .tShape:
            return Color.purple
        case .iShape:
            return Color.blue
        case .sShape:
            return Color.green
        case .jShape:
            return Color.indigo
        case .lineShape:
            return Color.mint
        case .dotShape:
            return Color.gray
        }
    }
}

#Preview {
    WelcomeView()
} 