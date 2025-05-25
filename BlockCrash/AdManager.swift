import SwiftUI
import GoogleMobileAds
import StoreKit

// AdManager sınıfı, reklamları yönetmek ve satın alma durumunu takip etmek için.
// ObservableObject protokolünü uygular, böylece SwiftUI görünümleri durumu izleyebilir.
class AdManager: NSObject, ObservableObject, FullScreenContentDelegate {

    // MARK: - Published Properties
    // Reklamların kaldırılıp kaldırılmadığını gösteren bayrak.
    // @AppStorage ile UserDefaults\'a kaydedilir ve oradan okunur.
    @AppStorage("adsRemoved") var adsRemoved: Bool = false

    // Banner reklam görünümü için.
    @Published var isBannerAdLoaded: Bool = false

    // Interstitial (geçiş) reklam için.
    private var interstitialAd: InterstitialAd?
    private var interstitialAdLoaded = false
    
    // MARK: - Ad Unit IDs
    // Bu ID'leri kendi AdMob Reklam Birimi ID'lerinizle değiştirin.
    // Test için AdMob'un sağladığı test ID'lerini kullanabilirsiniz.
    fileprivate let bannerAdUnitID: String = "ca-app-pub-7348943580529374/9836990780" 
    private let interstitialAdUnitID: String = "ca-app-pub-7348943580529374/1006180044" 
    
    // Test cihazı ID'si - kendi cihazınızın IDFA'sını buraya ekleyin
    private let testDeviceID: String = "YOUR_TEST_DEVICE_ID" // Bu değeri kendi test cihazınızla değiştirin

    // "Reklamları Kaldır" ürününün kimliği (App Store Connect'te tanımlanacak)
    private let removeAdsProductID: String = "com.BlockCrash.removeads"
    
    // "Continue Game" ürününün kimliği (App Store Connect'te tanımlanacak)  
    private let continueGameProductID: String = "com.BlockCrash.continue"

    // MARK: - Singleton Instance
    // AdManager\'a kolay erişim için singleton bir örnek.
    static let shared = AdManager()

    // MARK: - Root View Controller
    // Reklamları sunmak için kullanılacak root view controller.
    var rootViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return nil }
        return windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
    }

    // MARK: - Debug Methods
    func logCurrentState() {
        print("🔍 AdManager Current State:")
        print("  - adsRemoved: \(adsRemoved)")
        print("  - interstitialAdLoaded: \(interstitialAdLoaded)")
        print("  - interstitialAd exists: \(interstitialAd != nil)")
        print("  - bannerAdLoaded: \(isBannerAdLoaded)")
        print("  - rootViewController exists: \(rootViewController != nil)")
    }

    private override init() {
        super.init()
        
        print("AdManager: Initializing AdManager")
        print("AdManager: adsRemoved = \(adsRemoved)")
        
        // Sınıf başlatıldığında reklamları yüklemeye başla (eğer kaldırılmadıysa)
        if !adsRemoved {
            print("AdManager: Starting to load ads...")
            loadInterstitialAd()
        } else {
            print("AdManager: Ads are removed, not loading ads")
        }
    }

    // MARK: - Ad Loading Methods
    func loadInterstitialAd() {
        if adsRemoved { 
            print("AdManager: Ads are removed, not loading interstitial")
            return 
        }
        guard !interstitialAdLoaded else { // Zaten yüklü ve hazırsa tekrar yükleme
            print("AdManager: Interstitial ad already loaded and ready.")
            return
        }
        print("AdManager: Loading interstitial ad with ID: \(interstitialAdUnitID)")
        let request = Request()
        InterstitialAd.load(with: interstitialAdUnitID, request: request, completionHandler: { [weak self] (ad, error) in
            guard let self = self else { 
                print("AdManager: Self is nil in interstitial completion handler")
                return 
            }
            if let error = error {
                print("AdManager: Failed to load interstitial ad with error: \(error.localizedDescription)")
                self.interstitialAdLoaded = false
                return
            }
            print("AdManager: Interstitial ad loaded successfully!")
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
            self.interstitialAdLoaded = true // Yüklendi olarak işaretle
            print("AdManager: Interstitial ad is ready to show")
        })
    }

    // MARK: - Ad Presentation Methods
    func showInterstitialAd(completion: (() -> Void)? = nil) {
        print("AdManager: showInterstitialAd() called")
        
        if adsRemoved {
            print("AdManager: Ads are removed, skipping interstitial.")
            completion?()
            return
        }
        
        showInterstitialAdInternal(completion: completion)
    }
    
    // İç method - gerçek reklam gösterme mantığı
    private func showInterstitialAdInternal(completion: (() -> Void)? = nil) {
        print("AdManager: showInterstitialAdInternal() called")
        
        print("AdManager: Checking interstitial ad availability...")
        print("AdManager: interstitialAd exists: \(interstitialAd != nil)")
        print("AdManager: interstitialAdLoaded: \(interstitialAdLoaded)")
        
        guard let ad = interstitialAd, interstitialAdLoaded else {
            print("AdManager: Interstitial ad not ready or already shown.")
            print("AdManager: Attempting to load new interstitial ad...")
            loadInterstitialAd() // Bir sonraki sefer için yüklemeyi dene
            completion?()
            return
        }

        guard let rootVC = rootViewController else {
            print("AdManager: Could not find root view controller to present interstitial ad.")
            completion?()
            return
        }
        
        print("AdManager: Found root view controller: \(rootVC)")
        
        // En üstteki view controller'ı bul
        var topViewController = rootVC
        while let presentedVC = topViewController.presentedViewController {
            topViewController = presentedVC
        }
        
        print("AdManager: Top view controller: \(topViewController)")
        print("AdManager: Attempting to present interstitial ad from top VC.")
        presentInterstitial(ad: ad, from: topViewController, completion: completion)
    }
    
    private func presentInterstitial(ad: InterstitialAd, from rootVC: UIViewController, completion: (() -> Void)?) {
        // Completion'ı sakla, reklam kapandığında veya sunum başarısız olduğunda çağrılacak.
        setPendingInterstitialCompletion(completion)
        ad.present(from: rootVC)
        print("AdManager: present(from:) called on interstitial ad")
    }
    
    // MARK: - IAP (In-App Purchase) Methods
    
    func purchaseRemoveAds() {
        print("🛒 purchaseRemoveAds() called")
        
        // Şimdilik basit implementasyon - direkt reklamları kaldır
        // Production'da gerçek StoreKit implementasyonu gerekli
        self.adsRemoved = true
        
        // Banner ve interstitial reklamları temizle
        self.interstitialAd = nil
        self.interstitialAdLoaded = false
        
        print("✅ Ads removed successfully")
    }
    
    func restorePurchases() {
        print("🔄 restorePurchases() called")
        
        // Şimdilik basit implementasyon - reklamları kaldır
        // Production'da gerçek StoreKit restore implementasyonu gerekli
        self.adsRemoved = true
        self.interstitialAd = nil
        self.interstitialAdLoaded = false
        
        print("✅ Purchases restored, ads removed")
    }

    // MARK: - Continue Methods
    
    func showContinueAd(completion: @escaping () -> Void) {
        print("🎬 showContinueAd() called")
        
        if adsRemoved {
            print("🎬 Ads are removed, skipping continue ad")
            DispatchQueue.main.async {
                completion()
            }
            return
        }
        
        // Continue için normal interstitial sistemi kullan
        showInterstitialAd {
            print("🎬 Continue ad completed - calling completion")
            // Main thread'de completion'ı çağır
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func purchaseContinue(completion: @escaping () -> Void) {
        print("💰 purchaseContinue() called")
        
        // Şimdilik basit implementasyon - direkt continue'ye izin ver
        // Production'da gerçek StoreKit implementasyonu gerekli
        guard let rootVC = rootViewController else {
            print("💰 Could not find root view controller for continue purchase")
            DispatchQueue.main.async {
                completion()
            }
            return
        }
        
        let alert = UIAlertController(
            title: "Continue Playing",
            message: "Continue from where you left off for $0.99?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Purchase $0.99", style: .default) { _ in
            print("💰 User confirmed continue purchase")
            print("✅ Continue purchase successful")
            DispatchQueue.main.async {
                completion()
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("💰 User cancelled continue purchase")
        })
        
        rootVC.present(alert, animated: true)
    }

    // MARK: - FullScreenContentDelegate Methods
    // Reklam gösterilmeden önce çağrılır.
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("AdManager: ✅ adWillPresentFullScreenContent - Interstitial ad will present full screen content.")
        interstitialAdLoaded = false // Reklam gösterildikten sonra tekrar kullanılmaz, yeniden yüklenmeli.
        print("AdManager: Set interstitialAdLoaded to false")
    }

    // Reklam gösterilemediğinde çağrılır.
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("AdManager: ❌ didFailToPresentFullScreenContent - Interstitial ad failed to present with error: \(error.localizedDescription)")
        // Başarısız olursa, oyun akışının devam etmesi için bir mekanizma olmalı.
        executePendingInterstitialCompletion()
        print("AdManager: Attempting to load new interstitial ad after failure...")
        loadInterstitialAd() // Bir sonraki için yüklemeyi dene
    }

    // Reklam kapatıldığında çağrılır.
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("AdManager: ✅ adDidDismissFullScreenContent - Interstitial ad was dismissed.")
        
        // Kullanıcı reklamı kapattıktan sonra completion'ı çağır.
        executePendingInterstitialCompletion()
        self.interstitialAd = nil // Reklamı temizle
        print("AdManager: Cleared interstitial ad, loading new one...")
        loadInterstitialAd()     // Bir sonraki reklamı yükle
    }

    private var pendingInterstitialCompletion: (() -> Void)?

    private func setPendingInterstitialCompletion(_ completion: (() -> Void)?) {
        self.pendingInterstitialCompletion = completion
    }

    private func executePendingInterstitialCompletion() {
        DispatchQueue.main.async {
            print("AdManager: Executing pending interstitial completion on main thread")
            self.pendingInterstitialCompletion?()
            self.pendingInterstitialCompletion = nil // Tekrar çağrılmasını önle
        }
    }
}

// MARK: - SwiftUI Banner Ad View
struct BannerAdViewRepresentable: UIViewRepresentable {
    @ObservedObject var adManager = AdManager.shared

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adManager.bannerAdUnitID
        
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            bannerView.rootViewController = rootViewController
        } else {
            print("Could not find rootViewController for BannerAdViewRepresentable. This might happen if called too early or if the scene is not active.")
        }
        
        bannerView.delegate = context.coordinator
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        // SwiftUI durumu değiştikçe banner'ı güncellemek gerekebilir
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, BannerViewDelegate {
        let parent: BannerAdViewRepresentable

        init(_ parent: BannerAdViewRepresentable) {
            self.parent = parent
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("SwiftUI BannerAdView: Ad received.")
            parent.adManager.isBannerAdLoaded = true
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("SwiftUI BannerAdView: Failed to receive ad with error: \(error.localizedDescription)")
            parent.adManager.isBannerAdLoaded = false
        }
        
        func bannerViewWillPresentScreen(_ bannerView: BannerView) {
            print("SwiftUI BannerAdView: Ad will present screen.")
        }

        func bannerViewDidDismissScreen(_ bannerView: BannerView) {
            print("SwiftUI BannerAdView: Ad did dismiss screen.")
        }
    }
}