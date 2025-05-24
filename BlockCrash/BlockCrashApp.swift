//
//  BlockCrashApp.swift
//  BlockCrash
//
//  Created by Kerem Türközü on 28.04.2025.
//

import SwiftUI
import GoogleMobileAds // Google Mobile Ads SDK'sını içe aktar
import AppTrackingTransparency // Eklendi
import AdSupport // Eklendi

@main
struct BlockCrashApp: App {
    // AppDelegate'i SwiftUI yaşam döngüsüne bağla
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // AdManager'ı uygulama yaşam döngüsüne dahil etmek için @StateObject veya init() kullanabiliriz.
    // Singleton kullandığımız için, AdManager.shared üzerinden erişeceğiz ve başlatılması init() içinde olacak.
    
    init() {
        // Google Mobile Ads SDK'sını başlat
        MobileAds.shared.start(completionHandler: nil)
        
        // AdManager'ı (ve dolayısıyla reklam yüklemelerini) başlat
        // AdManager.shared zaten init metodunda reklamları yüklemeye çalışacak.
        // Bu satır sadece singleton'ın erken başlatılmasını garantiler (opsiyonel ama iyi bir pratik).
        let _ = AdManager.shared
        
        // Uygulama başlar başlamaz IDFA iznini iste - BURASI KALDIRILACAK veya YORUM SATIRI YAPILACAK
        // requestIDFAPermission()
    }

    var body: some Scene {
        WindowGroup {
            WelcomeView()
        }
    }
    
    // Bu fonksiyon WelcomeView'a taşınacak veya oradan çağrılacak şekilde düzenlenecek.
    // func requestIDFAPermission() { ... }
}
