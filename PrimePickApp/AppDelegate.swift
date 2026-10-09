//
//  AppDelegate.swift
//  PrimePickApp
//

import FirebaseCore
import UIKit

/// 起動時の初期化（Firebase・日付の無い旧形式の自己ベストの削除）を行う AppDelegate。`@UIApplicationDelegateAdaptor` から参照する
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureFirebase()
        TimeAttackRecordStore().removeLegacyBestScores()
        return true
    }

    /// `GoogleService-Info.plist` が無い状態で `FirebaseApp.configure()` を呼ぶとクラッシュするため、
    /// 存在を確認してから初期化する
    private func configureFirebase() {
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            print("GoogleService-Info.plist が見つからないため Firebase を初期化しません")
            return
        }
        FirebaseApp.configure()
    }
}
