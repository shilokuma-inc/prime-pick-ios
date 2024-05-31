//
//  QuizContentView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/31.
//

import SwiftUI

struct QuizContentView: View {
    @Binding var quizNumber: Int
    let difficulty: Difficulty
    let quizData: [QuizEntity]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                switch difficulty {
                case .easy:
                    Color("appGreen")
                        .opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                case .normal:
                    Color.blue
                        .opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                case .hard:
                    Color.red
                        .opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                }

                VStack(spacing: .zero) {
                    QuizIndexView(difficulty: difficulty, quizNumber: $quizNumber)
                        .frame(height: geometry.size.height / 6)
                    
                    QuizNumberView(
                        quizNumber: $quizNumber,
                        difficulty: difficulty,
                        quizData: quizData
                    )
                    .frame(height: geometry.size.height * 2 / 3)
                    
                    QuizTimeLimitView(difficulty: difficulty)
                        .frame(height: geometry.size.height / 6)
                }
            }
        }
    }
}

struct QuizContentView_Previews: PreviewProvider {
    @State static var quizNumber = 0
    
    static var previews: some View {
        QuizContentView(
            quizNumber: $quizNumber,
            difficulty: .easy,
            quizData: [QuizEntity(quizId: 0, number: 3, isCorrect: true)]
        )
    }
}
