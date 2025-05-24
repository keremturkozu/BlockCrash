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
    fileprivate let bannerAdUnitID: String = "ca-app-pub-3940256099942544/2934735716" // Test Banner ID
    private let interstitialAdUnitID: String = "ca-app-pub-3940256099942544/4411468910" // Test Interstitial ID
    
    // Test cihazı ID'si - kendi cihazınızın IDFA'sını buraya ekleyin
    private let testDeviceID: String = "YOUR_TEST_DEVICE_ID" // Bu değeri kendi test cihazınızla değiştirin

    // "Reklamları Kaldır" ürününün kimliği (App Store Connect\'te tanımlanacak)
    private let removeAdsProductID: String = "com.yourbundleid.removeads" // Kendi ürün ID\'nizle değiştirin

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
        
        // Test cihazı yapılandırması
        configureTestDevice()
        
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

    // MARK: - Test Device Configuration
    private func configureTestDevice() {
        print("AdManager: Configuring test device")
        // Test cihazı ekle - GADMobileAds SDK için doğru yöntem
        // Test cihazı ID'si elde etmek için uygulama konsolunu kontrol edin
        print("AdManager: Test device configuration is handled automatically in debug builds")
        print("AdManager: For production, add your device's IDFA to test device list")
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
        
        if rootVC.presentedViewController != nil {
            print("AdManager: Root view controller is already presenting another view controller: \(String(describing: rootVC.presentedViewController))")
            print("AdManager: Attempting to dismiss presented view controller first...")
            
            // Mevcut presented view controller'ı dismiss et
            rootVC.dismiss(animated: false) {
                print("AdManager: Dismissed presented view controller, now showing interstitial")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.presentInterstitial(ad: ad, from: rootVC, completion: completion)
                }
            }
            return
        }

        print("AdManager: All checks passed, attempting to present interstitial ad.")
        presentInterstitial(ad: ad, from: rootVC, completion: completion)
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
        // TODO: Gerçek StoreKit implementasyonu için bu kısmı değiştirin
        
        // ⚠️ TEST VERSİYONU - Gerçek satın alma olmadan reklamları kaldırır
        print("🧪 TEST MODE: Removing ads without purchase (for testing)")
        self.adsRemoved = true
        
        // Banner ve interstitial reklamları temizle
        self.interstitialAd = nil
        self.interstitialAdLoaded = false
        
        print("✅ Ads removed successfully (TEST MODE)")
        
        // TODO: Production için StoreKit implementasyonu:
        // 1. SKProductsRequest ile ürünü çek
        // 2. SKPayment ile satın alma başlat  
        // 3. SKPaymentTransactionObserver ile sonucu dinle
        // 4. Başarılı olursa adsRemoved = true yap
    }
    
    func restorePurchases() {
        print("🔄 restorePurchases() called")
        // TODO: Gerçek StoreKit implementasyonu için bu kısmı değiştirin
        
        // ⚠️ TEST VERSİYONU - Reklamları geri yükler (test için)
        print("🧪 TEST MODE: Simulating purchase restore")
        
        // Test için: Her restore'da reklamları kapat
        self.adsRemoved = true
        self.interstitialAd = nil
        self.interstitialAdLoaded = false
        
        print("✅ Purchases restored, ads removed (TEST MODE)")
        
        // TODO: Production için StoreKit implementasyonu:
        // 1. SKReceiptRefreshRequest ile receipt'i yenile
        // 2. Satın almaları kontrol et
        // 3. "Remove Ads" ürünü bulunursa adsRemoved = true yap
    }

    // MARK: - Continue Methods
    
    func showContinueAd(completion: @escaping () -> Void) {
        print("🎬 showContinueAd() called")
        
        // ⚠️ HIZLI TEST VERSİYONU - Reklam olmadan direkt continue
        print("🧪 FAST TEST MODE: Completing continue ad immediately")
        DispatchQueue.main.async {
            completion()
        }
    }
    
    func purchaseContinue(completion: @escaping () -> Void) {
        print("💰 purchaseContinue() called")
        
        // ⚠️ HIZLI TEST VERSİYONU - Alert olmadan direkt continue
        print("🧪 FAST TEST MODE: Completing continue purchase immediately")
        DispatchQueue.main.async {
            completion()
        }
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
        // `showInterstitialAd` çağrıldığı yerdeki completion handler bu durumu yönetmeli.
        // Ancak `showInterstitialAd`'in completion'ı `adDidDismissFullScreenContent`'a bağlandı.
        // Bu yüzden burada da `pendingCompletionForInterstitial`'ı çağırabiliriz.
        executePendingInterstitialCompletion()
        print("AdManager: Attempting to load new interstitial ad after failure...")
        loadInterstitialAd() // Bir sonraki için yüklemeyi dene
    }

    // Reklam kapatıldığında çağrılır.
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("AdManager: ✅ adDidDismissFullScreenContent - Interstitial ad was dismissed.")
        
        // %20 ihtimalle "Remove Ads?" sorusu göster
        if !adsRemoved && Int.random(in: 1...100) <= 20 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showRemoveAdsPrompt()
            }
        }
        
        // Kullanıcı reklamı kapattıktan sonra completion'ı çağır.
        executePendingInterstitialCompletion()
        self.interstitialAd = nil // Reklamı temizle
        print("AdManager: Cleared interstitial ad, loading new one...")
        loadInterstitialAd()     // Bir sonraki reklamı yükle
    }
    
    private func showRemoveAdsPrompt() {
        guard let rootVC = rootViewController else { return }
        print("AdManager: 📢 Showing Remove Ads prompt after interstitial")
        
        let alert = UIAlertController(
            title: "Enjoy Ad-Free Gaming! 🎮",
            message: "Remove ads forever and focus on beating your high score!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Remove Ads", style: .default) { _ in
            print("User chose to remove ads from prompt")
            self.purchaseRemoveAds()
        })
        
        alert.addAction(UIAlertAction(title: "Maybe Later", style: .cancel) { _ in
            print("User dismissed remove ads prompt")
        })
        
        rootVC.present(alert, animated: true)
    }

    private var pendingInterstitialCompletion: (() -> Void)?

    // `showInterstitialAd` içinde bu atanacak
    private func setPendingInterstitialCompletion(_ completion: (() -> Void)?) {
        self.pendingInterstitialCompletion = completion
    }

    private func executePendingInterstitialCompletion() {
        DispatchQueue.main.async {
            self.pendingInterstitialCompletion?()
            self.pendingInterstitialCompletion = nil // Tekrar çağrılmasını önle
        }
    }
}

// MARK: - SwiftUI Banner Ad View
// GADBannerView\'ı SwiftUI\'da kullanmak için bir wrapper.
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
            // Fallback rootViewController (UIApplication.shared.windows) kaldırıldı.
        }
        
        bannerView.delegate = context.coordinator
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        // SwiftUI durumu değiştikçe (örneğin adsRemoved) banner\'ı güncellemek gerekebilir.
        // Eğer reklamlar kaldırıldıysa banner\'ı gizleyebilir veya kaldırabiliriz.
        // Ancak bu örnekte, banner\'ın kendi kendine yüklenmesini sağlıyoruz.
        // Eğer adsRemoved true ise, BannerAdView\'ı hiç göstermemeyi tercih edebiliriz.
    }
    
    // Coordinator, UIViewRepresentable ile UIKit delegate\'lerini yönetmek için kullanılır.
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
