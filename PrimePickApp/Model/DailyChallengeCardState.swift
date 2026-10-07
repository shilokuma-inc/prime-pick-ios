//
//  DailyChallengeCardState.swift
//  PrimePickApp
//

import Foundation

/// タイトル画面の「今日のチャレンジ」カードに出す内容（Discussion #181 本文 2-6）
struct DailyChallengeCardState: Equatable {
    enum Status: Equatable {
        /// 今日はまだ始めていない
        case notStarted
        /// 始めたが最後まで解いていない（途中でやめた・強制終了した）。「未完了 3 / 10」
        case incomplete(answeredCount: Int, questionCount: Int)
        /// 最後まで解いた。「8 / 10 正解」
        case completed(correctCount: Int, questionCount: Int)
    }

    let status: Status
    /// 今日の通し番号（`#12`）
    let dayNumber: Int
    /// 現在のストリーク（`🔥 12`）
    let streak: Int

    /// 保存された記録と今日の日付から求める
    init(records: [DailyChallengeRecord], today: DailyChallengeDay) {
        if let record = records.first(where: { $0.dayKey == today.dayKey }) {
            status = record.isCompleted
                ? .completed(correctCount: record.correctCount, questionCount: record.results.count)
                : .incomplete(answeredCount: record.answeredCount, questionCount: record.results.count)
        } else {
            status = .notStarted
        }
        dayNumber = today.dayNumber
        streak = DailyChallengeStreak(records: records, today: today).current
    }

    init(status: Status, dayNumber: Int, streak: Int) {
        self.status = status
        self.dayNumber = dayNumber
        self.streak = streak
    }

    /// 今日のチャレンジに挑戦できるか（未挑戦のときだけ）
    var isPlayable: Bool {
        status == .notStarted
    }
}
