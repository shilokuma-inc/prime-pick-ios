//
//  DailyChallengeStreak.swift
//  PrimePickApp
//

import Foundation
import QuizCore

/// デイリーチャレンジのストリーク（`🔥 12`）と最長ストリーク
///
/// デイリーを最後まで解いた日が連続した日数（Discussion #181 Q5）。正解数は問わず、途中でやめた日は数えない。
/// 記録の日付の並びから毎回計算し、別には保存しない（本文 4-1）。計算は QuizKit の `QuizStreak` が持つ。
typealias DailyChallengeStreak = QuizStreak

extension QuizStreak {
    /// 保存された記録から計算する。最後まで解いた記録だけを数え、`dayKey` が読めない記録は無視する
    init(records: some Sequence<DailyChallengeRecord>, today: QuizDay) {
        self.init(
            completedDays: records.lazy
                .filter(\.isCompleted)
                .compactMap { QuizDay(dayKey: $0.dayKey) },
            today: today
        )
    }
}
