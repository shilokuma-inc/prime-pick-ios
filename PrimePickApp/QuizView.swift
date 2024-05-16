//
//  QuizView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/15.
//

import SwiftUI

struct QuizView: View {
    let primeData = PrimeData()
    var primes: [Int]
    let difficulty: String
    var quizData: [PrimeQuizEntity] = []
    
    init(difficulty: String) {
        self.difficulty = difficulty
        if self.difficulty == "Easy" {
            primes = primeData.generateOneOrTwoDigitPrimes()
        } else if self.difficulty == "Normal" {
            primes = primeData.generateThreeDigitPrimes()
        } else if self.difficulty == "Hard" {
            primes = primeData.generateFourDigitPrimes()
        } else {
            primes = []
        }
        for i in 1...10 {
            let randomInt = Int.random(in: 10...99)
            let primeQuizEntity = PrimeQuizEntity(quizId: i, number: randomInt, isCorrect: true)
            quizData.append(primeQuizEntity)
        }
    }

    var body: some View {
        List(primes, id: \.self) { prime in
            Text("\(prime)")
        }
        .navigationTitle("Primes")
        Text(quizData.description)
    }
}

#Preview {
    QuizView(difficulty: "Easy")
}
