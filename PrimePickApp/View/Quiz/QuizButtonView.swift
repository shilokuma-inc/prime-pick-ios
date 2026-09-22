//
//  QuizButtonView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/22.
//

import SwiftUI

struct QuizButtonView: View {
    var quizData: [QuizEntity]
    @Binding var correctQuizNumber: Int
    @Binding var quizIndex: Int
    @Binding var isPresentedResult: Bool
    @Binding var answerRecords: [QuizAnswerRecord]
    @State private var incorrectButtonTrigger: AnswerFeedbackTrigger?
    @State private var correctButtonTrigger: AnswerFeedbackTrigger?
    @State private var feedbackSequence: Int = 0

    var body: some View {
        ZStack {
            HStack {
                Spacer()

                quizButton(option: "Incorrect")
                .answerFeedbackEffect(trigger: incorrectButtonTrigger)
                .onTapGesture {
                    answer(answeredPrime: false)
                }

                Spacer()

                quizButton(option: "Correct")
                .answerFeedbackEffect(trigger: correctButtonTrigger)
                .onTapGesture {
                    answer(answeredPrime: true)
                }

                Spacer()
            }
        }
        .onAppear {
            AnswerFeedbackPlayer.prepare()
        }
    }

    /// 解答を記録してフィードバックを再生し、次の問題へ進める。最後の問題ならリザルトを表示する。
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
            if record.isAnswerCorrect {
                correctQuizNumber += 1
            }
            playFeedback(
                record.isAnswerCorrect ? .correct : .incorrect,
                on: answeredPrime ? .correct : .incorrect
            )
        }
        if quizIndex < quizData.count - 1 {
            quizIndex += 1
        } else {
            isPresentedResult = true
        }
    }

    /// タップされたボタン
    private enum TappedButton {
        case correct
        case incorrect
    }

    /// 触覚・効果音を再生し、タップされたボタンにアニメーションのきっかけを渡す
    ///
    /// いずれも再生完了を待たないため、この直後の次の問題への遷移をブロックしない。
    private func playFeedback(_ result: AnswerFeedback, on button: TappedButton) {
        AnswerFeedbackPlayer.play(result)

        // 同じ結果が続いてもアニメーションが再生されるよう、解答ごとに異なる ID を発行する
        feedbackSequence += 1
        let trigger = AnswerFeedbackTrigger(id: feedbackSequence, result: result)
        switch button {
        case .correct:
            correctButtonTrigger = trigger
        case .incorrect:
            incorrectButtonTrigger = trigger
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
