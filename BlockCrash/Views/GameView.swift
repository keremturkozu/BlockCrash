import SwiftUI
import SpriteKit

struct GameView: View {
    @ObservedObject var gameViewModel: GameViewModel
    @Environment(\.scenePhase) var scenePhase
    @State private var showMenu = false
    
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
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SCORE")
                                .font(.caption)
                                .foregroundColor(Color.yellow.opacity(0.85))
                            Text("\(gameViewModel.score)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Color.orange)
                        }
                        Spacer()
                        VStack(alignment: .center, spacing: 2) {
                            Text("HIGHSCORE")
                                .font(.caption)
                                .foregroundColor(Color.green.opacity(0.85))
                            Text("\(gameViewModel.highscore)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color.green)
                        }
                        Spacer()
                        Button {
                            showMenu = true
                        } label: {
                            Image(systemName: "gear")
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
                            GameOverView(score: gameViewModel.score, onPlayAgain: {
                                print("🎮 GameOverView callback triggered - Starting new game first")
                                // Önce game over state'ini kaldır (GameOverView'ı dismiss et)
                                gameViewModel.startNewGame()
                                
                                // Ardından kısa bir delay ile interstitial reklamı göster
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    print("🎮 Now showing interstitial ad after delay")
                                    AdManager.shared.showInterstitialAd {
                                        print("🎮 Interstitial ad completed")
                                    }
                                }
                            }, onContinueWithAd: {
                                print("🎬 Continue with Ad selected")
                                AdManager.shared.showContinueAd {
                                    print("🎬 Continue ad completed - resuming game")
                                    gameViewModel.continueGame()
                                }
                            }, onContinueWithPurchase: {
                                print("💰 Continue with Purchase selected")
                                AdManager.shared.purchaseContinue {
                                    print("💰 Continue purchase completed - resuming game")
                                    gameViewModel.continueGame()
                                }
                            })
                            .transition(.opacity)
                            .animation(.easeInOut, value: gameViewModel.gameOver)
                        }
                        if showMenu {
                            InGameMenuView(
                                onHome: { showMenu = false; gameViewModel.resetGame() },
                                onReplay: { showMenu = false; gameViewModel.startNewGame() },
                                onTerms: { if let url = URL(string: "https://example.com/terms") { UIApplication.shared.open(url) } },
                                onPrivacy: { if let url = URL(string: "https://example.com/privacy") { UIApplication.shared.open(url) } },
                                onRemoveAds: { 
                                    AdManager.shared.purchaseRemoveAds()
                                    showMenu = false 
                                },
                                onRestore: { 
                                    AdManager.shared.restorePurchases()
                                    showMenu = false 
                                },
                                onClose: { showMenu = false }
                            )
                        }
                    }
                    
                    // Banner reklam alanı - ekranın altında
                    if !AdManager.shared.adsRemoved {
                        BannerAdViewRepresentable()
                            .frame(height: 50)
                            .background(Color.black.opacity(0.1))
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
    let onContinueWithAd: () -> Void
    let onContinueWithPurchase: () -> Void
    @State private var isAnimated = false
    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.8),
                    Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0.9),
                    Color.black.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Game Over Title
                VStack(spacing: 8) {
                    Text("Game Over")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .cyan.opacity(0.8), .purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.5), radius: 8, x: 0, y: 4)
                    
                    // Score section
                    VStack(spacing: 4) {
                        Text("Your Score")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(score)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .orange.opacity(0.6), radius: 8, x: 0, y: 3)
                            .scaleEffect(isAnimated ? 1.05 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true),
                                value: isAnimated
                            )
                    }
                    .onAppear { isAnimated = true }
                }
                .padding(.top, 20)
                
                // Continue Options - Ana seçenek olarak öne çıkarıldı
                VStack(spacing: 16) {
                    Text("Continue Playing?")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                    
                    HStack(spacing: 16) {
                        // Watch Ad to Continue - Daha büyük ve prominent
                        Button {
                            print("🎬 Continue with Ad button tapped!")
                            onContinueWithAd()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "play.tv")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Watch Ad")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("FREE")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.green.opacity(0.9))
                            }
                            .frame(width: 120, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.green.opacity(0.8),
                                                Color.teal.opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // Pay to Continue - Daha büyük ve prominent
                        Button {
                            print("💰 Continue with Purchase button tapped!")
                            onContinueWithPurchase()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "bolt.circle.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Instant")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("$0.99")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.yellow.opacity(0.9))
                            }
                            .frame(width: 120, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.orange.opacity(0.8),
                                                Color.red.opacity(0.7)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.08))
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 20)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Play Again - İkincil seçenek olarak daha küçük
                Button {
                    print("GameOverView: Play Again button tapped!")
                    onPlayAgain()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .bold))
                        Text("Start New Game")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(width: 200, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(UIColor.systemIndigo).opacity(0.7),
                                        Color(UIColor.systemPurple).opacity(0.7)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .purple.opacity(0.3), radius: 6, x: 0, y: 3)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Remove Ads - En altta, küçük
                if !AdManager.shared.adsRemoved {
                    Button {
                        print("🛒 Remove Ads tapped from Game Over")
                        AdManager.shared.purchaseRemoveAds()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "nosign")
                                .font(.system(size: 11, weight: .medium))
                            Text("Remove Ads")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 110, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(32)
        }
    }
}

struct InGameMenuView: View {
    var onHome: () -> Void
    var onReplay: () -> Void
    var onTerms: () -> Void
    var onPrivacy: () -> Void
    var onRemoveAds: () -> Void
    var onRestore: () -> Void
    var onClose: () -> Void
    @State private var vibrationOn = true
    var body: some View {
        ZStack {
            Color(red: 0.09, green: 0.13, blue: 0.25)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(red: 0.13, green: 0.18, blue: 0.29))
                        .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 8)
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Button(action: onClose) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color.orange.opacity(0.8))
                                    .padding(8)
                            }
                        }
                        .padding(.top, 8)
                        Group {
                            MenuRowButton(icon: "arrow.clockwise", title: "Replay", buttonTitle: "Play", color: .green, action: onReplay)
                            Divider().background(Color.white.opacity(0.25))
                            MenuRowButton(icon: "house.fill", title: "Home", buttonTitle: "Back", color: .green, action: onHome)
                            Divider().background(Color.white.opacity(0.25))
                            MenuRowToggle(icon: "iphone.radiowaves.left.and.right", title: "Vibration", isOn: $vibrationOn, color: Color.orange)
                            Divider().background(Color.white.opacity(0.25))
                            MenuRowButton(icon: "doc.text", title: "Terms of Service", buttonTitle: "Open", color: .green, action: onTerms)
                            Divider().background(Color.white.opacity(0.25))
                            MenuRowButton(icon: "lock.shield", title: "Privacy Policy", buttonTitle: "Open", color: .green, action: onPrivacy)
                            Divider().background(Color.white.opacity(0.25))
                            MenuRowButton(icon: "nosign", title: "Remove Ads", buttonTitle: "Remove", color: .green, action: onRemoveAds)
                            Divider().background(Color.white.opacity(0.25))
                            MenuRowButton(icon: "arrow.triangle.2.circlepath", title: "Restore Purchases", buttonTitle: "Restore", color: .green, action: onRestore)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 2)
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 18)
                }
                .frame(maxWidth: 370, minHeight: 480, maxHeight: 540)
            }
            .padding(.horizontal, 18)
        }
    }
}

struct MenuRowToggle: View {
    var icon: String
    var title: String
    @Binding var isOn: Bool
    var color: Color = Color.orange
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(color)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: color))
                .labelsHidden()
        }
        .padding(.vertical, 8)
    }
}

struct MenuRowButton: View {
    var icon: String
    var title: String
    var buttonTitle: String
    var color: Color = Color.orange
    var action: () -> Void
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color.orange)
                .frame(width: 36, height: 36)
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color.orange)
            Spacer()
            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange)
                            .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    GameView(gameViewModel: GameViewModel())
} 