//
//  QuizDataManager.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/16.
//

import Foundation
import GameplayKit

class QuizDataManager {
    func makeQuizData(difficulty: String) -> [PrimeQuizEntity] {
        let primeData = PrimeData()
        var quizData: [PrimeQuizEntity] = []
        let timestamp = UInt64(Date().timeIntervalSince1970 * 1000)
        var generator = SeededGenerator(seed: timestamp)

        for i in 1...10 {
            var isCorrect: Bool = false
            var randomInt: Int = 0
            if difficulty == "Easy" {
                randomInt = Int.random(in: 1...99, using: &generator)
                let primeNumbers = primeData.generateOneOrTwoDigitPrimes()
                isCorrect = primeNumbers.contains(randomInt)
            }
            let primeQuizEntity = PrimeQuizEntity(quizId: i, number: randomInt, isCorrect: isCorrect)
            quizData.append(primeQuizEntity)
        }
        return quizData
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
