//
//  DailyReminderPlanner.swift
//  PrimePickApp
//

import Foundation
import QuizCore

/// 予約するリマインド 1 件
struct DailyReminderNotification: Equatable {
    /// このアプリが予約したリマインドの識別子の頭。組み直すときは、これで始まる予約を全部消してから入れ直す
    static let identifierPrefix = "dailyReminder."

    enum Message: Equatable {
        /// 翌日分。連続日数を入れる（連続日数が 1 以上のときだけ）
        case streak(Int)
        /// 決まった文面
        case standard
    }

    /// どの日のデイリーを知らせるか
    let day: DailyChallengeDay
    /// 予約した日（今日）から何日後か。今日の分は 0、翌日分は 1
    let daysAhead: Int
    /// 届ける日時（グレゴリオ暦の年・月・日・時・分。`calendar` にタイムゾーンを入れてある）
    let dateComponents: DateComponents
    /// 届ける瞬間
    let fireDate: Date
    let message: Message

    /// 日付から決める識別子（`dailyReminder.2026-10-01`）。同じ日の予約は組み直しても同じ識別子になり、重ならない
    var identifier: String {
        Self.identifier(for: day)
    }

    static func identifier(for day: DailyChallengeDay) -> String {
        identifierPrefix + day.dayKey
    }

    /// 識別子から日を読む。このアプリのリマインドでなければ nil
    static func day(fromIdentifier identifier: String) -> DailyChallengeDay? {
        guard identifier.hasPrefix(identifierPrefix) else { return nil }
        return DailyChallengeDay(dayKey: String(identifier.dropFirst(identifierPrefix.count)))
    }

    var title: String {
        String(localized: "Daily Challenge")
    }

    var body: String {
        switch message {
        case .streak(let streak):
            String(localized: "🔥 \(streak)-day streak! Keep it going with today's challenge.")
        case .standard:
            String(localized: "Today's challenge is ready. Can you spot the primes?")
        }
    }
}

/// 設定・デイリーの記録・現在時刻から、予約するリマインドの一覧を求める（副作用を持たない）
enum DailyReminderPlanner {
    /// 最後に開いた日から何日先まで予約するか
    static let scheduleDays = 7

    static func notifications(
        settings: DailyReminderSettings,
        store: some DailyChallengeStore,
        now: Date,
        timeZone: TimeZone = .current
    ) -> [DailyReminderNotification] {
        notifications(settings: settings, records: store.allRecords(), now: now, timeZone: timeZone)
    }

    /// 予約するリマインド（日付の昇順）
    ///
    /// - オフなら空
    /// - 今日の分は、今日のデイリーに手を付けている（解き終えた・途中でやめた）か、通知時刻を過ぎていれば除く
    /// - 最後に開いた日から `scheduleDays` 日先までに限る（最後に開いた日が今日より後なら今日から数える）
    /// - 翌日分だけ連続日数を入れた文面にし、連続日数が 0 なら決まった文面にする。2 日目以降は決まった文面
    static func notifications(
        settings: DailyReminderSettings,
        records: [DailyChallengeRecord],
        now: Date,
        timeZone: TimeZone = .current
    ) -> [DailyReminderNotification] {
        guard settings.isEnabled else { return [] }

        let calendar = DailyChallengeDay.calendar(timeZone: timeZone)
        let today = DailyChallengeDay.today(now: now, timeZone: timeZone)
        let lastDay = min(settings.lastOpenedDay ?? today, today).adding(days: scheduleDays)
        let playedDayKeys = Set(records.map(\.dayKey))
        guard today <= lastDay else { return [] }

        return (0...lastDay.days(since: today)).compactMap { daysAhead in
            let day = today.adding(days: daysAhead)
            guard !playedDayKeys.contains(day.dayKey) else { return nil }

            guard let startDate = day.startDate(in: timeZone) else { return nil }
            var components = calendar.dateComponents([.year, .month, .day], from: startDate)
            components.calendar = calendar
            components.timeZone = timeZone
            components.hour = settings.time.hour
            components.minute = settings.time.minute
            guard let fireDate = calendar.date(from: components), fireDate > now else { return nil }

            let message: DailyReminderNotification.Message
            if daysAhead == 1 {
                // 翌日の時点の連続日数。今日を解き終えていれば今日まで、解いていなければ 0（解き終えたときに組み直す）
                let streak = DailyChallengeStreak(records: records, today: day).current
                message = streak > 0 ? .streak(streak) : .standard
            } else {
                message = .standard
            }
            return DailyReminderNotification(
                day: day,
                daysAhead: daysAhead,
                dateComponents: components,
                fireDate: fireDate,
                message: message
            )
        }
    }
}
