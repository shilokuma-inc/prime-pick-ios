//
//  QuizButtonView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/22.
//

import SwiftUI

struct QuizButtonView: View {
    var quizData: [PrimeQuizEntity]
    @Binding var quizNumber: Int

    var body: some View {
        ZStack {
            Color.gray
            
            VStack {
                
                Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                
                Text(quizData[quizNumber].quizId.description)
                
                Text(quizData[quizNumber].number.description)
                
                Text(quizData[quizNumber].isCorrect.description)
            }
            
            HStack {
                Spacer()
                
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.pink, lineWidth: 5)
                    .background(RoundedRectangle(cornerRadius: 25).fill(Color.white))
                    .frame(width: UIScreen.main.bounds.width * 2 / 5, height: UIScreen.main.bounds.height / 4)
                    .shadow(radius: 10)
                    .onTapGesture {
                        print("❌")
                    }
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.cyan, lineWidth: 5)
                    .background(RoundedRectangle(cornerRadius: 25).fill(Color.white))
                    .frame(width: UIScreen.main.bounds.width * 2 / 5, height: UIScreen.main.bounds.height / 4)
                    .shadow(radius: 10)
                    .onTapGesture {
                        print("✅")
                    }
                
                Spacer()
            }
        }
    }
}
