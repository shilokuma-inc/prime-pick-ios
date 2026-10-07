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
}

/// プレイの終わりの処理
///
/// 結果画面を出す時点で `QuizView` から 1 プレイにつき 1 回だけ呼ばれる。
/// 練習・タイムアタックは自己ベストを記録する `BestScorePlayFinisher` を使い、
/// デイリーチャレンジのように終わりに別の記録を残すプレイは、この型を差し替えて載せる。
protocol QuizPlayFinishing {
    /// 終わりの処理を行い、自己ベストを更新したか（結果画面に NEW RECORD! を出すか）を返す
    func finish(_ outcome: QuizPlayOutcome) -> Bool
}

/// 練習・タイムアタックの終わりの処理。タイムアタックの自己ベストを記録する
struct BestScorePlayFinisher: QuizPlayFinishing {
    var store = BestScoreStore()

    func finish(_ outcome: QuizPlayOutcome) -> Bool {
        store.record(score: outcome.score, gameMode: outcome.gameMode, difficulty: outcome.difficulty)
    }
}
