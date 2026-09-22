//
//  QuizDataManager.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/16.
//

import Foundation
import GameplayKit

class QuizDataManager {
    func makeQuizData(
        difficulty: Difficulty,
        range: QuizRange,
        questionCount: QuizQuestionCount
    ) -> [QuizEntity] {
        var quizData: [QuizEntity] = []
        let timestamp = UInt64(Date().timeIntervalSince1970 * 1000)
        var generator = SeededGenerator(seed: timestamp)
        let bounds = range.bounds

        for i in 1...questionCount.value {
            var randomInt = Int.random(in: bounds, using: &generator)
            if difficulty.excludesMultiplesOfTwoThreeFive {
                while isMultipleOf235(randomInt) {
                    randomInt = Int.random(in: bounds, using: &generator)
                }
            }
            let isCorrect = PrimeFactorization.isPrime(randomInt)
            let primeQuizEntity = QuizEntity(quizId: i, number: randomInt, isCorrect: isCorrect)
            quizData.append(primeQuizEntity)
        }
        return quizData
    }

    func isMultipleOf235(_ number: Int) -> Bool {
        return number % 2 == 0 || number % 3 == 0 || number % 5 == 0
    }
}

/// シード値から決まった乱数列を作る `RandomNumberGenerator`。
///
/// `GKMersenneTwisterRandomSource` が一度に返すのは 32bit 分なので、2 回引いて 64bit に組み立てる。
/// 以前は `nextUniform()` の戻り値（`Float`）に `Float(UInt64.max)` を掛けていたが、
/// - `Float` の仮数部は 24bit しかなく、下位 40bit 前後が常に 0 になる
/// - `Float(UInt64.max)` は 2^64 に丸まるため、`nextUniform()` が 1.0 を返すと積が
///   `UInt64` の範囲を超えてクラッシュする（実測で約 428 万回に 1 回発生）
/// という問題があったため、整数のまま扱っている。
struct SeededGenerator: RandomNumberGenerator {
    private let source: GKMersenneTwisterRandomSource

    init(seed: UInt64) {
        source = GKMersenneTwisterRandomSource(seed: seed)
    }

    mutating func next() -> UInt64 {
        let high = UInt64(UInt32(bitPattern: Int32(truncatingIfNeeded: source.nextInt())))
        let low = UInt64(UInt32(bitPattern: Int32(truncatingIfNeeded: source.nextInt())))
        return high << 32 | low
    }
}
