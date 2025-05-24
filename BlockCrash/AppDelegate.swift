import SwiftUI
import AppTrackingTransparency
import AdSupport // ASIdentifierManager için

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("AppDelegate: application(_:didFinishLaunchingWithOptions:) CALLED")
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("AppDelegate: applicationDidBecomeActive CALLED")
        requestIDFAPermission()
    }

    func requestIDFAPermission() {
        print("AppDelegate: requestIDFAPermission() CALLED")
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async { // UI ile ilgili olmasa da, ana thread'e geçiş yapmak iyi bir pratiktir.
                    print("IDFA Request Status from AppDelegate: \(status)")
                    switch status {
                    case .authorized:
                        // IDFA alınabilir.
                        let idfa = ASIdentifierManager.shared().advertisingIdentifier
                        print("IDFA (from AppDelegate): \(idfa.uuidString)")
                        // Burada AdManager'a veya başka bir servise bilgi verebilirsiniz.
                        // Örneğin, test cihazı olarak AdMob'a göndermek için bir flag ayarlayabilirsiniz.
                    case .denied:
                        print("IDFA permission denied from AppDelegate.")
                    case .notDetermined:
                        print("IDFA permission not determined from AppDelegate. The user has not yet made a choice.")
                    case .restricted:
                        print("IDFA permission restricted (e.g., by parental controls) from AppDelegate.")
                    @unknown default:
                        print("IDFA permission status unknown from AppDelegate.")
                    }
                }
            }
        }
    }
} 