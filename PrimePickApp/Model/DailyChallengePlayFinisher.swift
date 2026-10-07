//
//  DailyChallengePlayFinisher.swift
//  PrimePickApp
//

import Foundation

/// デイリーチャレンジの終わりの処理。自己ベストではなく、その日の記録を保存する
///
/// 1 問解くごとに途中経過を保存し、強制終了されても「未完了 3 / 10」を出せるようにする（Discussion #181 本文 2-3）。
/// 記録の日付は始めた時点の `startedRecord.dayKey` のまま変えないので、23:59 に始めて 0:01 に解き終えても始めた日の記録になる。
struct DailyChallengePlayFinisher: QuizPlayFinishing {
    /// 始めた時点で保存した記録
    let startedRecord: DailyChallengeRecord
    let store: any DailyChallengeStore
    /// 現在時刻。テストのために差し替えられる
    var now: () -> Date = Date.init

    func recordProgress(_ outcome: QuizPlayOutcome) {
        store.save(startedRecord.applying(answerRecords: outcome.answerRecords))
    }

    /// 解き終えた記録を保存する。デイリーには自己ベストが無いので NEW RECORD! は出さない
    func finish(_ outcome: QuizPlayOutcome) -> Bool {
        var record = startedRecord.applying(answerRecords: outcome.answerRecords)
        record.completedAt = now()
        store.save(record)
        return false
    }
}
