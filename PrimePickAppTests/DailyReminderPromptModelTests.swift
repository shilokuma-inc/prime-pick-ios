//
//  DailyReminderPromptModelTests.swift
//  PrimePickAppTests
//

import XCTest
import QuizCore
import UserNotifications
@testable import PrimePickApp

@MainActor
final class DailyReminderPromptModelTests: XCTestCase {

    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var settingsStore: DailyReminderSettingsStore!
    private var center: PromptRecordingNotificationCenter!
    private var authorizer: PromptFakeAuthorizer!

    override func setUp() {
        super.setUp()
        suiteName = "DailyReminderPromptModelTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        settingsStore = DailyReminderSettingsStore(userDefaults: userDefaults)
        center = PromptRecordingNotificationCenter()
        authorizer = PromptFakeAuthorizer()
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - 出すかどうか

    /// 解き終えた直後で、オフ・未案内・撮影モードでないときだけ出す
    func testShouldShowOnlyRightAfterFinishingWhenOffAndNotShown() {
        let initial = DailyReminderSettings()
        XCTAssertTrue(DailyReminderPromptModel.shouldShow(isJustFinished: true, settings: initial, isScreenshotDemo: false))
        XCTAssertFalse(DailyReminderPromptModel.shouldShow(isJustFinished: false, settings: initial, isScreenshotDemo: false))
        XCTAssertFalse(DailyReminderPromptModel.shouldShow(isJustFinished: true, settings: initial, isScreenshotDemo: true))

        var enabled = initial
        enabled.isEnabled = true
        XCTAssertFalse(DailyReminderPromptModel.shouldShow(isJustFinished: true, settings: enabled, isScreenshotDemo: false))

        var shown = initial
        shown.hasShownResultPrompt = true
        XCTAssertFalse(DailyReminderPromptModel.shouldShow(isJustFinished: true, settings: shown, isScreenshotDemo: false))
    }

    func testInitialStateAsksRightAfterFinishing() {
        let model = makeModel(isJustFinished: true)

        XCTAssertEqual(model.state, .asking)
        XCTAssertEqual(model.time, DailyReminderTime.defaultTime)
        // 出すだけでは許可を求めない
        XCTAssertEqual(authorizer.requestCount, 0)
    }

    /// 挑戦済みの日に開き直したときは出さない
    func testHiddenWhenReopened() {
        XCTAssertEqual(makeModel(isJustFinished: false).state, .hidden)
    }

    /// 撮影モードでは出さず、許可も求めない
    func testHiddenInScreenshotDemo() async {
        let model = makeModel(isJustFinished: true, isScreenshotDemo: true)

        XCTAssertEqual(model.state, .hidden)
        await model.enable()
        XCTAssertEqual(authorizer.requestCount, 0)
        XCTAssertFalse(settingsStore.load().isEnabled)
    }

    /// 出した時点で案内済みにし、次に解き終えたときは出さない
    func testShownOnlyOnce() {
        let model = makeModel(isJustFinished: true)
        model.didAppear()

        XCTAssertTrue(settingsStore.load().hasShownResultPrompt)
        XCTAssertEqual(makeModel(isJustFinished: true).state, .hidden)
    }

    // MARK: - オンにする

    /// 許可を求め、許可されたらオン（時刻は設定値）にして予約する
    func testEnableRequestsAuthorizationAndSchedules() async throws {
        authorizer.status = .notDetermined
        authorizer.grants = true
        let model = makeModel(isJustFinished: true)

        await model.enable()

        XCTAssertEqual(authorizer.requestCount, 1)
        XCTAssertEqual(model.state, .enabled(DailyReminderTime.defaultTime))
        let settings = settingsStore.load()
        XCTAssertTrue(settings.isEnabled)
        XCTAssertEqual(settings.time, DailyReminderTime.defaultTime)
        XCTAssertTrue(settings.hasShownResultPrompt)
        XCTAssertTrue(settings.hasRequestedAuthorization)
        XCTAssertFalse(center.pending.isEmpty)
        for request in center.pending {
            XCTAssertTrue(request.identifier.hasPrefix(DailyReminderNotification.identifierPrefix))
            let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
            XCTAssertEqual(trigger.dateComponents.hour, 20)
            XCTAssertEqual(trigger.dateComponents.minute, 0)
        }
    }

    /// 設定画面で時刻だけ変えてあれば、その時刻でオンにする
    func testEnableUsesSavedTime() async throws {
        authorizer.status = .authorized
        let time = try XCTUnwrap(DailyReminderTime(hour: 7, minute: 30))
        settingsStore.update { $0.time = time }
        let model = makeModel(isJustFinished: true)
        XCTAssertEqual(model.time, time)

        await model.enable()

        XCTAssertEqual(model.state, .enabled(time))
        XCTAssertEqual(authorizer.requestCount, 0)
        for request in center.pending {
            let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
            XCTAssertEqual(trigger.dateComponents.hour, 7)
            XCTAssertEqual(trigger.dateComponents.minute, 30)
        }
    }

    /// 許可されなければオフのまま、設定画面から変えられることを伝える
    func testEnableRefusedShowsDeniedAndStaysOff() async {
        authorizer.status = .notDetermined
        authorizer.grants = false
        let model = makeModel(isJustFinished: true)

        await model.enable()

        XCTAssertEqual(authorizer.requestCount, 1)
        XCTAssertEqual(model.state, .denied)
        let settings = settingsStore.load()
        XCTAssertFalse(settings.isEnabled)
        XCTAssertTrue(settings.hasShownResultPrompt)
        XCTAssertEqual(center.pending, [])
    }

    /// 拒否済みならダイアログは出せないので、そのまま設定画面から変えられることを伝える
    func testEnableWhenAlreadyDenied() async {
        authorizer.status = .denied
        let model = makeModel(isJustFinished: true)

        await model.enable()

        XCTAssertEqual(authorizer.requestCount, 0)
        XCTAssertEqual(model.state, .denied)
        XCTAssertFalse(settingsStore.load().isEnabled)
    }

    // MARK: - 今はしない

    /// 案内済みにして閉じ、それ以降は出さない。許可は求めない
    func testDeclineRecordsShownAndHides() {
        let model = makeModel(isJustFinished: true)

        model.decline()

        XCTAssertEqual(model.state, .hidden)
        XCTAssertEqual(authorizer.requestCount, 0)
        let settings = settingsStore.load()
        XCTAssertTrue(settings.hasShownResultPrompt)
        XCTAssertFalse(settings.isEnabled)
        XCTAssertFalse(settings.hasRequestedAuthorization)
        XCTAssertEqual(center.pending, [])
        XCTAssertEqual(makeModel(isJustFinished: true).state, .hidden)
    }

    /// 選んだ後は、もう一方のボタンを押しても何もしない
    func testEnableAfterDeclineDoesNothing() async {
        let model = makeModel(isJustFinished: true)
        model.decline()

        await model.enable()

        XCTAssertEqual(model.state, .hidden)
        XCTAssertEqual(authorizer.requestCount, 0)
        XCTAssertFalse(settingsStore.load().isEnabled)
    }

    // MARK: - Helpers

    private func makeModel(isJustFinished: Bool, isScreenshotDemo: Bool = false) -> DailyReminderPromptModel {
        let scheduler = DailyReminderScheduler(
            center: center,
            settingsStore: settingsStore,
            challengeStore: UserDefaultsDailyChallengeStore(userDefaults: userDefaults),
            now: { Date(timeIntervalSince1970: 1_790_000_000) },
            timeZone: { [tokyo] in tokyo },
            isActive: !isScreenshotDemo
        )
        return DailyReminderPromptModel(
            isJustFinished: isJustFinished,
            settingsStore: settingsStore,
            scheduler: scheduler,
            authorizer: authorizer,
            isScreenshotDemo: isScreenshotDemo
        )
    }
}

/// 許可の状態を決めておき、許可を求めた回数を数える `DailyReminderAuthorizing`
private final class PromptFakeAuthorizer: DailyReminderAuthorizing, @unchecked Sendable {
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
private final class PromptRecordingNotificationCenter: DailyReminderNotificationCenter, @unchecked Sendable {
    private let lock = NSLock()
    private var _pending: [UNNotificationRequest] = []

    var pending: [UNNotificationRequest] {
        lock.withLock { _pending }
    }

    func pendingRequestIdentifiers() async -> [String] {
        pending.map(\.identifier)
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
