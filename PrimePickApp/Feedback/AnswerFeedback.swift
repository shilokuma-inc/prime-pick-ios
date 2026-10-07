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
    ///
    /// 正解はコンボ段階に応じて強くする（`ComboStage.correctFeedback`）。誤答は従来どおり `.error`。
    /// - Parameter combo: この解答を反映した後の連続正解数
    func sensoryFeedback(combo: Int) -> SensoryFeedback {
        switch self {
        case .correct:
            return ComboStage.correctFeedback(combo: combo)
        case .incorrect:
            return .error
        }
    }

    /// 鳴らす効果音。正解音はコンボに応じて音程が上がる
    /// - Parameter combo: この解答を反映した後の連続正解数
    func sound(combo: Int) -> SoundEffect {
        switch self {
        case .correct:
            return .correct(combo: combo)
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
    /// この解答を反映した後の連続正解数。振動の強さを決めるのに使う
    var combo: Int = 0

    var sensoryFeedback: SensoryFeedback {
        result.sensoryFeedback(combo: combo)
    }
}
