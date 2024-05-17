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
    let manager = QuizDataManager()
    let quizData: [PrimeQuizEntity]

    @State private var quizNumber: Int = 1
    
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
        quizData = manager.makeQuizData()
    }

    var body: some View {
        VStack {
            Text(quizData.first?.number.description ?? "nodata")
            HStack {
                Button {
                    print("正解")
                } label: {
                    Text("正解")
                }
                
                Button {
                    print("不正解")
                } label: {
                    Text("不正解")
                }
            }
        }
        .onAppear {
            print(quizData)
        }
    }
}

#Preview {
    QuizView(difficulty: "Easy")
}
