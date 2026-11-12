//
//  QuizEntity.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/16.
//

import Foundation
import QuizCore

struct QuizEntity: Equatable {
    var quizId: Int
    var number: Int
    var isCorrect: Bool
    /// この問題の難易度
    ///
    /// 練習・タイムアタックでは全問がプレイの設定と同じ値を持つ。
    /// デイリーチャレンジのように 1 プレイの中で難易度が変わる出題に備え、問題ごとに持たせている。
    var difficulty: Difficulty
    /// この問題の出題レンジ。`difficulty` と同じく問題ごとに持つ
    var range: QuizRange

    init(quizId: Int, number: Int, isCorrect: Bool, difficulty: Difficulty, range: QuizRange) {
        self.quizId = quizId
        self.number = number
        self.isCorrect = isCorrect
        self.difficulty = difficulty
        self.range = range
    }
}

// QuizKit の `QuizSession` で進める。選択肢は「素数ではない / 素数」の 2 つで固定（左右の並びは `QuizButtonView` が決める）
extension QuizEntity: QuizQuestion {
    var choices: [AnswerChoice] { [.notPrime, .prime] }

    func isCorrect(_ choice: AnswerChoice) -> Bool {
        choice.isPrime == isCorrect
    }

    var scoreFactor: Double {
        difficulty.scoreFactor
    }
}
