//
//  DailyReminderSettingsModelTests.swift
//  PrimePickAppTests
//

import XCTest
import QuizCore
import UserNotifications
@testable import PrimePickApp

@MainActor
final class DailyReminderSettingsModelTests: XCTestCase {

    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var settingsStore: DailyReminderSettingsStore!
    private var center: RecordingNotificationCenter!
    private var authorizer: FakeAuthorizer!

    override func setUp() {
        super.setUp()
        suiteName = "DailyReminderSettingsModelTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        settingsStore = DailyReminderSettingsStore(userDefaults: userDefaults)
        center = RecordingNotificationCenter()
        authorizer = FakeAuthorizer()
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - 初期状態

    func testInitialStateIsOffAt2000() async {
        let model = makeModel()
        await model.refresh()

        XCTAssertFalse(model.isEnabled)
        XCTAssertEqual(model.time, DailyReminderTime.defaultTime)
        XCTAssertEqual(authorizer.requestCount, 0)
        XCTAssertFalse(model.isAuthorizationDenied)
        XCTAssertEqual(center.pendingIdentifiers, [])
    }

    // MARK: - オンにする

    /// 許可が未確定なら許可を求め、許可されたらオンにして予約する
    func testEnableRequestsAuthorizationWhenNotDetermined() async {
        authorizer.status = .notDetermined
        authorizer.grants = true
        let model = makeModel()

        await model.setEnabled(true)

        XCTAssertEqual(authorizer.requestCount, 1)
        XCTAssertTrue(model.isEnabled)
        XCTAssertFalse(model.isRequestingAuthorization)
        XCTAssertTrue(settingsStore.load().isEnabled)
        XCTAssertTrue(settingsStore.load().hasRequestedAuthorization)
        XCTAssertFalse(center.pendingIdentifiers.isEmpty)
        XCTAssertTrue(center.pendingIdentifiers.allSatisfy { $0.hasPrefix(DailyReminderNotification.identifierPrefix) })
    }

    /// 許可されなければオフに戻し、設定アプリへ案内する
    func testEnableRevertsWhenAuthorizationRefused() async {
        authorizer.status = .notDetermined
        authorizer.grants = false
        let model = makeModel()

        await model.setEnabled(true)

        XCTAssertEqual(authorizer.requestCount, 1)
        XCTAssertFalse(model.isEnabled)
        XCTAssertFalse(settingsStore.load().isEnabled)
        XCTAssertTrue(settingsStore.load().hasRequestedAuthorization)
        XCTAssertTrue(model.isAuthorizationDenied)
        XCTAssertEqual(center.pendingIdentifiers, [])
    }

    /// 許可済みならダイアログを出さずにオンにする
    func testEnableWithoutRequestWhenAlreadyAuthorized() async {
        authorizer.status = .authorized
        let model = makeModel()

        await model.setEnabled(true)

        XCTAssertEqual(authorizer.requestCount, 0)
        XCTAssertTrue(model.isEnabled)
        XCTAssertTrue(settingsStore.load().isEnabled)
    }

    /// 拒否済みならダイアログは出せないので、オフのまま設定アプリへ案内する
    func testEnableStaysOffWhenDenied() async {
        authorizer.status = .denied
        let model = makeModel()

        await model.setEnabled(true)

        XCTAssertEqual(authorizer.requestCount, 0)
        XCTAssertFalse(model.isEnabled)
        XCTAssertFalse(settingsStore.load().isEnabled)
        XCTAssertTrue(model.isAuthorizationDenied)
    }

    // MARK: - オフにする・時刻

    func testDisableRemovesReminders() async {
        authorizer.status = .authorized
        let model = makeModel()
        await model.setEnabled(true)

        await model.setEnabled(false)

        XCTAssertFalse(model.isEnabled)
        XCTAssertFalse(settingsStore.load().isEnabled)
        XCTAssertEqual(center.pendingIdentifiers, [])
    }

    /// 時刻を変えたら保存し、新しい時刻で予約し直す（前の予約は残らない）
    func testSetTimeSavesAndReschedules() async throws {
        authorizer.status = .authorized
        let model = makeModel()
        await model.setEnabled(true)
        let countBefore = center.pendingIdentifiers.count

        let newTime = try XCTUnwrap(DailyReminderTime(hour: 7, minute: 30))
        await model.setTime(newTime)

        XCTAssertEqual(model.time, newTime)
        XCTAssertEqual(settingsStore.load().time, newTime)
        XCTAssertEqual(center.pendingIdentifiers.count, countBefore)
        XCTAssertEqual(Set(center.pendingIdentifiers).count, center.pendingIdentifiers.count)
        for request in center.pending {
            let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
            XCTAssertEqual(trigger.dateComponents.hour, 7)
            XCTAssertEqual(trigger.dateComponents.minute, 30)
        }
    }

    // MARK: - 読み直す

    /// 設定アプリで通知を止められていたら、開き直したときにオフに戻して予約を消す
    func testRefreshTurnsOffWhenDeniedInSettingsApp() async {
        authorizer.status = .authorized
        let model = makeModel()
        await model.setEnabled(true)

        authorizer.status = .denied
        await model.refresh()

        XCTAssertFalse(model.isEnabled)
        XCTAssertFalse(settingsStore.load().isEnabled)
        XCTAssertTrue(model.isAuthorizationDenied)
        XCTAssertEqual(center.pendingIdentifiers, [])
    }

    /// 設定アプリで許可されたら、案内を消す
    func testRefreshClearsDeniedGuidanceWhenAllowed() async {
        authorizer.status = .denied
        let model = makeModel()
        await model.refresh()
        XCTAssertTrue(model.isAuthorizationDenied)

        authorizer.status = .authorized
        await model.refresh()

        XCTAssertFalse(model.isAuthorizationDenied)
        XCTAssertFalse(model.isEnabled)
    }

    /// ほかの場所（結果画面の案内）で変えた設定を読み直す
    func testRefreshReadsSavedSettings() async throws {
        authorizer.status = .authorized
        let model = makeModel()
        let time = try XCTUnwrap(DailyReminderTime(hour: 21, minute: 15))
        settingsStore.update {
            $0.isEnabled = true
            $0.time = time
        }

        await model.refresh()

        XCTAssertTrue(model.isEnabled)
        XCTAssertEqual(model.time, time)
    }

    // MARK: - 許可の状態・時刻の変換

    func testAuthorizationStatusMapping() {
        XCTAssertEqual(DailyReminderAuthorizationStatus(.notDetermined), .notDetermined)
        XCTAssertEqual(DailyReminderAuthorizationStatus(.denied), .denied)
        XCTAssertEqual(DailyReminderAuthorizationStatus(.authorized), .authorized)
        XCTAssertEqual(DailyReminderAuthorizationStatus(.provisional), .authorized)
        XCTAssertEqual(DailyReminderAuthorizationStatus(.ephemeral), .authorized)
    }

    func testTimeRoundTripsThroughDate() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tokyo
        let time = try XCTUnwrap(DailyReminderTime(hour: 6, minute: 45))

        let date = time.date(calendar: calendar, now: Date(timeIntervalSince1970: 1_790_000_000))

        XCTAssertEqual(DailyReminderTime(date: date, calendar: calendar), time)
    }

    // MARK: - Helpers

    private func makeModel() -> DailyReminderSettingsModel {
        let scheduler = DailyReminderScheduler(
            center: center,
            settingsStore: settingsStore,
            challengeStore: UserDefaultsDailyChallengeStore(userDefaults: userDefaults),
            now: { Date(timeIntervalSince1970: 1_790_000_000) },
            timeZone: { [tokyo] in tokyo },
            isActive: true
        )
        return DailyReminderSettingsModel(settingsStore: settingsStore, scheduler: scheduler, authorizer: authorizer, sendAnalytics: { _ in })
    }
}

/// 許可の状態を決めておき、許可を求めた回数を数える `DailyReminderAuthorizing`
private final class FakeAuthorizer: DailyReminderAuthorizing, @unchecked Sendable {
    var status: DailyReminderAuthorizationStatus = .notDetermined
    /// 許可ダイアログで許可するか
    var grants = true
    private(set) var requestCount = 0

    func authorizationStatus() async -> DailyReminderAuthorizationStatus {
        status
    }

    func requestAuthorization() async -> Bool {
        requestCount += 1
        status = grants ? .authorized : .denied
        return grants
    }
}

/// 予約と取り消しを記録するだけの `DailyReminderNotificationCenter`
private final class RecordingNotificationCenter: DailyReminderNotificationCenter, @unchecked Sendable {
    private let lock = NSLock()
    private var _pending: [UNNotificationRequest] = []

    var pending: [UNNotificationRequest] {
        lock.withLock { _pending }
    }

    var pendingIdentifiers: [String] {
        pending.map(\.identifier)
    }

    func pendingRequestIdentifiers() async -> [String] {
        pendingIdentifiers
    }

    func deliveredNotificationIdentifiers() async -> [String] {
        []
    }

    func removePendingRequests(withIdentifiers identifiers: [String]) {
        lock.withLock { _pending.removeAll { identifiers.contains($0.identifier) } }
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}

    func add(_ request: UNNotificationRequest) async throws {
        lock.withLock {
            _pending.removeAll { $0.identifier == request.identifier }
            _pending.append(request)
        }
    }
}
