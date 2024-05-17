//
//  QuizDataManager.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/16.
//

import Foundation

class QuizDataManager {
    func makeQuizData() -> [PrimeQuizEntity] {
        let primeData = PrimeData()
        var quizData: [PrimeQuizEntity] = []
        let primeNumbers = primeData.generateOneOrTwoDigitPrimes()
        for i in 1...10 {
            let randomInt = Int.random(in: 1...99)
            let isCorrect = primeNumbers.contains(randomInt)
            let primeQuizEntity = PrimeQuizEntity(quizId: i, number: randomInt, isCorrect: isCorrect)
            quizData.append(primeQuizEntity)
        }
        return quizData
    }
}
