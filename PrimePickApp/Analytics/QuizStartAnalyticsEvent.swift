//
//  QuizStartAnalyticsEvent.swift
//  PrimePickApp
//

import Foundation

/// 練習・タイムアタックを始めた画面
enum QuizStartSource: String, Hashable {
    /// タイトル画面の難易度ボタン
    case title
    /// デイリーの結果画面の「タイムアタックで遊ぶ」
    case dailyResult = "daily_result"
}

/// 練習・タイムアタックを始めたときに送る `quiz_start` イベント
///
/// デイリーの結果画面からどれだけタイムアタックに流れたかを `source` で測る（Discussion #181 本文 6 章）。
/// デイリー自体の開始は `daily_challenge_start` で測るため、このイベントは送らない。
struct QuizStartAnalyticsEvent: Equatable {
    static let name = "quiz_start"

    let gameMode: GameMode
    let difficulty: Difficulty
    let range: QuizRange
    let questionCount: QuizQuestionCount
    let source: QuizStartSource

    /// Firebase Analytics に渡すパラメータ。値は文字列か数値のみ
    var parameters: [String: Any] {
        [
            "game_mode": gameMode.id,
            "difficulty": difficulty.rawValue,
            "quiz_range": range.rawValue,
            "question_count": questionCount.value,
            "source": source.rawValue
        ]
    }
}
