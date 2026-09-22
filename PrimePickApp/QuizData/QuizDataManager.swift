//
//  QuizDataManager.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/16.
//

import Foundation
import GameplayKit

class QuizDataManager {
    func makeQuizData(difficulty: Difficulty) -> [QuizEntity] {
        var quizData: [QuizEntity] = []
        let timestamp = UInt64(Date().timeIntervalSince1970 * 1000)
        var generator = SeededGenerator(seed: timestamp)

        for i in 1...10 {
            var randomInt: Int = 0
            switch difficulty {
            case .easy:
                randomInt = Int.random(in: 1...99, using: &generator)
            case .normal:
                randomInt = Int.random(in: 100...999, using: &generator)
            case .hard:
                repeat {
                    randomInt = Int.random(in: 100...999, using: &generator)
                } while isMultipleOf235(randomInt)
            }
            let isCorrect = PrimeData.isPrime(randomInt)
            let primeQuizEntity = QuizEntity(quizId: i, number: randomInt, isCorrect: isCorrect)
            quizData.append(primeQuizEntity)
        }
        return quizData
    }

    func isMultipleOf235(_ number: Int) -> Bool {
        return number % 2 == 0 || number % 3 == 0 || number % 5 == 0
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var rng: GKMersenneTwisterRandomSource

    init(seed: UInt64) {
        rng = GKMersenneTwisterRandomSource(seed: seed)
    }

    mutating func next() -> UInt64 {
        return UInt64(rng.nextUniform() * Float(UInt64.max))
    }
}
