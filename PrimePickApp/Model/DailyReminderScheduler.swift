//
//  DailyReminderScheduler.swift
//  PrimePickApp
//

import Foundation
import QuizCore
import UserNotifications

/// リマインドの予約先。アプリでは `UNUserNotificationCenter`、テストでは記録するだけの偽物に差し替える
protocol DailyReminderNotificationCenter {
    /// 予約中の通知の識別子
    func pendingRequestIdentifiers() async -> [String]
    /// 届いて通知センターに残っている通知の識別子
    func deliveredNotificationIdentifiers() async -> [String]
    func removePendingRequests(withIdentifiers identifiers: [String])
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
    func add(_ request: UNNotificationRequest) async throws
}

/// `UNUserNotificationCenter.current()` に予約する `DailyReminderNotificationCenter`
struct SystemDailyReminderNotificationCenter: DailyReminderNotificationCenter {
    private var center: UNUserNotificationCenter { .current() }

    func pendingRequestIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }

    func deliveredNotificationIdentifiers() async -> [String] {
        await center.deliveredNotifications().map(\.request.identifier)
    }

    func removePendingRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }
}

/// デイリーのリマインドを予約し直す
///
/// 予約し直すのは、アプリが前面に戻ったとき（最後に開いた日も今日にする）・デイリーを解き終えたとき・設定を変えたとき。
/// 予約し直すときは、このアプリが予約したリマインド（`DailyReminderNotification.identifierPrefix` で始まるもの）を全部消してから
/// `DailyReminderPlanner` の求めた分を入れ直すので、前の予約が残って二重に届くことはない。
/// 続けて呼ばれても前の組み直しが終わってから次を始め、古い予約が後から入り込まないようにする。撮影モードでは予約しない。
final class DailyReminderScheduler: @unchecked Sendable {
    static let shared = DailyReminderScheduler()

    private let center: any DailyReminderNotificationCenter
    private let settingsStore: DailyReminderSettingsStore
    private let challengeStore: any DailyChallengeStore
    private let now: () -> Date
    private let timeZone: () -> TimeZone
    /// false なら予約も取り消しもしない（撮影モード）
    private let isActive: Bool

    private let lock = NSLock()
    /// 最後に始めた組み直し。次の組み直しはこれが終わってから始める
    private var lastTask: Task<Void, Never>?

    init(
        center: any DailyReminderNotificationCenter = SystemDailyReminderNotificationCenter(),
        settingsStore: DailyReminderSettingsStore = DailyReminderSettingsStore(),
        challengeStore: any DailyChallengeStore = UserDefaultsDailyChallengeStore(),
        now: @escaping () -> Date = Date.init,
        timeZone: @escaping () -> TimeZone = { .current },
        isActive: Bool = !ScreenshotDemo.isEnabled
    ) {
        self.center = center
        self.settingsStore = settingsStore
        self.challengeStore = challengeStore
        self.now = now
        self.timeZone = timeZone
        self.isActive = isActive
    }

    /// アプリが前面に戻ったとき。最後に開いた日を今日にしてから予約し直す
    @discardableResult
    func appDidBecomeActive() -> Task<Void, Never> {
        guard isActive else { return Task {} }
        let today = DailyChallengeDay.today(now: now(), timeZone: timeZone())
        settingsStore.update { $0.lastOpenedDay = today }
        return reschedule()
    }

    /// 設定を書き換えて保存し、予約し直す（設定画面・結果画面の案内から使う）
    @discardableResult
    func updateSettings(_ change: (inout DailyReminderSettings) -> Void) -> Task<Void, Never> {
        settingsStore.update(change)
        return reschedule()
    }

    /// 今の設定と記録で予約し直す。返した `Task` は組み直しが終わると終わる
    @discardableResult
    func reschedule() -> Task<Void, Never> {
        guard isActive else { return Task {} }
        lock.lock()
        defer { lock.unlock() }
        let previous = lastTask
        let task = Task { [self] in
            await previous?.value
            await performReschedule()
        }
        lastTask = task
        return task
    }

    /// アプリが前面にあるときに届いたリマインドの見せ方
    ///
    /// その日のデイリーにもう手を付けていれば出さない（予約したあとに解いた場合）。
    /// まだなら、遊んでいる最中の邪魔にならないよう音は鳴らさず、バナーと通知センターにだけ出す。
    /// このアプリのリマインドでない通知と撮影モードでは出さない（delegate を置く前と同じ）。
    func foregroundPresentationOptions(forIdentifier identifier: String) -> UNNotificationPresentationOptions {
        guard isActive, let day = DailyReminderNotification.day(fromIdentifier: identifier) else { return [] }
        guard challengeStore.record(dayKey: day.dayKey) == nil else { return [] }
        return [.banner, .list]
    }

    /// 予約する通知の中身
    static func request(for notification: DailyReminderNotification) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        content.userInfo = [DailyReminderTap.daysAheadKey: notification.daysAhead]
        let trigger = UNCalendarNotificationTrigger(dateMatching: notification.dateComponents, repeats: false)
        return UNNotificationRequest(identifier: notification.identifier, content: content, trigger: trigger)
    }

    private func performReschedule() async {
        let settings = settingsStore.load()
        let records = challengeStore.allRecords()
        let notifications = DailyReminderPlanner.notifications(
            settings: settings,
            records: records,
            now: now(),
            timeZone: timeZone()
        )

        let pendingReminders = await center.pendingRequestIdentifiers()
            .filter { $0.hasPrefix(DailyReminderNotification.identifierPrefix) }
        if !pendingReminders.isEmpty {
            center.removePendingRequests(withIdentifiers: pendingReminders)
        }

        // 届いて通知センターに残っているリマインドのうち、もう手を付けた日の分は消す
        let playedDayKeys = Set(records.map(\.dayKey))
        let staleDelivered = await center.deliveredNotificationIdentifiers().filter { identifier in
            DailyReminderNotification.day(fromIdentifier: identifier).map { playedDayKeys.contains($0.dayKey) } ?? false
        }
        if !staleDelivered.isEmpty {
            center.removeDeliveredNotifications(withIdentifiers: staleDelivered)
        }

        for notification in notifications {
            do {
                try await center.add(Self.request(for: notification))
            } catch {
                print("リマインドを予約できませんでした: \(notification.identifier) \(error)")
            }
        }
    }
}

/// タップされたリマインド
struct DailyReminderTap: Equatable {
    /// 予約した日から何日後の分かを入れる `userInfo` のキー
    static let daysAheadKey = "daysAhead"

    /// どの日のデイリーを知らせたか
    let day: DailyChallengeDay
    /// 予約した日から何日後の分か（翌日分は 1）。読めなければ nil
    let daysAhead: Int?

    /// このアプリのリマインドでなければ nil
    init?(identifier: String, userInfo: [AnyHashable: Any]) {
        guard let day = DailyReminderNotification.day(fromIdentifier: identifier) else { return nil }
        self.day = day
        daysAhead = userInfo[Self.daysAheadKey] as? Int
    }
}

/// タップされたリマインドを `MainView` に渡す
///
/// 停止中からの起動では、`MainView` ができる前に届くことがあるので、`MainView` が受け取るまで持っておく。
@MainActor
final class DailyReminderRouter: ObservableObject {
    static let shared = DailyReminderRouter()

    /// まだ画面を開いていないタップ
    @Published private(set) var pendingTap: DailyReminderTap?

    func open(_ tap: DailyReminderTap) {
        pendingTap = tap
    }

    /// 受け取ったタップを返して空にする
    @discardableResult
    func consume() -> DailyReminderTap? {
        defer { pendingTap = nil }
        return pendingTap
    }
}
