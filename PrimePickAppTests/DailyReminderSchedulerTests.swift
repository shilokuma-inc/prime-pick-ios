//
//  DailyReminderSchedulerTests.swift
//  PrimePickAppTests
//

import XCTest
import QuizCore
import SwiftUI
import UserNotifications
@testable import PrimePickApp

final class DailyReminderSchedulerTests: XCTestCase {

    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    private let today = DailyChallengeDay(year: 2026, month: 11, day: 23)
    private let startedAt = Date(timeIntervalSince1970: 1_790_000_000)

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var settingsStore: DailyReminderSettingsStore!
    private var challengeStore: UserDefaultsDailyChallengeStore!
    private var center: FakeNotificationCenter!

    override func setUp() {
        super.setUp()
        suiteName = "DailyReminderSchedulerTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        settingsStore = DailyReminderSettingsStore(userDefaults: userDefaults)
        challengeStore = UserDefaultsDailyChallengeStore(userDefaults: userDefaults)
        center = FakeNotificationCenter()
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - 予約し直す

    func testRescheduleAddsPlannedReminders() async throws {
        enable()
        await makeScheduler(now: date("2026-11-23T12:00:00+09:00")).reschedule().value

        XCTAssertEqual(center.pendingIdentifiers, dayKeys(0...7).map { "dailyReminder.\($0)" })
        let first = try XCTUnwrap(center.pending.first)
        let trigger = try XCTUnwrap(first.trigger as? UNCalendarNotificationTrigger)
        XCTAssertFalse(trigger.repeats)
        XCTAssertEqual(trigger.dateComponents.day, 23)
        XCTAssertEqual(trigger.dateComponents.hour, 20)
        XCTAssertEqual(trigger.dateComponents.minute, 0)
        XCTAssertEqual(first.content.title, String(localized: "Daily Challenge"))
        XCTAssertEqual(first.content.body, String(localized: "Today's challenge is ready. Can you spot the primes?"))
        XCTAssertEqual(first.content.userInfo[DailyReminderTap.daysAheadKey] as? Int, 0)
        XCTAssertEqual(center.pending.last?.content.userInfo[DailyReminderTap.daysAheadKey] as? Int, 7)
    }

    /// 前の予約（このアプリのリマインド）は全部消してから入れ直す。ほかの通知には触らない
    func testRescheduleReplacesPreviousRemindersOnly() async {
        enable()
        center.pending = [
            request(identifier: "dailyReminder.2026-11-20"),
            request(identifier: "dailyReminder.2026-11-23"),
            request(identifier: "other.notification")
        ]
        await makeScheduler(now: date("2026-11-23T21:00:00+09:00")).reschedule().value

        XCTAssertEqual(
            center.pendingIdentifiers,
            ["other.notification"] + dayKeys(1...7).map { "dailyReminder.\($0)" }
        )
    }

    /// 何度組み直しても二重にならない
    func testRepeatedRescheduleDoesNotDuplicate() async {
        enable()
        let scheduler = makeScheduler(now: date("2026-11-23T12:00:00+09:00"))
        scheduler.reschedule()
        scheduler.reschedule()
        await scheduler.reschedule().value

        XCTAssertEqual(center.pendingIdentifiers, dayKeys(0...7).map { "dailyReminder.\($0)" })
    }

    func testDisabledRemovesAllReminders() async {
        center.pending = [request(identifier: "dailyReminder.2026-11-24")]
        await makeScheduler(now: date("2026-11-23T12:00:00+09:00")).reschedule().value

        XCTAssertEqual(center.pendingIdentifiers, [])
    }

    /// 撮影モードでは予約も取り消しもしない
    func testInactiveDoesNothing() async {
        enable(lastOpenedDay: today.adding(days: -3))
        center.pending = [request(identifier: "dailyReminder.2026-11-24")]
        let scheduler = makeScheduler(now: date("2026-11-23T12:00:00+09:00"), isActive: false)
        await scheduler.reschedule().value
        await scheduler.appDidBecomeActive().value

        XCTAssertEqual(center.pendingIdentifiers, ["dailyReminder.2026-11-24"])
        XCTAssertEqual(settingsStore.load().lastOpenedDay, today.adding(days: -3))
    }

    // MARK: - 前面に戻ったとき

    /// 最後に開いた日を今日にし、そこから 7 日先まで予約する
    func testAppDidBecomeActiveUpdatesLastOpenedDay() async {
        enable(lastOpenedDay: today)
        let now = date("2026-11-26T12:00:00+09:00")
        await makeScheduler(now: now).appDidBecomeActive().value

        XCTAssertEqual(settingsStore.load().lastOpenedDay, today.adding(days: 3))
        XCTAssertEqual(center.pendingIdentifiers.last, "dailyReminder.2026-12-03")
        XCTAssertEqual(center.pendingIdentifiers.count, 8)
    }

    // MARK: - 設定を変えたとき

    func testUpdateSettingsSavesAndReschedules() async throws {
        let time = try XCTUnwrap(DailyReminderTime(hour: 7, minute: 30))
        await makeScheduler(now: date("2026-11-23T12:00:00+09:00")).updateSettings {
            $0.isEnabled = true
            $0.time = time
        }.value

        XCTAssertEqual(settingsStore.load().time, time)
        // 今日の 7:30 は過ぎているので翌日から
        XCTAssertEqual(center.pendingIdentifiers.first, "dailyReminder.2026-11-24")
        let trigger = try XCTUnwrap(center.pending.first?.trigger as? UNCalendarNotificationTrigger)
        XCTAssertEqual(trigger.dateComponents.hour, 7)
        XCTAssertEqual(trigger.dateComponents.minute, 30)

        await makeScheduler(now: date("2026-11-23T12:00:00+09:00")).updateSettings { $0.isEnabled = false }.value
        XCTAssertEqual(center.pendingIdentifiers, [])
    }

    // MARK: - 解き終えたとき

    /// 解き終えると予約し直し、今日の分が消え、翌日分に連続日数が入る
    func testFinishingDailyRemovesTodayReminder() async {
        enable()
        let now = date("2026-11-23T12:00:00+09:00")
        let scheduler = makeScheduler(now: now)
        await scheduler.reschedule().value
        XCTAssertEqual(center.pendingIdentifiers.first, "dailyReminder.2026-11-23")

        var rescheduled: Task<Void, Never>?
        let finisher = DailyChallengePlayFinisher(
            startedRecord: .started(dayKey: today.dayKey, generatorVersion: 1, questionCount: 10, startedAt: startedAt),
            store: challengeStore,
            now: { now },
            sendAnalytics: { _ in },
            rescheduleReminders: { rescheduled = scheduler.reschedule() }
        )
        _ = finisher.finish(QuizPlayOutcome(gameMode: .dailyChallenge, difficulty: .easy, score: 0, correctCount: 0, answerRecords: []))
        await rescheduled?.value

        XCTAssertEqual(center.pendingIdentifiers, dayKeys(1...7).map { "dailyReminder.\($0)" })
        XCTAssertEqual(
            center.pending.first?.content.body,
            DailyReminderNotification(day: today.adding(days: 1), daysAhead: 1, dateComponents: DateComponents(), fireDate: now, message: .streak(1)).body
        )
    }

    /// 解いた日の届いたリマインドは通知センターから消す。まだ解いていない日の分は残す
    func testRemovesDeliveredRemindersOfPlayedDays() async {
        enable()
        challengeStore.save(record(day: today, completed: true))
        center.delivered = ["dailyReminder.2026-11-22", "dailyReminder.2026-11-23", "other.notification"]
        await makeScheduler(now: date("2026-11-23T21:00:00+09:00")).reschedule().value

        XCTAssertEqual(center.delivered, ["dailyReminder.2026-11-22", "other.notification"])
    }

    // MARK: - 前面にあるときに届いたリマインド

    func testForegroundPresentation() {
        let scheduler = makeScheduler(now: date("2026-11-23T20:00:00+09:00"))
        XCTAssertEqual(scheduler.foregroundPresentationOptions(forIdentifier: "dailyReminder.2026-11-23"), [.banner, .list])
        XCTAssertEqual(scheduler.foregroundPresentationOptions(forIdentifier: "other.notification"), [])

        challengeStore.save(record(day: today, completed: false))
        XCTAssertEqual(scheduler.foregroundPresentationOptions(forIdentifier: "dailyReminder.2026-11-23"), [])

        let inactive = self.makeScheduler(now: date("2026-11-23T20:00:00+09:00"), isActive: false)
        XCTAssertEqual(inactive.foregroundPresentationOptions(forIdentifier: "dailyReminder.2026-11-24"), [])
    }

    // MARK: - タップ

    func testTapReadsDayAndDaysAhead() {
        let tap = DailyReminderTap(identifier: "dailyReminder.2026-11-24", userInfo: [DailyReminderTap.daysAheadKey: 1])
        XCTAssertEqual(tap?.day, today.adding(days: 1))
        XCTAssertEqual(tap?.daysAhead, 1)

        XCTAssertNil(DailyReminderTap(identifier: "dailyReminder.2026-11-24", userInfo: [:])?.daysAhead)
        XCTAssertNil(DailyReminderTap(identifier: "other.notification", userInfo: [:]))
    }

    @MainActor
    func testRouterKeepsTapUntilConsumed() {
        let router = DailyReminderRouter()
        let tap = DailyReminderTap(identifier: "dailyReminder.2026-11-24", userInfo: [:])!
        router.open(tap)
        XCTAssertEqual(router.pendingTap, tap)
        XCTAssertEqual(router.consume(), tap)
        XCTAssertNil(router.pendingTap)
        XCTAssertNil(router.consume())
    }

    @MainActor
    func testReminderPathOpensDailyChallengeOnly() {
        XCTAssertEqual(MainView.reminderPath, NavigationPath([DailyChallengeRoute()]))
        XCTAssertEqual(MainView.reminderPath.count, 1)
    }

    // MARK: - ヘルパー

    /// オンにする。最後に開いた日は指定が無ければ今日
    private func enable(lastOpenedDay: DailyChallengeDay? = nil) {
        let lastOpenedDay = lastOpenedDay ?? today
        settingsStore.update {
            $0.isEnabled = true
            $0.lastOpenedDay = lastOpenedDay
        }
    }

    private func makeScheduler(now: Date, isActive: Bool = true) -> DailyReminderScheduler {
        DailyReminderScheduler(
            center: center,
            settingsStore: settingsStore,
            challengeStore: challengeStore,
            now: { now },
            timeZone: { [tokyo] in tokyo },
            isActive: isActive
        )
    }

    private func request(identifier: String) -> UNNotificationRequest {
        UNNotificationRequest(identifier: identifier, content: UNMutableNotificationContent(), trigger: nil)
    }

    private func record(day: DailyChallengeDay, completed: Bool) -> DailyChallengeRecord {
        var record = DailyChallengeRecord.started(dayKey: day.dayKey, generatorVersion: 1, questionCount: 10, startedAt: startedAt)
        record.completedAt = completed ? startedAt.addingTimeInterval(60) : nil
        return record
    }

    /// `today` から数えた日の dayKey
    private func dayKeys(_ range: ClosedRange<Int>) -> [String] {
        range.map { today.adding(days: $0).dayKey }
    }

    private func date(_ iso8601: String) -> Date {
        ISO8601DateFormatter().date(from: iso8601)!
    }
}

/// 予約と取り消しを記録するだけの `DailyReminderNotificationCenter`
private final class FakeNotificationCenter: DailyReminderNotificationCenter, @unchecked Sendable {
    private let lock = NSLock()
    private var _pending: [UNNotificationRequest] = []
    private var _delivered: [String] = []

    var pending: [UNNotificationRequest] {
        get { lock.withLock { _pending } }
        set { lock.withLock { _pending = newValue } }
    }

    var delivered: [String] {
        get { lock.withLock { _delivered } }
        set { lock.withLock { _delivered = newValue } }
    }

    var pendingIdentifiers: [String] {
        pending.map(\.identifier)
    }

    func pendingRequestIdentifiers() async -> [String] {
        pendingIdentifiers
    }

    func deliveredNotificationIdentifiers() async -> [String] {
        delivered
    }

    func removePendingRequests(withIdentifiers identifiers: [String]) {
        pending.removeAll { identifiers.contains($0.identifier) }
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        delivered.removeAll { identifiers.contains($0) }
    }

    /// 同じ識別子の予約は置き換える（`UNUserNotificationCenter` と同じ）
    func add(_ request: UNNotificationRequest) async throws {
        lock.withLock {
            _pending.removeAll { $0.identifier == request.identifier }
            _pending.append(request)
        }
    }
}
