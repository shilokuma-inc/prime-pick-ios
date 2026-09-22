//
//  QuizView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/15.
//

import SwiftUI

struct QuizView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var quizNumber: Int = 0
    @State var isPresentedResult: Bool = false
    @State private var scoreCalculator = ScoreCalculator()
    @State private var answerRecords: [QuizAnswerRecord] = []
    /// 現在の問題が表示された時刻。速度ボーナスの計測基準
    @State private var questionStartDate: Date = Date()

    let primeData = PrimeData()
    let difficulty: Difficulty
    let manager = QuizDataManager()
    let quizData: [QuizEntity]

    init(difficulty: Difficulty) {
        self.difficulty = difficulty
        quizData = manager.makeQuizData(difficulty: difficulty)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: .zero) {
                    QuizContentView(
                        quizNumber: $quizNumber,
                        difficulty: difficulty,
                        quizData: quizData,
                        currentCombo: scoreCalculator.currentCombo
                    )
                    .frame(height: geometry.size.height / 2)

                    Spacer()

                    QuizButtonView(
                        quizData: quizData,
                        difficulty: difficulty,
                        questionStartDate: questionStartDate,
                        scoreCalculator: $scoreCalculator,
                        quizIndex: $quizNumber,
                        isPresentedResult: $isPresentedResult,
                        answerRecords: $answerRecords
                    )
                    .frame(height: geometry.size.height / 3)

                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)

                if isPresentedResult {
                    QuizResultView(
                        score: scoreCalculator.totalScore,
                        correctCount: scoreCalculator.correctCount,
                        maxCombo: scoreCalculator.maxCombo,
                        answerRecords: answerRecords
                    )
                }
            }
        }
        .sendAnalyticsScreen(.quiz)
        .onAppear {
            print(quizData)
            // 1 問目が表示された時点を経過時間の基準にする
            questionStartDate = Date()
        }
        .onChange(of: quizNumber) { _, _ in
            // 次の問題に切り替わった時点を経過時間の基準にする
            questionStartDate = Date()
        }
    }
}

#Preview {
    QuizView(difficulty: .easy)
}
