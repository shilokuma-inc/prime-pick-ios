//
//  AnswerFeedback.swift
//  PrimePickApp
//

import SwiftUI

/// 解答結果に対して返すフィードバックの種類
enum AnswerFeedback {
    case correct
    case incorrect

    /// `sensoryFeedback` に渡す触覚パターン
    var sensoryFeedback: SensoryFeedback {
        switch self {
        case .correct:
            return .success
        case .incorrect:
            return .error
        }
    }

    var sound: SoundEffect {
        switch self {
        case .correct:
            return .correct
        case .incorrect:
            return .incorrect
        }
    }
}

/// 触覚とアニメーション再生のきっかけ
///
/// 同じ結果が連続しても View 側で変化を検知できるよう、解答ごとに増える `id` を持たせている。
struct AnswerFeedbackTrigger: Equatable {
    let id: Int
    let result: AnswerFeedback
}
