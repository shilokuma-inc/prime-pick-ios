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
            VStack(spacing: .zero) {
                QuizTimeLimitView(difficulty: difficulty)
                    .frame(height: geometry.size.height)
            }
        }
    }
}

struct QuizContentView_Previews: PreviewProvider {
    @State static var quizNumber = 3
    
    static var previews: some View {
        QuizContentView(
            quizNumber: $quizNumber,
            difficulty: .easy,
            quizData: [QuizEntity(quizId: 0, number: 3, isCorrect: true)]
        )
    }
}
