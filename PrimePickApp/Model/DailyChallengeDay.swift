//
//  DailyChallengeDay.swift
//  PrimePickApp
//

import Foundation
import QuizCore

/// デイリーチャレンジの 1 日。全員が同じ日に同じ問題を解くための「今日」を表す
///
/// 日付の扱い（端末のタイムゾーンの 0 時で切り替え・グレゴリオ暦で数える）は QuizKit の `QuizDay` が持つ。
typealias DailyChallengeDay = QuizDay

extension QuizDay {
    /// 通し番号 #1 の日（デイリーを公開した日）
    static let launchDay = QuizDay(year: 2026, month: 10, day: 7)

    /// 通し番号。`launchDay` を 1 とした経過日数（公開日より前は 0 以下）
    var dayNumber: Int {
        dayNumber(since: Self.launchDay)
    }
}
