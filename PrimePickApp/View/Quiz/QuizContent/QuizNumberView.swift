//
//  QuizNumberView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/17.
//

import SwiftUI

struct QuizNumberView: View {
    @Binding var quizNumber: Int
    let difficulty: Difficulty
    let quizData: [QuizEntity]
    
    var body: some View {
        ZStack {
            quizNumberBackgroundView(difficulty: difficulty)
            
            quizNumberText(
                quizNumber: quizNumber,
                difficulty: difficulty,
                quizData: quizData
            )
        }
    }
}

private func quizNumberBackgroundView(difficulty: Difficulty) -> some View {
    let color = if difficulty == .easy {
        Color.appGreen
    } else if difficulty == .normal {
        Color.blue
    } else {
        Color.red
    }
    
    return RoundedRectangle(cornerRadius: 25)
        .stroke(color, lineWidth: 5)
        .frame(width: 300, height: 200)
        .shadow(radius: 10)
        .background(
            RoundedRectangle(cornerRadius: 25).fill(Color.white)
        )
}

private func quizNumberText(quizNumber: Int, difficulty: Difficulty, quizData: [QuizEntity]) -> some View {
    let size: CGFloat = if difficulty == .easy {
        180
    } else {
        120
    }
    
    return Text(quizData[quizNumber].number.description)
        .font(.custom("ArialRoundedMTBold", size: size))
        .foregroundStyle(Color.gray)
}

struct QuizNumberView_Previews: PreviewProvider {
    @State static var quizNumber = 3
    
    static var previews: some View {
        QuizNumberView(
            quizNumber: $quizNumber,
            difficulty: .easy,
            quizData: [QuizEntity(quizId: 0, number: 3, isCorrect: true)]
        )
    }
}
