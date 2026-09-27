//
//  AnswerChoice.swift
//  PrimePickApp
//

import Foundation

/// 解答ボタンの選択肢
///
/// 「正解 / 不正解」ではなく「素数だと答える / 素数ではないと答える」を表す。
/// 答えが合っているかどうかは出題された数との比較（`QuizAnswerRecord.isAnswerCorrect`）で決まる。
enum AnswerChoice {
    /// 素数ではないと答える
    case notPrime
    /// 素数だと答える
    case prime

    /// この選択肢が「素数である」と答えるものか
    var isPrime: Bool {
        switch self {
        case .notPrime:
            return false
        case .prime:
            return true
        }
    }
}
