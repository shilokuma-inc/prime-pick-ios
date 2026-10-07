//
//  DailyChallengeStreak.swift
//  PrimePickApp
//

import Foundation

/// デイリーチャレンジのストリーク（`🔥 12`）と最長ストリーク
///
/// デイリーを最後まで解いた日が連続した日数（Discussion #181 Q5）。正解数は問わず、途中でやめた日は数えない。
/// 記録の日付の並びから毎回計算し、別には保存しない（本文 4-1）。
struct DailyChallengeStreak: Equatable {
    /// 現在のストリーク。今日か昨日に解き終えていて、そこから途切れずに続いている日数
    let current: Int
    /// これまでで最も長く続いたストリーク
    let longest: Int

    /// - Parameters:
    ///   - completedDays: 最後まで解いた日（順不同・重複可）
    ///   - today: 端末の「今日」
    ///
    /// 今日まだ解いていなくても、昨日まで続いていればストリークは切れていない扱いにする（今日解けば続く）。
    /// 端末の時計を戻して「今日」より後の日の記録がある場合も、最長ストリークには数え、現在のストリークには数えない。
    init(completedDays: some Sequence<DailyChallengeDay>, today: DailyChallengeDay) {
        let days = Set(completedDays)

        let latest = days.contains(today) ? today : today.adding(days: -1)
        var current = 0
        var day = latest
        while days.contains(day) {
            current += 1
            day = day.adding(days: -1)
        }

        var longest = 0
        var run = 0
        var previous: DailyChallengeDay?
        for day in days.sorted() {
            if let previous, day.days(since: previous) == 1 {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
            previous = day
        }

        self.current = current
        self.longest = max(longest, current)
    }

    /// 保存された記録から計算する。最後まで解いた記録だけを数え、`dayKey` が読めない記録は無視する
    init(records: some Sequence<DailyChallengeRecord>, today: DailyChallengeDay) {
        self.init(
            completedDays: records.lazy
                .filter(\.isCompleted)
                .compactMap { DailyChallengeDay(dayKey: $0.dayKey) },
            today: today
        )
    }
}
