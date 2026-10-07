//
//  DailyChallengeDayTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class DailyChallengeDayTests: XCTestCase {

    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    private let losAngeles = TimeZone(identifier: "America/Los_Angeles")!

    // MARK: - dayKey

    func testDayKeyIsZeroPadded() {
        XCTAssertEqual(DailyChallengeDay(year: 2026, month: 10, day: 1).dayKey, "2026-10-01")
        XCTAssertEqual(DailyChallengeDay(year: 2027, month: 1, day: 9).dayKey, "2027-01-09")
    }

    func testDayKeyRoundTrips() {
        let day = DailyChallengeDay(year: 2028, month: 2, day: 29)
        XCTAssertEqual(DailyChallengeDay(dayKey: day.dayKey), day)
    }

    func testInvalidDayKeyIsRejected() {
        XCTAssertNil(DailyChallengeDay(dayKey: "2026-02-30"))
        XCTAssertNil(DailyChallengeDay(dayKey: "2026-13-01"))
        XCTAssertNil(DailyChallengeDay(dayKey: "2027-02-29"))
        XCTAssertNil(DailyChallengeDay(dayKey: "2026-1-01"))
        XCTAssertNil(DailyChallengeDay(dayKey: "20261001"))
        XCTAssertNil(DailyChallengeDay(dayKey: ""))
        // 符号付きの数字は長さが合っていても正規形ではない
        XCTAssertNil(DailyChallengeDay(dayKey: "2026-+1-01"))
        XCTAssertNil(DailyChallengeDay(dayKey: "+026-10-01"))
        XCTAssertNil(DailyChallengeDay(dayKey: "2026-10--1"))
    }

    // MARK: - 今日

    /// 同じ瞬間でも、端末のタイムゾーンの 0 時で日付が切り替わる
    func testTodayDependsOnTimeZone() {
        // 2026-10-01 00:30 JST = 2026-09-30 08:30 PDT
        let now = date("2026-10-01T00:30:00+09:00")
        XCTAssertEqual(DailyChallengeDay.today(now: now, timeZone: tokyo).dayKey, "2026-10-01")
        XCTAssertEqual(DailyChallengeDay.today(now: now, timeZone: losAngeles).dayKey, "2026-09-30")
    }

    func testTodaySwitchesAtMidnight() {
        XCTAssertEqual(DailyChallengeDay.today(now: date("2026-10-01T23:59:59+09:00"), timeZone: tokyo).dayKey, "2026-10-01")
        XCTAssertEqual(DailyChallengeDay.today(now: date("2026-10-02T00:00:00+09:00"), timeZone: tokyo).dayKey, "2026-10-02")
    }

    func testTodayAcrossYearEnd() {
        XCTAssertEqual(DailyChallengeDay.today(now: date("2026-12-31T23:59:00+09:00"), timeZone: tokyo).dayKey, "2026-12-31")
        XCTAssertEqual(DailyChallengeDay.today(now: date("2027-01-01T00:01:00+09:00"), timeZone: tokyo).dayKey, "2027-01-01")
    }

    /// 和暦・タイ仏暦の端末で `Calendar.current` を使うと年がずれる（令和 8 年・仏暦 2569 年）。
    /// 端末の暦に依らずグレゴリオ暦の年で数えることを確かめる
    func testDayKeyIgnoresNonGregorianCalendars() {
        let now = date("2026-10-01T12:00:00+09:00")
        for identifier in [Calendar.Identifier.japanese, .buddhist] {
            var calendar = Calendar(identifier: identifier)
            calendar.timeZone = tokyo
            XCTAssertNotEqual(calendar.component(.year, from: now), 2026, "\(identifier) では年がずれる前提")
        }
        XCTAssertEqual(DailyChallengeDay.calendar(timeZone: tokyo).identifier, .gregorian)
        XCTAssertEqual(DailyChallengeDay.today(now: now, timeZone: tokyo).dayKey, "2026-10-01")
    }

    func testStartDateIsMidnightInTimeZone() {
        let day = DailyChallengeDay(year: 2026, month: 10, day: 1)
        XCTAssertEqual(day.startDate(in: tokyo), date("2026-10-01T00:00:00+09:00"))
        XCTAssertEqual(day.startDate(in: losAngeles), date("2026-10-01T00:00:00-07:00"))
    }

    // MARK: - 日の計算

    func testAddingDaysAcrossMonthYearAndLeapDay() {
        XCTAssertEqual(DailyChallengeDay(year: 2026, month: 10, day: 31).adding(days: 1).dayKey, "2026-11-01")
        XCTAssertEqual(DailyChallengeDay(year: 2026, month: 12, day: 31).adding(days: 1).dayKey, "2027-01-01")
        XCTAssertEqual(DailyChallengeDay(year: 2028, month: 2, day: 28).adding(days: 1).dayKey, "2028-02-29")
        XCTAssertEqual(DailyChallengeDay(year: 2027, month: 1, day: 1).adding(days: -1).dayKey, "2026-12-31")
    }

    func testDaysSince() {
        let day = DailyChallengeDay(year: 2026, month: 10, day: 7)
        XCTAssertEqual(day.days(since: day), 0)
        XCTAssertEqual(DailyChallengeDay(year: 2027, month: 10, day: 7).days(since: day), 365)
        XCTAssertEqual(DailyChallengeDay(year: 2026, month: 10, day: 1).days(since: day), -6)
    }

    func testOrdering() {
        XCTAssertLessThan(DailyChallengeDay(year: 2026, month: 12, day: 31), DailyChallengeDay(year: 2027, month: 1, day: 1))
        XCTAssertLessThan(DailyChallengeDay(year: 2026, month: 9, day: 30), DailyChallengeDay(year: 2026, month: 10, day: 1))
    }

    // MARK: - 通し番号

    func testDayNumberStartsAtOneOnLaunchDay() {
        let launch = DailyChallengeDay.launchDay
        XCTAssertEqual(launch.dayNumber, 1)
        XCTAssertEqual(launch.adding(days: 11).dayNumber, 12)
        XCTAssertEqual(launch.adding(days: -1).dayNumber, 0)
    }

    private func date(_ iso8601: String) -> Date {
        ISO8601DateFormatter().date(from: iso8601)!
    }
}
