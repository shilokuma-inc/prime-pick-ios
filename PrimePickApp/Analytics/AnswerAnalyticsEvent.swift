//
//  AnswerAnalyticsEvent.swift
//  PrimePickApp
//

import Foundation

/// 1 問解答するごとに送信する `answer` イベント
///
/// 1 問目の誤答率・回答時間を 2 問目以降と比べ、解答ボタンの意味が伝わっているかを測るために使う。
struct AnswerAnalyticsEvent: Equatable {
    static let name = "answer"

    let difficulty: Difficulty
    let range: QuizRange
    /// 何問目か（1 始まり）
    let questionNumber: Int
    let isCorrect: Bool
    /// 問題が表示されてから解答するまでの秒数
    let elapsedSeconds: TimeInterval

    /// Firebase Analytics に渡すパラメータ
    ///
    /// Firebase のパラメータ値は文字列か数値のみのため、正誤は 1 / 0 で送る。
    var parameters: [String: Any] {
        [
            "difficulty": difficulty.rawValue,
            "quiz_range": range.rawValue,
            "question_number": questionNumber,
            "is_correct": isCorrect ? 1 : 0,
            "elapsed_seconds": elapsedSeconds
        ]
    }
}
