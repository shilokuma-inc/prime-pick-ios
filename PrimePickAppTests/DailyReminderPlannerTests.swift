//
//  DailyReminderPlannerTests.swift
//  PrimePickAppTests
//

import XCTest
import QuizCore
@testable import PrimePickApp

final class DailyReminderPlannerTests: XCTestCase {

    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    private let today = DailyChallengeDay(year: 2026, month: 11, day: 23)
    private let startedAt = Date(timeIntervalSince1970: 1_790_000_000)

    // MARK: - オン／オフ

    func testDisabledIsEmpty() {
        var settings = enabledSettings()
        settings.isEnabled = false
        XCTAssertEqual(plan(settings: settings, now: date("2026-11-23T12:00:00+09:00")), [])
    }

    // MARK: - 今日の分

    /// 通知時刻の前で、今日まだ始めていなければ今日の分から 7 日先まで入る
    func testIncludesTodayBeforeReminderTime() {
        let notifications = plan(now: date("2026-11-23T19:59:00+09:00"))
        XCTAssertEqual(notifications.map(\.day.dayKey), dayKeys(0...7))
        XCTAssertEqual(notifications.map(\.daysAhead), Array(0...7))
        XCTAssertEqual(notifications.first?.fireDate, date("2026-11-23T20:00:00+09:00"))
        XCTAssertEqual(notifications.last?.fireDate, date("2026-11-30T20:00:00+09:00"))
    }

    /// 通知時刻ちょうど・過ぎたら今日の分は入らない
    func testExcludesTodayAtOrAfterReminderTime() {
        XCTAssertEqual(plan(now: date("2026-11-23T20:00:00+09:00")).map(\.day.dayKey), dayKeys(1...7))
        XCTAssertEqual(plan(now: date("2026-11-23T23:59:00+09:00")).map(\.day.dayKey), dayKeys(1...7))
    }

    func testExcludesTodayWhenCompleted() {
        let records = [record(back: 0, completed: true)]
        let notifications = plan(records: records, now: date("2026-11-23T08:00:00+09:00"))
        XCTAssertEqual(notifications.map(\.day.dayKey), dayKeys(1...7))
    }

    /// 始めて途中でやめた日も、その日の挑戦権を使っているので知らせない
    func testExcludesTodayWhenStartedButIncomplete() {
        let records = [record(back: 0, completed: false)]
        let notifications = plan(records: records, now: date("2026-11-23T08:00:00+09:00"))
        XCTAssertEqual(notifications.map(\.day.dayKey), dayKeys(1...7))
    }

    /// 0 時ちょうどは新しい日の始まり
    func testMidnightStartsNewDay() {
        let notifications = plan(now: date("2026-11-24T00:00:00+09:00"), lastOpenedDay: today.adding(days: 1))
        XCTAssertEqual(notifications.first?.day.dayKey, "2026-11-24")
    }

    // MARK: - 何日先まで

    /// 最後に開いた日から 7 日先までに限る
    func testLimitedToSevenDaysFromLastOpenedDay() {
        let notifications = plan(now: date("2026-11-25T12:00:00+09:00"), lastOpenedDay: today)
        XCTAssertEqual(notifications.map(\.day.dayKey), ["2026-11-25", "2026-11-26", "2026-11-27", "2026-11-28", "2026-11-29", "2026-11-30"])
    }

    func testLastOpenedSevenDaysAgoLeavesOnlyToday() {
        let notifications = plan(now: date("2026-11-30T12:00:00+09:00"), lastOpenedDay: today)
        XCTAssertEqual(notifications.map(\.day.dayKey), ["2026-11-30"])
    }

    func testLastOpenedMoreThanSevenDaysAgoIsEmpty() {
        XCTAssertEqual(plan(now: date("2026-12-01T12:00:00+09:00"), lastOpenedDay: today), [])
    }

    /// 最後に開いた日がまだ無ければ今日から数える
    func testNoLastOpenedDayCountsFromToday() {
        var settings = enabledSettings()
        settings.lastOpenedDay = nil
        let notifications = plan(settings: settings, now: date("2026-11-23T12:00:00+09:00"))
        XCTAssertEqual(notifications.map(\.day.dayKey), dayKeys(0...7))
    }

    /// 時計を戻して最後に開いた日が今日より後でも、今日から 7 日先までにする
    func testFutureLastOpenedDayCountsFromToday() {
        let notifications = plan(now: date("2026-11-23T12:00:00+09:00"), lastOpenedDay: today.adding(days: 3))
        XCTAssertEqual(notifications.map(\.day.dayKey), dayKeys(0...7))
    }

    /// 月・年をまたいでも日付で数える
    func testAcrossYearEnd() {
        let lastDay = DailyChallengeDay(year: 2026, month: 12, day: 30)
        let notifications = plan(now: date("2026-12-30T21:00:00+09:00"), lastOpenedDay: lastDay)
        XCTAssertEqual(notifications.map(\.day.dayKey), [
            "2026-12-31", "2027-01-01", "2027-01-02", "2027-01-03", "2027-01-04", "2027-01-05", "2027-01-06"
        ])
    }

    // MARK: - 文面

    /// 翌日分だけ連続日数が入る。今日を解き終えていれば今日までの連続日数
    func testOnlyNextDayHasStreak() {
        let records = (0...2).map { record(back: $0, completed: true) }
        let notifications = plan(records: records, now: date("2026-11-23T21:00:00+09:00"))

        XCTAssertEqual(notifications.first?.daysAhead, 1)
        XCTAssertEqual(notifications.first?.message, .streak(3))
        XCTAssertEqual(notifications.dropFirst().map(\.message), Array(repeating: .standard, count: 6))
    }

    /// 今日の分は決まった文面。翌日分は、今日を解いていなければ連続が切れるので決まった文面
    func testTodayAndNextDayWithoutPlayingTodayAreStandard() {
        let records = (1...4).map { record(back: $0, completed: true) }
        let notifications = plan(records: records, now: date("2026-11-23T12:00:00+09:00"))

        XCTAssertEqual(notifications[0].daysAhead, 0)
        XCTAssertEqual(notifications[0].message, .standard)
        XCTAssertEqual(notifications[1].daysAhead, 1)
        XCTAssertEqual(notifications[1].message, .standard)
    }

    /// 連続日数が 0 なら決まった文面
    func testZeroStreakIsStandard() {
        let notifications = plan(now: date("2026-11-23T21:00:00+09:00"))
        XCTAssertEqual(notifications.map(\.message), Array(repeating: .standard, count: 7))
    }

    /// 途中でやめた日は連続日数に数えない
    func testIncompleteTodayDoesNotCountInStreak() {
        let records = [record(back: 0, completed: false), record(back: 1, completed: true)]
        let notifications = plan(records: records, now: date("2026-11-23T21:00:00+09:00"))
        XCTAssertEqual(notifications.first?.message, .standard)
    }

    func testBodyContainsStreakOnlyForStreakMessage() {
        let streak = notification(message: .streak(12))
        let standard = notification(message: .standard)
        XCTAssertTrue(streak.body.contains("12"), streak.body)
        XCTAssertTrue(streak.body.contains("🔥"), streak.body)
        XCTAssertFalse(standard.body.contains("🔥"), standard.body)
        XCTAssertNotEqual(streak.body, standard.body)
        XCTAssertFalse(standard.title.isEmpty)
    }

    // MARK: - 時刻

    func testUsesConfiguredTime() throws {
        var settings = enabledSettings()
        settings.time = try XCTUnwrap(DailyReminderTime(hour: 7, minute: 30))
        let notifications = plan(settings: settings, now: date("2026-11-23T07:29:00+09:00"))

        XCTAssertEqual(notifications.first?.fireDate, date("2026-11-23T07:30:00+09:00"))
        let components = try XCTUnwrap(notifications.first?.dateComponents)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 11)
        XCTAssertEqual(components.day, 23)
        XCTAssertEqual(components.hour, 7)
        XCTAssertEqual(components.minute, 30)
        XCTAssertEqual(components.calendar?.identifier, .gregorian)
    }

    /// 端末のタイムゾーンの時刻で届ける
    func testFireDateFollowsTimeZone() {
        let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
        let notifications = DailyReminderPlanner.notifications(
            settings: enabledSettings(lastOpenedDay: DailyChallengeDay(year: 2026, month: 11, day: 22)),
            records: [],
            now: date("2026-11-22T12:00:00-08:00"),
            timeZone: losAngeles
        )
        XCTAssertEqual(notifications.first?.day.dayKey, "2026-11-22")
        XCTAssertEqual(notifications.first?.fireDate, date("2026-11-22T20:00:00-08:00"))
    }

    // MARK: - 識別子

    func testIdentifierIsDerivedFromDay() {
        let notifications = plan(now: date("2026-11-23T12:00:00+09:00"))
        XCTAssertEqual(notifications.first?.identifier, "dailyReminder.2026-11-23")
        XCTAssertEqual(Set(notifications.map(\.identifier)).count, notifications.count)
        XCTAssertTrue(notifications.allSatisfy { $0.identifier.hasPrefix(DailyReminderNotification.identifierPrefix) })
    }

    /// 組み直しても同じ日の識別子は変わらない（前の予約と重ならない）
    func testIdentifiersAreStableAcrossReplanning() {
        let morning = plan(now: date("2026-11-23T08:00:00+09:00"))
        let night = plan(records: [record(back: 0, completed: true)], now: date("2026-11-23T21:00:00+09:00"))
        XCTAssertEqual(Set(night.map(\.identifier)), Set(morning.map(\.identifier)).subtracting(["dailyReminder.2026-11-23"]))
    }

    func testDayFromIdentifier() {
        XCTAssertEqual(DailyReminderNotification.day(fromIdentifier: "dailyReminder.2026-11-24"), today.adding(days: 1))
        XCTAssertNil(DailyReminderNotification.day(fromIdentifier: "other.2026-11-24"))
        XCTAssertNil(DailyReminderNotification.day(fromIdentifier: "dailyReminder.broken"))
    }

    func testStoreOverloadReadsRecords() {
        let suiteName = "DailyReminderPlannerTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsDailyChallengeStore(userDefaults: userDefaults)
        store.save(record(back: 0, completed: true))

        let notifications = DailyReminderPlanner.notifications(
            settings: enabledSettings(),
            store: store,
            now: date("2026-11-23T08:00:00+09:00"),
            timeZone: tokyo
        )
        XCTAssertEqual(notifications.map(\.day.dayKey), dayKeys(1...7))
    }

    // MARK: - ヘルパー

    private func enabledSettings(lastOpenedDay: DailyChallengeDay? = nil) -> DailyReminderSettings {
        var settings = DailyReminderSettings()
        settings.isEnabled = true
        settings.lastOpenedDay = lastOpenedDay ?? today
        return settings
    }

    private func plan(
        settings: DailyReminderSettings? = nil,
        records: [DailyChallengeRecord] = [],
        now: Date,
        lastOpenedDay: DailyChallengeDay? = nil
    ) -> [DailyReminderNotification] {
        var settings = settings ?? enabledSettings()
        if let lastOpenedDay {
            settings.lastOpenedDay = lastOpenedDay
        }
        return DailyReminderPlanner.notifications(settings: settings, records: records, now: now, timeZone: tokyo)
    }

    private func notification(message: DailyReminderNotification.Message) -> DailyReminderNotification {
        DailyReminderNotification(
            day: today,
            daysAhead: 1,
            dateComponents: DateComponents(),
            fireDate: date("2026-11-23T20:00:00+09:00"),
            message: message
        )
    }

    /// `today` から数えた日の dayKey
    private func dayKeys(_ range: ClosedRange<Int>) -> [String] {
        range.map { today.adding(days: $0).dayKey }
    }

    private func record(back: Int, completed: Bool) -> DailyChallengeRecord {
        var record = DailyChallengeRecord.started(
            dayKey: today.adding(days: -back).dayKey,
            generatorVersion: 1,
            questionCount: 10,
            startedAt: startedAt
        )
        record.results = Array(repeating: completed ? .correct : .unanswered, count: 10)
        record.completedAt = completed ? startedAt.addingTimeInterval(60) : nil
        return record
    }

    private func date(_ iso8601: String) -> Date {
        ISO8601DateFormatter().date(from: iso8601)!
    }
}
