//
//  DailyChallengeDay.swift
//  PrimePickApp
//

import Foundation

/// デイリーチャレンジの 1 日。全員が同じ日に同じ問題を解くための「今日」を表す
///
/// - 「今日」は端末のタイムゾーンの 0 時で切り替える
/// - 年月日はグレゴリオ暦で数える。`Calendar.current` は和暦・タイ仏暦の端末で年がずれ、
///   `dayKey`（＝ 出題のシード）が他の端末と食い違うため使わない
struct DailyChallengeDay: Hashable, Comparable {
    let year: Int
    let month: Int
    let day: Int

    /// 通し番号 #1 の日（デイリーを公開した日）
    static let launchDay = DailyChallengeDay(year: 2026, month: 10, day: 7)

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// `2026-10-01` の形式から読み取る。存在しない日付（`2026-02-30` など）は nil
    init?(dayKey: String) {
        let parts = dayKey.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2])
        else { return nil }
        let candidate = DailyChallengeDay(year: year, month: month, day: day)
        // `Int` は `+1`・`-01` のような符号付きも読めるため、正規形と一致するものだけを受け付ける（同じ日に別のキーを作らない）
        guard candidate.dayKey == dayKey else { return nil }
        // 正規化して元に戻らない日付（13 月・2 月 30 日など）は受け付けない
        guard let date = candidate.startDate(in: Self.utc),
              DailyChallengeDay(date: date, timeZone: Self.utc) == candidate
        else { return nil }
        self = candidate
    }

    /// `date` の瞬間に、`timeZone` の地域で何日か
    init(date: Date, timeZone: TimeZone) {
        let components = Self.calendar(timeZone: timeZone).dateComponents([.year, .month, .day], from: date)
        self.init(year: components.year ?? 0, month: components.month ?? 0, day: components.day ?? 0)
    }

    /// 端末の「今日」。時刻とタイムゾーンはテストのために差し替えられる
    static func today(now: Date = Date(), timeZone: TimeZone = .current) -> DailyChallengeDay {
        DailyChallengeDay(date: now, timeZone: timeZone)
    }

    /// 記録や出題のシードに使うキー。`2026-10-01` の形式
    var dayKey: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// 通し番号。`launchDay` を 1 とした経過日数（公開日より前は 0 以下）
    var dayNumber: Int {
        days(since: Self.launchDay) + 1
    }

    /// `days` 日後（負なら前）の日
    func adding(days: Int) -> DailyChallengeDay {
        let calendar = Self.calendar(timeZone: Self.utc)
        guard let start = startDate(in: Self.utc),
              let moved = calendar.date(byAdding: .day, value: days, to: start)
        else { return self }
        return DailyChallengeDay(date: moved, timeZone: Self.utc)
    }

    /// `other` から何日経ったか（`other` より前なら負）
    func days(since other: DailyChallengeDay) -> Int {
        let calendar = Self.calendar(timeZone: Self.utc)
        guard let start = other.startDate(in: Self.utc),
              let end = startDate(in: Self.utc)
        else { return 0 }
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    /// この日が `timeZone` の地域で始まる瞬間（0 時）
    func startDate(in timeZone: TimeZone) -> Date? {
        Self.calendar(timeZone: timeZone).date(from: DateComponents(year: year, month: month, day: day))
    }

    static func < (lhs: DailyChallengeDay, rhs: DailyChallengeDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    /// 日付の計算に使う暦。端末の設定に依らずグレゴリオ暦に固定する
    static func calendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    /// 日の加減算・日数の差に使うタイムゾーン。夏時間で 1 日が 23 / 25 時間になる地域の影響を受けないようにする
    private static let utc = TimeZone(identifier: "UTC")!
}
