//
//  AnswerFeedback.swift
//  PrimePickApp
//

import Foundation

/// 解答結果に対して返すフィードバックの種類
enum AnswerFeedback {
    case correct
    case incorrect

    var haptic: HapticFeedback.Pattern {
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

/// アニメーション再生のきっかけ
///
/// 同じ結果が連続しても View 側で変化を検知できるよう、解答ごとに増える `id` を持たせている。
struct AnswerFeedbackTrigger: Equatable {
    let id: Int
    let result: AnswerFeedback
}

/// 触覚と効果音をまとめて再生する窓口
@MainActor
enum AnswerFeedbackPlayer {
    /// 初回再生の遅延を減らすため、解答が行われる画面の表示時に呼ぶ
    static func prepare() {
        HapticFeedback.shared.prepare()
    }

    /// 触覚・効果音とも再生完了を待たずに制御を返すため、次の問題への遷移をブロックしない
    static func play(_ result: AnswerFeedback) {
        HapticFeedback.shared.play(result.haptic)
        SoundFeedback.play(result.sound)
    }
}
