//
//  DailyReminderSettingsModel.swift
//  PrimePickApp
//

import Foundation
import UserNotifications

/// 通知の許可の状態（リマインドに要る分だけに丸めたもの）
enum DailyReminderAuthorizationStatus: Equatable {
    /// まだ許可ダイアログを出していない
    case notDetermined
    /// 許可されなかった（設定アプリで変えてもらうしかない）
    case denied
    /// 許可されている（仮の許可なども含む）
    case authorized

    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .denied:
            self = .denied
        default:
            self = .authorized
        }
    }
}

/// 通知の許可を読む・求める窓口。アプリでは `UNUserNotificationCenter`、テストでは偽物に差し替える
protocol DailyReminderAuthorizing {
    func authorizationStatus() async -> DailyReminderAuthorizationStatus
    /// OS の許可ダイアログを出し、許可されたかを返す
    func requestAuthorization() async -> Bool
}

/// `UNUserNotificationCenter.current()` で許可を読む・求める `DailyReminderAuthorizing`
struct SystemDailyReminderAuthorizer: DailyReminderAuthorizing {
    private var center: UNUserNotificationCenter { .current() }

    func authorizationStatus() async -> DailyReminderAuthorizationStatus {
        DailyReminderAuthorizationStatus(await center.notificationSettings().authorizationStatus)
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            print("通知の許可を求められませんでした: \(error)")
            return false
        }
    }
}

/// 設定画面の「リマインド」の項目
///
/// オンにしたとき、許可が未確定なら OS の許可ダイアログを出し、許可されなければオフに戻す。
/// 許可が拒否されているときは、設定アプリへ案内する（`isAuthorizationDenied`）。設定を変えたら予約を組み直す。
@MainActor
final class DailyReminderSettingsModel: ObservableObject {
    /// トグルに出すオン／オフ
    @Published private(set) var isEnabled: Bool
    @Published private(set) var time: DailyReminderTime
    @Published private(set) var authorizationStatus: DailyReminderAuthorizationStatus?
    /// 許可を求めている最中か（その間はトグルを触れなくする）
    @Published private(set) var isRequestingAuthorization = false

    private let settingsStore: DailyReminderSettingsStore
    private let scheduler: DailyReminderScheduler
    private let authorizer: any DailyReminderAuthorizing

    init(
        settingsStore: DailyReminderSettingsStore = DailyReminderSettingsStore(),
        scheduler: DailyReminderScheduler = .shared,
        authorizer: any DailyReminderAuthorizing = SystemDailyReminderAuthorizer()
    ) {
        self.settingsStore = settingsStore
        self.scheduler = scheduler
        self.authorizer = authorizer
        let settings = settingsStore.load()
        isEnabled = settings.isEnabled
        time = settings.time
    }

    /// 設定アプリへの案内を出すか
    var isAuthorizationDenied: Bool {
        authorizationStatus == .denied
    }

    /// 保存された設定と許可の状態を読み直す（画面を開いたとき・前面に戻ったとき）
    ///
    /// 設定アプリで通知を止められていたら、オンのままにせずオフに戻す。
    func refresh() async {
        let status = await authorizer.authorizationStatus()
        authorizationStatus = status
        let settings = settingsStore.load()
        time = settings.time
        if settings.isEnabled, status == .denied {
            await apply { $0.isEnabled = false }
        } else {
            isEnabled = settings.isEnabled
        }
    }

    /// トグルを切り替えたとき
    func setEnabled(_ enabled: Bool) async {
        guard enabled else {
            await apply { $0.isEnabled = false }
            return
        }
        guard !isRequestingAuthorization else { return }
        // 許可を待つ間もトグルはオンに見せ、許可されなければオフに戻す
        isEnabled = true
        isRequestingAuthorization = true
        defer { isRequestingAuthorization = false }

        var status = await authorizer.authorizationStatus()
        if status == .notDetermined {
            settingsStore.update { $0.hasRequestedAuthorization = true }
            _ = await authorizer.requestAuthorization()
            status = await authorizer.authorizationStatus()
        }
        authorizationStatus = status
        await apply { $0.isEnabled = status == .authorized }
    }

    /// 時刻を変えたとき
    func setTime(_ newTime: DailyReminderTime) async {
        guard newTime != time else { return }
        await apply { $0.time = newTime }
    }

    /// 設定を保存して予約を組み直し、画面の値を保存した値にそろえる
    private func apply(_ change: (inout DailyReminderSettings) -> Void) async {
        let task = scheduler.updateSettings(change)
        let settings = settingsStore.load()
        isEnabled = settings.isEnabled
        time = settings.time
        await task.value
    }
}

extension DailyReminderTime {
    /// `DatePicker` に渡す、今日のこの時刻
    func date(calendar: Calendar = .current, now: Date = Date()) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
    }

    /// `DatePicker` で選んだ日時の時・分
    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        self = DailyReminderTime(hour: components.hour ?? 0, minute: components.minute ?? 0) ?? .defaultTime
    }
}
