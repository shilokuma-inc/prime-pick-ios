//
//  TimeAttackPlayRecord.swift
//  PrimePickApp
//

import Foundation
import SwiftData

/// タイムアタックの 1 プレイの記録（Discussion #223 Q4）
///
/// 画面や集計はこの値で扱い、SwiftData の型（`StoredTimeAttackPlay`）には触らない。
/// 正答率は正解数と解答数から求められるので保存しない。
struct TimeAttackPlayRecord: Equatable {
    /// プレイを終えた日時
    let playedAt: Date
    let duration: TimeAttackDuration
    let difficulty: Difficulty
    let score: Int
    let correctCount: Int
    /// 解答した問題の数。時間切れで解かなかった問題は含まない
    let answeredCount: Int
    /// 最大コンボ（連続正解数の最大）
    let maxCombo: Int

    /// 記録の区分に使うモード
    var gameMode: GameMode {
        .timeAttack(duration)
    }

    /// 正答率（0〜1）。1 問も解いていなければ nil
    var accuracy: Double? {
        guard answeredCount > 0 else { return nil }
        return Double(correctCount) / Double(answeredCount)
    }
}

/// SwiftData に保存する 1 プレイの記録。`TimeAttackPlayRecord` との変換は `SwiftDataTimeAttackRecordStore` だけが行う
///
/// 区分は `GameMode.id`（例 `timeAttack_30`）と `Difficulty.rawValue` を文字列で持ち、そのまま絞り込みに使う。
/// 列挙型を直接持たないのは、値を足し引きしても保存済みの記録を読めるようにするため。
@Model
final class StoredTimeAttackPlay {
    var playedAt: Date
    /// `GameMode.id`（例 `timeAttack_30`）
    var gameModeID: String
    var timeLimitSeconds: Int
    /// `Difficulty.rawValue`
    var difficulty: String
    var score: Int
    var correctCount: Int
    var answeredCount: Int
    var maxCombo: Int

    init(_ record: TimeAttackPlayRecord) {
        playedAt = record.playedAt
        gameModeID = record.gameMode.id
        timeLimitSeconds = record.duration.seconds
        difficulty = record.difficulty.rawValue
        score = record.score
        correctCount = record.correctCount
        answeredCount = record.answeredCount
        maxCombo = record.maxCombo
    }

    /// 画面や集計で使う値。今のアプリが知らない制限時間・難易度の記録は nil（読み飛ばす）
    var record: TimeAttackPlayRecord? {
        guard let duration = TimeAttackDuration(rawValue: timeLimitSeconds),
              let difficulty = Difficulty(rawValue: self.difficulty)
        else { return nil }
        return TimeAttackPlayRecord(
            playedAt: playedAt,
            duration: duration,
            difficulty: difficulty,
            score: score,
            correctCount: correctCount,
            answeredCount: answeredCount,
            maxCombo: maxCombo
        )
    }
}
