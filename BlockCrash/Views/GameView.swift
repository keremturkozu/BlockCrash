import SwiftUI
import SpriteKit

struct GameView: View {
    @ObservedObject var gameViewModel: GameViewModel
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.09, green: 0.13, blue: 0.25), Color(red: 0.18, green: 0.22, blue: 0.45), Color(red: 0.09, green: 0.13, blue: 0.25)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("SCORE")
                                .font(.caption)
                                .foregroundColor(Color.yellow.opacity(0.85))
                            Text("\(gameViewModel.score)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Color.orange)
                        }
                        Spacer()
                        Button {
                            gameViewModel.resetGame()
                        } label: {
                            Image(systemName: "house.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.7)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                )
                                .shadow(color: Color.purple.opacity(0.25), radius: 6, x: 0, y: 2)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    
                    // Game area
                    ZStack {
                        SpriteView(gameViewModel: gameViewModel)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        if gameViewModel.gameOver {
                            GameOverView(score: gameViewModel.score) {
                                gameViewModel.startNewGame()
                            }
                            .transition(.opacity)
                            .animation(.easeInOut, value: gameViewModel.gameOver)
                        }
                    }
                }
            }
            .onChange(of: scenePhase) { oldValue, newValue in
                if newValue == .background {
                    // Pause logic if needed
                }
            }
        }
    }
}

struct GameOverView: View {
    let score: Int
    let onPlayAgain: () -> Void
    @State private var isAnimated = false
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            VStack(spacing: 30) {
                Text("Game Over")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                VStack {
                    Text("Your Score")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    Text("\(score)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 5)
                }
                .scaleEffect(isAnimated ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimated
                )
                .onAppear { isAnimated = true }
                Button {
                    onPlayAgain()
                } label: {
                    Text("Play Again")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 220, height: 55)
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
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 10)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemGray6).opacity(0.9))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(30)
        }
    }
}

#Preview {
    GameView(gameViewModel: GameViewModel())
} 