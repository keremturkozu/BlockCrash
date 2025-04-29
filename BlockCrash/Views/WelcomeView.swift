import SwiftUI

struct WelcomeView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @State private var isPulsing = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(UIColor.systemIndigo)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Title
                    Text("BlockCrash")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .scaleEffect(isPulsing ? 1.05 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                        .onAppear {
                            isPulsing = true
                        }
                    
                    // Game illustration
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.15))
                            .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                        
                        // Simple grid illustration
                        VStack(spacing: 4) {
                            ForEach(0..<5) { _ in
                                HStack(spacing: 4) {
                                    ForEach(0..<5) { _ in
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.2))
                                            .aspectRatio(1, contentMode: .fit)
                                    }
                                }
                            }
                        }
                        .padding(20)
                        
                        // Sample blocks
                        Circle()
                            .fill(Color.red)
                            .frame(width: 30, height: 30)
                            .offset(x: -40, y: -30)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green)
                            .frame(width: 30, height: 30)
                            .offset(x: 20, y: 40)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.yellow)
                            .frame(width: 30, height: 30)
                            .offset(x: 40, y: -40)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(width: 30, height: 30)
                            .offset(x: -30, y: 30)
                    }
                    
                    // Play button
                    Button {
                        gameViewModel.startNewGame()
                    } label: {
                        Text("Play Game")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 240, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(UIColor.systemIndigo),
                                                Color(UIColor.systemPurple)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // How to play
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How to Play:")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("• Drag blocks to the grid")
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("• Complete rows or columns to clear them")
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("• Score points and try to last as long as possible!")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .fullScreenCover(isPresented: .init(
                get: { !gameViewModel.isNewGame },
                set: { if !$0 { gameViewModel.resetGame() } }
            )) {
                GameView(gameViewModel: gameViewModel)
            }
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    WelcomeView()
} 