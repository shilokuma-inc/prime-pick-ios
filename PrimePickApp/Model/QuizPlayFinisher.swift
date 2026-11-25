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
    /// 画面に表示している問題（1 始まり）。解答後のミニ解説の間は、解いたばかりの問題のまま
    var shownQuestionNumber: Int?
}

/// プレイの終わりの処理が返す、結果画面に出すもの
struct QuizPlayFinishResult: Equatable {
    /// 自己ベストを更新したか（結果画面に NEW RECORD! を出すか）
    var isNewRecord = false
    /// タイムアタックの、それまでの記録との比べ（#549）。タイムアタック以外は nil
    var timeAttackComparison: TimeAttackComparison?
}

/// プレイの終わりの処理
///
/// 結果画面を出す時点で `QuizView` から 1 プレイにつき 1 回だけ呼ばれる。
/// 練習・タイムアタックは自己ベストを記録する `BestScorePlayFinisher` を使い、
/// デイリーチャレンジのように終わりに別の記録を残すプレイは、この型を差し替えて載せる。
protocol QuizPlayFinishing {
    /// 1 問解答するごとに呼ばれる。途中経過を残したいプレイ（強制終了に備えるデイリーなど）だけが実装する
    func recordProgress(_ outcome: QuizPlayOutcome)
    /// 終わりの処理を行い、結果画面に出すもの（NEW RECORD! と、タイムアタックのそれまでの記録との比べ）を返す
    @discardableResult
    func finish(_ outcome: QuizPlayOutcome) -> QuizPlayFinishResult
    /// 途中でやめたときに呼ばれる。解答済みまでで結果を確定したいプレイ（デイリー）だけが実装する
    func abandon(_ outcome: QuizPlayOutcome)
}

extension QuizPlayFinishing {
    func recordProgress(_ outcome: QuizPlayOutcome) {}
    func abandon(_ outcome: QuizPlayOutcome) {}
}

/// 練習・タイムアタックの終わりの処理。タイムアタックの記録と履歴を残し、自己ベスト（1 位）を更新したかと、それまでの記録との比べを返す
///
/// 練習はスコアを比べないので何も残さない。
struct BestScorePlayFinisher: QuizPlayFinishing {
    var store = TimeAttackRecordStore()
    /// 1 プレイごとの履歴（#549）。前回との差と、記録画面の推移グラフに使う
    var history = TimeAttackPlayHistoryStore()

    @discardableResult
    func finish(_ outcome: QuizPlayOutcome) -> QuizPlayFinishResult {
        let gameMode = outcome.gameMode
        let difficulty = outcome.difficulty
        guard gameMode.isTimeAttack else { return QuizPlayFinishResult() }
        // 記録する前の上位と前回のスコアと比べる
        let comparison = TimeAttackComparison(
            score: outcome.score,
            recordsBefore: store.records(gameMode: gameMode, difficulty: difficulty),
            previousScore: history.lastScore(gameMode: gameMode, difficulty: difficulty)
        )
        let isNewRecord = store.record(score: outcome.score, gameMode: gameMode, difficulty: difficulty)
        history.record(score: outcome.score, gameMode: gameMode, difficulty: difficulty)
        return QuizPlayFinishResult(isNewRecord: isNewRecord, timeAttackComparison: comparison)
    }
}
