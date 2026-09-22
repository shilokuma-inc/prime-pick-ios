//
//  QuizAnswerRecord.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2026/09/22.
//

import Foundation

/// 1 問ごとの解答結果。リザルトの復習一覧で使う。
struct QuizAnswerRecord: Identifiable, Equatable {
    /// 出題順（`QuizEntity.quizId` と同じ）
    let id: Int
    /// 出題された数
    let number: Int
    /// 正解。出題された数が素数なら `true`
    let isPrime: Bool
    /// ユーザーの解答。素数だと答えたなら `true`
    let answeredPrime: Bool

    /// ユーザーの解答が正解と一致したか
    var isAnswerCorrect: Bool {
        isPrime == answeredPrime
    }
}
