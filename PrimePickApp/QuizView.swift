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
    }

    var body: some View {
        List(primes, id: \.self) { prime in
            Text("\(prime)")
        }
        .navigationTitle("Primes")
    }
}

#Preview {
    QuizView(difficulty: "Easy")
}
