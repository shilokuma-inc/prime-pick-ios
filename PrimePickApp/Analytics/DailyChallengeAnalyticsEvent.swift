//
//  DailyChallengeAnalyticsEvent.swift
//  PrimePickApp
//

import Foundation

/// デイリーチャレンジの計測イベント（Discussion #181 本文 6 章）
///
/// Firebase のパラメータ値は文字列か数値のみのため、すべて数値で送る。
enum DailyChallengeAnalyticsEvent: Equatable {
    /// 始めた（その日の挑戦権を使った）。`streakBefore` は始める前の時点のストリーク
    case start(dayNumber: Int, streakBefore: Int)
    /// 最後まで解いた。`streak` は解き終えたあとのストリーク
    case complete(dayNumber: Int, correctCount: Int, totalSeconds: TimeInterval, streak: Int)
    /// 途中でやめた。`questionNumber` はやめたときに表示していた問題（1 始まり）
    case abandon(dayNumber: Int, questionNumber: Int)

    var name: String {
        switch self {
        case .start:
            return "daily_challenge_start"
        case .complete:
            return "daily_challenge_complete"
        case .abandon:
            return "daily_challenge_abandon"
        }
    }

    /// Firebase Analytics に渡すパラメータ
    var parameters: [String: Any] {
        switch self {
        case let .start(dayNumber, streakBefore):
            return [
                "day_number": dayNumber,
                "streak_before": streakBefore
            ]
        case let .complete(dayNumber, correctCount, totalSeconds, streak):
            return [
                "day_number": dayNumber,
                "correct_count": correctCount,
                "total_seconds": totalSeconds,
                "streak": streak
            ]
        case let .abandon(dayNumber, questionNumber):
            return [
                "day_number": dayNumber,
                "question_number": questionNumber
            ]
        }
    }
}
