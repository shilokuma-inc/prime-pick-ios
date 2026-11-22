//
//  DailyChallengeAnalyticsEvent.swift
//  PrimePickApp
//

import Foundation

/// デイリーチャレンジの計測イベント（Discussion #181 本文 6 章）
///
/// Firebase のパラメータ値は文字列か数値のみのため、共有先のほかはすべて数値で送る。
enum DailyChallengeAnalyticsEvent: Equatable {
    /// 始めた（その日の挑戦権を使った）。`streakBefore` は始める前の時点のストリーク
    case start(dayNumber: Int, streakBefore: Int)
    /// 最後まで解いた。`streak` は解き終えたあとのストリーク
    case complete(dayNumber: Int, correctCount: Int, totalSeconds: TimeInterval, streak: Int)
    /// 途中でやめた。`questionNumber` はやめたときに表示していた問題（1 始まり）
    case abandon(dayNumber: Int, questionNumber: Int)
    /// 結果画面のシェアボタンを押した
    case shareTap(dayNumber: Int, correctCount: Int, streak: Int)
    /// 共有シートで送り終えた（閉じただけのときは送らない）。`activityType` は共有先（`UIActivity.ActivityType` の rawValue）
    case shareComplete(dayNumber: Int, activityType: String)

    /// Firebase のパラメータ値（文字列）の長さの上限
    static let maxParameterValueLength = 100

    var name: String {
        switch self {
        case .start:
            return "daily_challenge_start"
        case .complete:
            return "daily_challenge_complete"
        case .abandon:
            return "daily_challenge_abandon"
        case .shareTap:
            return "daily_share_tap"
        case .shareComplete:
            return "daily_share_complete"
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
        case let .shareTap(dayNumber, correctCount, streak):
            return [
                "day_number": dayNumber,
                "correct_count": correctCount,
                "streak": streak
            ]
        case let .shareComplete(dayNumber, activityType):
            return [
                "day_number": dayNumber,
                "activity_type": String(activityType.prefix(Self.maxParameterValueLength))
            ]
        }
    }
}
