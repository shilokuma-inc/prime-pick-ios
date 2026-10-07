//
//  DailyChallengeRecord.swift
//  PrimePickApp
//

import Foundation

/// デイリーチャレンジ 1 問分の結果
enum DailyChallengeAnswerResult: String, Codable, Equatable {
    case correct
    case incorrect
    /// 途中でやめた・強制終了したなどで解かなかった問題
    case unanswered
}

/// デイリーチャレンジ 1 日分の記録（Discussion #181 本文 4 章）
///
/// 始めた時点で保存し（`startedAt` だけを持つ未完了の記録）、解き終えたら `completedAt` を入れる。
/// 途中でやめた・強制終了した日は `completedAt` が無いまま残り、その日の挑戦権を使った扱いになる。
/// ストリークはこの記録の日付の並びから計算し、別には保存しない。
struct DailyChallengeRecord: Codable, Equatable {
    /// どの日のデイリーか（`2026-10-01` の形式。`DailyChallengeDay.dayKey`）
    let dayKey: String
    /// 出題に使った生成器の版（`DailyChallengeGenerator.version`）
    let generatorVersion: Int
    /// 始めた時刻。23:59 に始めて 0:01 に解き終えても、記録は始めた日（`dayKey`）のものになる
    let startedAt: Date
    /// 解き終えた時刻。nil なら未完了
    var completedAt: Date?
    /// 問題ごとの結果（出題順）。始めた時点では全問 `unanswered`
    var results: [DailyChallengeAnswerResult]
    /// 解答ごとの経過時間（問題が表示されてから解答するまで）の合計。ミニ解説の表示時間は含めない
    var totalAnswerSeconds: TimeInterval

    /// 始めた時点の記録。全問を未解答にしておく
    static func started(
        dayKey: String,
        generatorVersion: Int,
        questionCount: Int,
        startedAt: Date
    ) -> DailyChallengeRecord {
        DailyChallengeRecord(
            dayKey: dayKey,
            generatorVersion: generatorVersion,
            startedAt: startedAt,
            completedAt: nil,
            results: Array(repeating: .unanswered, count: questionCount),
            totalAnswerSeconds: 0
        )
    }

    /// 最後まで解いたか。ストリークに数えるのはこの日だけ
    var isCompleted: Bool {
        completedAt != nil
    }

    var correctCount: Int {
        results.filter { $0 == .correct }.count
    }

    /// 解答した問題数（「未完了 3 / 10」の 3）
    var answeredCount: Int {
        results.filter { $0 != .unanswered }.count
    }
}
