//
//  QuizView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/15.
//

import SwiftUI

struct QuizView: View {
    @Environment(\.dismiss) private var dismiss
    
    let primeData = PrimeData()
    var primes: [Int]
    let difficulty: String
    let manager = QuizDataManager()
    let quizData: [PrimeQuizEntity]

    @State private var quizNumber: Int = 0
    
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
            Text(quizData[quizNumber].number.description)
            HStack {
                if quizNumber < 9 {
                    Button {
                        print("正解")
                        if quizNumber < 9 {
                            quizNumber += 1
                        } else {
//                            dismiss()
                        }
                    } label: {
                        Text("正解")
                    }
                    
                    Button {
                        print("不正解")
                        if quizNumber < 9 {
                            quizNumber += 1
                        } else {
//                            dismiss()
                        }
                    } label: {
                        Text("不正解")
                    }
                } else {
                    Text("終わり")
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
