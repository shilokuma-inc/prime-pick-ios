//
//  DailyReminderAnalyticsEventTests.swift
//  PrimePickAppTests
//

import XCTest
import QuizCore
import UserNotifications
@testable import PrimePickApp

@MainActor
final class DailyReminderAnalyticsEventTests: XCTestCase {

    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var settingsStore: DailyReminderSettingsStore!
    private var authorizer: AnalyticsFakeAuthorizer!
    private var events: [DailyReminderAnalyticsEvent] = []

    override func setUp() {
        super.setUp()
        suiteName = "DailyReminderAnalyticsEventTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        settingsStore = DailyReminderSettingsStore(userDefaults: userDefaults)
        authorizer = AnalyticsFakeAuthorizer()
        events = []
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - イベントの形

    func testToggleEvent() {
        let on = DailyReminderAnalyticsEvent.toggle(isEnabled: true, source: .settings)
        XCTAssertEqual(on.name, "daily_reminder_toggle")
        XCTAssertEqual(on.parameters.count, 2)
        XCTAssertEqual(on.parameters["enabled"] as? Int, 1)
        XCTAssertEqual(on.parameters["source"] as? String, "settings")

        let off = DailyReminderAnalyticsEvent.toggle(isEnabled: false, source: .dailyResult)
        XCTAssertEqual(off.parameters["enabled"] as? Int, 0)
        XCTAssertEqual(off.parameters["source"] as? String, "daily_result")

        let auto = DailyReminderAnalyticsEvent.toggle(isEnabled: false, source: .systemSettings)
        XCTAssertEqual(auto.parameters["source"] as? String, "system_settings")
    }

    func testTimeChangeEvent() {
        let event = DailyReminderAnalyticsEvent.timeChange(hour: 7, minute: 30)
        XCTAssertEqual(event.name, "daily_reminder_time_change")
        XCTAssertEqual(event.parameters.count, 2)
        XCTAssertEqual(event.parameters["hour"] as? Int, 7)
        XCTAssertEqual(event.parameters["minute"] as? Int, 30)
    }

    func testPermissionResultEvent() {
        let granted = DailyReminderAnalyticsEvent.permissionResult(granted: true, source: .dailyResult)
        XCTAssertEqual(granted.name, "daily_reminder_permission")
        XCTAssertEqual(granted.parameters.count, 2)
        XCTAssertEqual(granted.parameters["result"] as? String, "granted")
        XCTAssertEqual(granted.parameters["source"] as? String, "daily_result")

        let denied = DailyReminderAnalyticsEvent.permissionResult(granted: false, source: .settings)
        XCTAssertEqual(denied.parameters["result"] as? String, "denied")
        XCTAssertEqual(denied.parameters["source"] as? String, "settings")
    }

    func testPromptEvents() {
        XCTAssertEqual(DailyReminderAnalyticsEvent.promptShow.name, "daily_reminder_prompt_show")
        XCTAssertTrue(DailyReminderAnalyticsEvent.promptShow.parameters.isEmpty)

        let turnOn = DailyReminderAnalyticsEvent.promptAction(.turnOn)
        XCTAssertEqual(turnOn.name, "daily_reminder_prompt_action")
        XCTAssertEqual(turnOn.parameters.count, 1)
        XCTAssertEqual(turnOn.parameters["action"] as? String, "turn_on")
        XCTAssertEqual(DailyReminderAnalyticsEvent.promptAction(.notNow).parameters["action"] as? String, "not_now")
    }

    /// 翌日分か、それ以降の分か（予約した日の分も含む）と、予約から何日後かを送る
    func testNotificationTapEvent() {
        let nextDay = DailyReminderAnalyticsEvent.notificationTap(dayNumber: 30, daysAhead: 1)
        XCTAssertEqual(nextDay.name, "daily_reminder_tap")
        XCTAssertEqual(nextDay.parameters.count, 3)
        XCTAssertEqual(nextDay.parameters["day_number"] as? Int, 30)
        XCTAssertEqual(nextDay.parameters["notification_kind"] as? String, "next_day")
        XCTAssertEqual(nextDay.parameters["days_ahead"] as? Int, 1)

        let sameDay = DailyReminderAnalyticsEvent.notificationTap(dayNumber: 30, daysAhead: 0)
        XCTAssertEqual(sameDay.parameters["notification_kind"] as? String, "same_day")
        XCTAssertEqual(sameDay.parameters["days_ahead"] as? Int, 0)

        let later = DailyReminderAnalyticsEvent.notificationTap(dayNumber: 30, daysAhead: 5)
        XCTAssertEqual(later.parameters["notification_kind"] as? String, "later")
        XCTAssertEqual(later.parameters["days_ahead"] as? Int, 5)

        // 何日後かが読めなければ、days_ahead は送らない（Firebase に nil は渡せない）
        let unknown = DailyReminderAnalyticsEvent.notificationTap(dayNumber: 30, daysAhead: nil)
        XCTAssertEqual(unknown.parameters.count, 2)
        XCTAssertEqual(unknown.parameters["notification_kind"] as? String, "unknown")
        XCTAssertNil(unknown.parameters["days_ahead"])
    }

    /// タップされた通知の識別子と userInfo から作る
    func testNotificationTapEventFromTap() throws {
        let day = DailyChallengeDay(year: 2026, month: 11, day: 24)
        let tap = try XCTUnwrap(DailyReminderTap(
            identifier: DailyReminderNotification.identifier(for: day),
            userInfo: [DailyReminderTap.daysAheadKey: 3]
        ))
        XCTAssertEqual(
            DailyReminderAnalyticsEvent(tap: tap),
            .notificationTap(dayNumber: day.dayNumber, daysAhead: 3)
        )
    }

    /// Firebase の制約: 値は文字列か数値、名前は 40 文字以内、文字列の値は 100 文字以内
    func testAllEventsFollowFirebaseConstraints() {
        let all: [DailyReminderAnalyticsEvent] = [
            .toggle(isEnabled: true, source: .settings),
            .toggle(isEnabled: false, source: .systemSettings),
            .timeChange(hour: 23, minute: 59),
            .permissionResult(granted: true, source: .dailyResult),
            .promptShow,
            .promptAction(.turnOn),
            .promptAction(.notNow),
            .notificationTap(dayNumber: 1, daysAhead: 7),
            .notificationTap(dayNumber: 1, daysAhead: nil)
        ]
        for event in all {
            XCTAssertLessThanOrEqual(event.name.count, 40, event.name)
            for (key, value) in event.parameters {
                XCTAssertLessThanOrEqual(key.count, 40, key)
                if let string = value as? String {
                    XCTAssertLessThanOrEqual(string.count, 100)
                } else {
                    XCTAssertTrue(value is Int || value is Double, "\(event.name).\(key) は文字列でも数値でもない")
                }
            }
        }
    }

    // MARK: - 設定画面から送るタイミング

    /// 未確定からオンにして許可されたら、許可の結果とオンを settings として送る
    func testSettingsEnableGrantedSendsPermissionAndToggle() async {
        authorizer.status = .notDetermined
        authorizer.grants = true
        let model = makeSettingsModel()

        await model.setEnabled(true)

        XCTAssertEqual(events, [
            .permissionResult(granted: true, source: .settings),
            .toggle(isEnabled: true, source: .settings)
        ])
    }

    /// 許可されなければ、許可の結果だけを送る（オフのままなのでオン／オフは送らない）
    func testSettingsEnableRefusedSendsOnlyPermission() async {
        authorizer.status = .notDetermined
        authorizer.grants = false
        let model = makeSettingsModel()

        await model.setEnabled(true)

        XCTAssertEqual(events, [.permissionResult(granted: false, source: .settings)])
    }

    /// 許可済み・拒否済みならダイアログを出さないので、許可の結果は送らない
    func testSettingsEnableWithoutDialogSendsNoPermission() async {
        authorizer.status = .authorized
        let model = makeSettingsModel()
        await model.setEnabled(true)
        XCTAssertEqual(events, [.toggle(isEnabled: true, source: .settings)])

        events = []
        await model.setEnabled(false)
        XCTAssertEqual(events, [.toggle(isEnabled: false, source: .settings)])

        events = []
        authorizer.status = .denied
        await model.setEnabled(true)
        XCTAssertEqual(events, [])
    }

    /// 変わらないオフを選び直しても送らない
    func testSettingsDisableWhenAlreadyOffSendsNothing() async {
        let model = makeSettingsModel()
        await model.setEnabled(false)
        XCTAssertEqual(events, [])
    }

    func testSettingsTimeChangeSendsHourAndMinute() async throws {
        let model = makeSettingsModel()

        await model.setTime(try XCTUnwrap(DailyReminderTime(hour: 7, minute: 30)))
        // 同じ時刻を選び直しても送らない
        await model.setTime(try XCTUnwrap(DailyReminderTime(hour: 7, minute: 30)))

        XCTAssertEqual(events, [.timeChange(hour: 7, minute: 30)])
    }

    /// 設定アプリで通知を止められていてオフに戻したときは system_settings として送る
    func testRefreshTurningOffSendsSystemSettingsToggle() async {
        settingsStore.update { $0.isEnabled = true }
        authorizer.status = .denied
        let model = makeSettingsModel()

        await model.refresh()

        XCTAssertEqual(events, [.toggle(isEnabled: false, source: .systemSettings)])
    }

    func testRefreshWithoutChangeSendsNothing() async {
        settingsStore.update { $0.isEnabled = true }
        authorizer.status = .authorized
        let model = makeSettingsModel()

        await model.refresh()

        XCTAssertEqual(events, [])
    }

    // MARK: - 結果画面の案内から送るタイミング

    /// 出したことは 1 回だけ送る
    func testPromptShowSentOnce() {
        let model = makePromptModel()

        model.didAppear()
        model.didAppear()

        XCTAssertEqual(events, [.promptShow])
    }

    /// 出さないときは送らない
    func testPromptShowNotSentWhenHidden() {
        makePromptModel(isJustFinished: false).didAppear()
        makePromptModel(isScreenshotDemo: true).didAppear()
        XCTAssertEqual(events, [])
    }

    /// 「オンにする」→ 許可の結果とオンを daily_result として送る
    func testPromptTurnOnGrantedSendsDailyResultEvents() async {
        authorizer.status = .notDetermined
        authorizer.grants = true
        let model = makePromptModel()
        model.didAppear()

        await model.enable()

        XCTAssertEqual(events, [
            .promptShow,
            .promptAction(.turnOn),
            .permissionResult(granted: true, source: .dailyResult),
            .toggle(isEnabled: true, source: .dailyResult)
        ])
    }

    func testPromptTurnOnRefusedSendsDeniedPermission() async {
        authorizer.status = .notDetermined
        authorizer.grants = false
        let model = makePromptModel()

        await model.enable()

        XCTAssertEqual(events, [
            .promptAction(.turnOn),
            .permissionResult(granted: false, source: .dailyResult)
        ])
    }

    func testPromptNotNowSendsAction() async {
        let model = makePromptModel()

        model.decline()
        // 選んだ後に押しても送らない
        await model.enable()
        model.decline()

        XCTAssertEqual(events, [.promptAction(.notNow)])
    }

    // MARK: - Helpers

    private func makeScheduler(isActive: Bool = true) -> DailyReminderScheduler {
        DailyReminderScheduler(
            center: AnalyticsRecordingNotificationCenter(),
            settingsStore: settingsStore,
            challengeStore: UserDefaultsDailyChallengeStore(userDefaults: userDefaults),
            now: { Date(timeIntervalSince1970: 1_790_000_000) },
            timeZone: { [tokyo] in tokyo },
            isActive: isActive
        )
    }

    private func makeSettingsModel() -> DailyReminderSettingsModel {
        DailyReminderSettingsModel(
            settingsStore: settingsStore,
            scheduler: makeScheduler(),
            authorizer: authorizer,
            sendAnalytics: { [weak self] in self?.events.append($0) }
        )
    }

    private func makePromptModel(isJustFinished: Bool = true, isScreenshotDemo: Bool = false) -> DailyReminderPromptModel {
        DailyReminderPromptModel(
            isJustFinished: isJustFinished,
            settingsStore: settingsStore,
            scheduler: makeScheduler(isActive: !isScreenshotDemo),
            authorizer: authorizer,
            isScreenshotDemo: isScreenshotDemo,
            sendAnalytics: { [weak self] in self?.events.append($0) }
        )
    }
}

/// 許可の状態を決めておく `DailyReminderAuthorizing`
private final class AnalyticsFakeAuthorizer: DailyReminderAuthorizing, @unchecked Sendable {
    var status: DailyReminderAuthorizationStatus = .notDetermined
    /// 許可ダイアログで許可するか
    var grants = true

    func authorizationStatus() async -> DailyReminderAuthorizationStatus {
        status
    }

    func requestAuthorization() async -> Bool {
        status = grants ? .authorized : .denied
        return grants
    }
}

/// 予約を記録するだけの `DailyReminderNotificationCenter`
private final class AnalyticsRecordingNotificationCenter: DailyReminderNotificationCenter, @unchecked Sendable {
    private let lock = NSLock()
    private var identifiers: [String] = []

    func pendingRequestIdentifiers() async -> [String] {
        lock.withLock { identifiers }
    }

    func deliveredNotificationIdentifiers() async -> [String] {
        []
    }

    func removePendingRequests(withIdentifiers removing: [String]) {
        lock.withLock { identifiers.removeAll { removing.contains($0) } }
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}

    func add(_ request: UNNotificationRequest) async throws {
        lock.withLock {
            identifiers.removeAll { $0 == request.identifier }
            identifiers.append(request.identifier)
        }
    }
}
