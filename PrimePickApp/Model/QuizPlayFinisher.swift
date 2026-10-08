//
//  QuizPlayFinisher.swift
//  PrimePickApp
//

import Foundation

/// 1 プレイを終えたときの結果。プレイの終わりの処理（`QuizPlayFinishing`）に渡す
struct QuizPlayOutcome: Equatable {
    let gameMode: GameMode
    /// プレイの設定の難易度。問題ごとの難易度は `QuizEntity.difficulty` を参照する
    let difficulty: Difficulty
    let score: Int
    let correctCount: Int
    /// 解答した問題の記録（出題順）。時間切れなどで解かなかった問題は含まない
    let answerRecords: [QuizAnswerRecord]
    /// 最大コンボ（連続正解数の最大）。タイムアタックの 1 プレイの記録に残す
    var maxCombo: Int = 0
    /// 画面に表示している問題（1 始まり）。解答後のミニ解説の間は、解いたばかりの問題のまま
    var shownQuestionNumber: Int?
}

/// プレイの終わりの処理
///
/// 結果画面を出す時点で `QuizView` から 1 プレイにつき 1 回だけ呼ばれる。
/// 練習・タイムアタックは自己ベストを記録する `BestScorePlayFinisher` を使い、
/// デイリーチャレンジのように終わりに別の記録を残すプレイは、この型を差し替えて載せる。
protocol QuizPlayFinishing {
    /// 1 問解答するごとに呼ばれる。途中経過を残したいプレイ（強制終了に備えるデイリーなど）だけが実装する
    func recordProgress(_ outcome: QuizPlayOutcome)
    /// 終わりの処理を行い、結果画面に出す過去の記録との比べを返す
    func finish(_ outcome: QuizPlayOutcome) -> QuizPlayFinishResult
    /// 途中でやめたときに呼ばれる。解答済みまでで結果を確定したいプレイ（デイリー）だけが実装する
    func abandon(_ outcome: QuizPlayOutcome)
}

/// プレイの終わりの処理の結果。結果画面に出す
struct QuizPlayFinishResult: Equatable {
    /// 自己ベストを更新したか（NEW RECORD! を出すか）
    var isNewRecord = false
    /// 自己ベストとの比べ。比べないプレイ（練習・デイリー）や初回は nil
    var bestScoreComparison: BestScoreComparison?
    /// 前回（同じ区分で直前に記録したプレイ）のスコアとの差（Discussion #223 Q4）。前回の記録が無ければ nil
    var previousScoreDifference: Int?
}

extension QuizPlayFinishing {
    func recordProgress(_ outcome: QuizPlayOutcome) {}
    func abandon(_ outcome: QuizPlayOutcome) {}
}

/// 練習・タイムアタックの終わりの処理。タイムアタックの自己ベストと 1 プレイの記録を残す
///
/// 1 プレイの記録はタイムアタックだけに残す（Discussion #223 Q5）。途中でやめたプレイ（`finish` を通らないプレイ）は残さない。
/// 自己ベストは履歴を始める前からの値を引き継ぐため、これまでどおり `BestScoreStore` にも記録する。
struct BestScorePlayFinisher: QuizPlayFinishing {
    var store = BestScoreStore()
    /// 1 プレイの記録の保存先。nil なら残さない
    var recordStore: (any TimeAttackRecordStore)?
    /// 記録に残す日時
    var now: () -> Date = Date.init

    func finish(_ outcome: QuizPlayOutcome) -> QuizPlayFinishResult {
        var previousScoreDifference: Int?
        if let recordStore, case .timeAttack(let duration) = outcome.gameMode {
            // 保存する前に読み、今回のプレイを前回と取り違えないようにする
            let previous = recordStore.records(gameMode: outcome.gameMode, difficulty: outcome.difficulty).last
            previousScoreDifference = previous.map { outcome.score - $0.score }
            recordStore.save(TimeAttackPlayRecord(
                playedAt: now(),
                duration: duration,
                difficulty: outcome.difficulty,
                score: outcome.score,
                correctCount: outcome.correctCount,
                answeredCount: outcome.answerRecords.count,
                maxCombo: outcome.maxCombo
            ))
        }
        let update = store.record(score: outcome.score, gameMode: outcome.gameMode, difficulty: outcome.difficulty)
        return QuizPlayFinishResult(
            isNewRecord: update.isNewRecord,
            bestScoreComparison: update.comparison,
            previousScoreDifference: previousScoreDifference
        )
    }
}
