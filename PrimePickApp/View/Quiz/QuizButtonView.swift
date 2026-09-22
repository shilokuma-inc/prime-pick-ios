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
    @Binding var scoreCalculator: ScoreCalculator
    @Binding var questionStartDate: Date
    @Binding var quizIndex: Int
    @Binding var isPresentedResult: Bool

    var body: some View {
        ZStack {
            HStack {
                Spacer()

                quizButton(option: "Incorrect")
                .onTapGesture {
                    answer(selectedIsPrime: false)
                }

                Spacer()

                quizButton(option: "Correct")
                .onTapGesture {
                    answer(selectedIsPrime: true)
                }

                Spacer()
            }
        }
    }

    /// 解答をスコアに反映し、次の問題へ進める
    private func answer(selectedIsPrime: Bool) {
        if !isPresentedResult {
            let elapsedTime = Date().timeIntervalSince(questionStartDate)
            scoreCalculator.submit(
                isCorrect: quizData[quizIndex].isCorrect == selectedIsPrime,
                difficulty: difficulty,
                elapsedTime: elapsedTime
            )
        }
        if quizIndex < 9 {
            quizIndex += 1
            // 次の問題が表示された時点を経過時間の基準にする
            questionStartDate = Date()
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
