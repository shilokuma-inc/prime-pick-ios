//
//  TimeAttackBestScores.swift
//  PrimePickApp
//

import Foundation

/// タイトル画面の難易度ボタンに出す、タイムアタックの自己ベスト（#548）
///
/// 制限時間 × 難易度の 12 枠の 1 位を、記録画面と同じ `TimeAttackRecordStore` からまとめて読んでおく。
/// モードを切り替えるたびに読み直さずに済むよう、全部の制限時間の分を持つ。
/// 撮影モードでは読まない（App Store のスクリーンショットのホーム画面を、端末に残った記録で変えない）。
struct TimeAttackBestScores: Equatable {
    private let scores: [TimeAttackDuration: [Difficulty: Int]]
    private let isScreenshotDemo: Bool

    /// 記録から読む。プレイを終えてタイトルに戻るたびに読み直す
    static func load(
        store: TimeAttackRecordStore = TimeAttackRecordStore(),
        isScreenshotDemo: Bool = ScreenshotDemo.isEnabled
    ) -> TimeAttackBestScores {
        guard !isScreenshotDemo else {
            return TimeAttackBestScores(scores: [:], isScreenshotDemo: true)
        }
        var scores: [TimeAttackDuration: [Difficulty: Int]] = [:]
        for duration in TimeAttackDuration.allCases {
            for difficulty in Difficulty.allCases {
                if let best = store.bestScore(gameMode: .timeAttack(duration), difficulty: difficulty) {
                    scores[duration, default: [:]][difficulty] = best
                }
            }
        }
        return TimeAttackBestScores(scores: scores, isScreenshotDemo: false)
    }

    /// 難易度ボタンに出す自己ベスト。記録の無い難易度は入らない
    ///
    /// 練習（スコアを記録しない）と撮影モードでは nil を返し、ボタンに自己ベストの行を出さない。
    func bestScores(for gameMode: GameMode) -> [Difficulty: Int]? {
        guard !isScreenshotDemo, case .timeAttack(let duration) = gameMode else { return nil }
        return scores[duration] ?? [:]
    }
}
