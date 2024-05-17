//
//  QuizNumberView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/17.
//

import SwiftUI

struct QuizNumberView: View {
    @Binding var quizNumber: Int
    let quizData: [PrimeQuizEntity]
    
    var body: some View {
        Text(quizData[quizNumber].number.description)
    }
}

struct QuizNumberView_Previews: PreviewProvider {
    @State static var quizNumber = 3
    
    static var previews: some View {
        QuizNumberView(quizNumber: $quizNumber, quizData: [PrimeQuizEntity(quizId: 0, number: 3, isCorrect: true)])
    }
}
