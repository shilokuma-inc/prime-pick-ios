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
            switch difficulty {
            case .easy:
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.green, lineWidth: 5)
                    .background(RoundedRectangle(cornerRadius: 25).fill(Color.white))
                    .frame(width: 300, height: 200)
                    .shadow(radius: 10)

            case .normal:
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.blue, lineWidth: 5)
                    .background(RoundedRectangle(cornerRadius: 25).fill(Color.white))
                    .frame(width: 300, height: 200)
                    .shadow(radius: 10)

            case .hard:
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.red, lineWidth: 5)
                    .background(RoundedRectangle(cornerRadius: 25).fill(Color.white))
                    .frame(width: 300, height: 200)
                    .shadow(radius: 10)
            }
            
            switch difficulty {
            case .easy:
                Text(quizData[quizNumber].number.description)
                    .font(.custom("ArialRoundedMTBold", size: 180))
                    .foregroundStyle(Color.gray)
            case .normal, .hard:
                Text(quizData[quizNumber].number.description)
                    .font(.custom("ArialRoundedMTBold", size: 120))
                    .foregroundStyle(Color.gray)
            }
        }
    }
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
