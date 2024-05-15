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
    init() {
        primes = primeData.generateOneOrTwoDigitPrimes()
    }

    var body: some View {
        List(primes, id: \.self) { prime in
            Text("\(prime)")
        }
        .navigationTitle("Primes")
    }
}

#Preview {
    QuizView()
}
