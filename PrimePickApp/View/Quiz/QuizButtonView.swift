//
//  QuizButtonView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/22.
//

import SwiftUI

struct QuizButtonView: View {
    var quizData: [QuizEntity]
    let difficulty: Difficulty
    /// 現在の問題が表示された時刻。速度ボーナスの計測基準
    let questionStartDate: Date
    @Binding var scoreCalculator: ScoreCalculator
    @Binding var quizIndex: Int
    @Binding var isPresentedResult: Bool
    @Binding var answerRecords: [QuizAnswerRecord]

    var body: some View {
        ZStack {
            HStack {
                Spacer()

                quizButton(option: "Incorrect")
                .onTapGesture {
                    answer(answeredPrime: false)
                }

                Spacer()

                quizButton(option: "Correct")
                .onTapGesture {
                    answer(answeredPrime: true)
                }

                Spacer()
            }
        }
    }

    /// 解答を記録してスコアに反映し、次の問題へ進める。最後の問題ならリザルトを表示する。
    private func answer(answeredPrime: Bool) {
        if !isPresentedResult {
            let quiz = quizData[quizIndex]
            let record = QuizAnswerRecord(
                id: quiz.quizId,
                number: quiz.number,
                isPrime: quiz.isCorrect,
                answeredPrime: answeredPrime
            )
            answerRecords.append(record)
            scoreCalculator.submit(
                isCorrect: record.isAnswerCorrect,
                difficulty: difficulty,
                elapsedTime: Date().timeIntervalSince(questionStartDate)
            )
        }
        if quizIndex < quizData.count - 1 {
            quizIndex += 1
        } else {
            isPresentedResult = true
        }
    }
}

private func quizButton(option: String) -> some View {
    ZStack {
        RoundedRectangle(cornerRadius: 25)
            .stroke(option == "Correct" ? Color.quizCorrectButton : Color.quizIncorrectButton, lineWidth: 5)
            .background(RoundedRectangle(cornerRadius: 25).fill(option == "Correct" ? Color.quizCorrectButton.opacity(0.1) : Color.quizIncorrectButton.opacity(0.1)))
            .frame(width: UIScreen.main.bounds.width * 2 / 5, height: UIScreen.main.bounds.height / 4)
            .shadow(radius: 10)
        
        if option == "Correct" {
            Text("✅")
                .font(.custom("ArialRoundedMTBold", size: 80))
        } else {
            Text("❌")
                .font(.custom("ArialRoundedMTBold", size: 80))
        }
    }
}
