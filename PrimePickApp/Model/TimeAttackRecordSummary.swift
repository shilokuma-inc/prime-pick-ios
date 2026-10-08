//
//  TimeAttackRecordSummary.swift
//  PrimePickApp
//

import Foundation

/// 1 つの区分（制限時間 × 難易度）の記録から、記録画面に出す TOP 10 と推移を求める（Discussion #223 Q4）
///
/// 記録の並びから毎回計算し、別には保存しない。渡された記録の区分は確かめない（`TimeAttackRecordStore.records` で絞ってから渡す）。
struct TimeAttackRecordSummary: Equatable {
    /// TOP に出す件数
    static let topLimit = 10
    /// 推移に出す件数（直近の記録から数える）
    static let trendLimit = 20

    /// スコアの高い順に最大 `topLimit` 件。同点は先に出したほうを上にする（後から並んでも順位を奪わない）
    let top: [TimeAttackPlayRecord]
    /// 直近の最大 `trendLimit` 件を古い順に並べたもの
    let trend: [TimeAttackPlayRecord]

    /// - Parameter records: 1 つの区分の記録（順不同）
    init(records: [TimeAttackPlayRecord]) {
        top = Array(
            records.sorted { lhs, rhs in
                lhs.score != rhs.score ? lhs.score > rhs.score : lhs.playedAt < rhs.playedAt
            }
            .prefix(Self.topLimit)
        )
        trend = Array(records.sorted { $0.playedAt < $1.playedAt }.suffix(Self.trendLimit))
    }
}
