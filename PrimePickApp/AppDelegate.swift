//
//  AppDelegate.swift
//  PrimePickApp
//

import FirebaseCore
import UIKit
import UserNotifications

/// 起動時の初期化（Firebase・日付の無い旧形式の自己ベストの削除・通知の delegate）を行う AppDelegate。`@UIApplicationDelegateAdaptor` から参照する
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureFirebase()
        TimeAttackRecordStore().removeLegacyBestScores()
        // 停止中にリマインドをタップして起動したときも受け取れるよう、起動を終える前に置く
        UNUserNotificationCenter.current().delegate = self
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

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// アプリが前面にあるときに届いたリマインドの見せ方は `DailyReminderScheduler.foregroundPresentationOptions` で決める
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler(
            DailyReminderScheduler.shared.foregroundPresentationOptions(forIdentifier: notification.request.identifier)
        )
    }

    /// リマインドをタップしたら、デイリーチャレンジの画面を開く
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let request = response.notification.request
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier,
              let tap = DailyReminderTap(identifier: request.identifier, userInfo: request.content.userInfo) else {
            completionHandler()
            return
        }
        Task { @MainActor in
            DailyReminderRouter.shared.open(tap)
            completionHandler()
        }
    }
}
