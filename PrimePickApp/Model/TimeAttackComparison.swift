//
//  TimeAttackComparison.swift
//  PrimePickApp
//

import QuizCore

/// タイムアタックの 1 プレイを、それまでの自分の記録と比べた結果（#549）。結果画面に出す
///
/// 比べる相手は、このプレイを記録する前の上位 10 件（`TimeAttackRecordStore`）と履歴（`TimeAttackPlayHistoryStore`）。
struct TimeAttackComparison: Equatable {
    /// 自己ベスト（このプレイの前の 1 位）との差
    enum BestDifference: Equatable {
        /// 自己ベストを更新した（`NEW RECORD!`）
        case updated(by: Int)
        /// 自己ベストと同点（更新ではない）
        case tied
        /// 自己ベストに届かなかった
        case short(by: Int)
    }

    /// 自己ベストとの差。比べる自己ベストが無い（初めての記録）ときは nil
    let best: BestDifference?
    /// このプレイが上位 10 件の何位に入ったか（1 始まり）。入らなかった・0 点のときは nil
    let rank: Int?
    /// 同じ枠の 1 つ前のプレイとの差（このプレイ − 前回）。前回の履歴が無いときは nil
    let previousDifference: Int?

    /// - Parameters:
    ///   - recordsBefore: このプレイを記録する前の上位の記録（スコアの高い順）
    ///   - previousScore: 同じ枠の 1 つ前のプレイのスコア
    ///   - maxRank: 上位に残す件数
    init(score: Int, recordsBefore: [ScoreRecord], previousScore: Int?, maxRank: Int = TimeAttackRecordStore.maxRecordCount) {
        best = recordsBefore.first.map { best in
            if score > best.score {
                return .updated(by: score - best.score)
            } else if score == best.score {
                return .tied
            } else {
                return .short(by: best.score - score)
            }
        }
        // 上位の並びは「同点なら先に出した記録が上」（`LocalLeaderboard`）。同点の記録の後ろに入るので、同点も上に数える。
        // 0 点は上位に記録しないので順位も出さない
        let candidate = recordsBefore.filter { $0.score >= score }.count + 1
        rank = score > 0 && candidate <= maxRank ? candidate : nil
        previousDifference = previousScore.map { score - $0 }
    }
}
