import SwiftUI

enum DesignConstants {
    // MARK: - Colors
    enum Colors {
        static let primaryBackground = LinearGradient(
            gradient: Gradient(colors: [Color.black, Color(UIColor.systemIndigo)]),
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let buttonGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color(UIColor.systemIndigo),
                Color(UIColor.systemPurple)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let blockColors: [Color] = [
            Color(UIColor.systemRed),
            Color(UIColor.systemBlue),
            Color(UIColor.systemGreen),
            Color(UIColor.systemYellow),
            Color(UIColor.systemPurple)
        ]
    }
    
    // MARK: - Typography
    enum Typography {
        static let title = Font.system(size: 48, weight: .bold, design: .rounded)
        static let heading = Font.system(size: 36, weight: .bold, design: .rounded)
        static let buttonText = Font.system(size: 24, weight: .bold, design: .rounded)
        static let scoreLabel = Font.caption
        static let scoreValue = Font.system(size: 32, weight: .bold, design: .rounded)
    }
    
    // MARK: - Layout
    enum Layout {
        static let screenPadding: CGFloat = 20
        static let elementSpacing: CGFloat = 40
        static let buttonCornerRadius: CGFloat = 16
        static let buttonHeight: CGFloat = 60
        static let blockCornerRadius: CGFloat = 4
        
        // Minimum touch target size (44x44 points as per Apple HIG)
        static let minimumTouchTargetSize: CGFloat = 44
    }
    
    // MARK: - Animation
    enum Animation {
        static let buttonScale: CGFloat = 0.95
        static let titlePulse: CGFloat = 1.05
        static let pulseAnimationDuration: Double = 1.2
        static let easeInOutTiming = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
} 