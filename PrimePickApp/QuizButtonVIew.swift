//
//  QuizButtonVIew.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/22.
//

import SwiftUI

struct QuizButtonVIew: View {
    var quizData: [PrimeQuizEntity]
    @Binding var quizNumber: Int

    var body: some View {
        ZStack {
            Color.gray
            
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            
            Text(quizData.first?.number.description ?? "")
        }
    }
}
