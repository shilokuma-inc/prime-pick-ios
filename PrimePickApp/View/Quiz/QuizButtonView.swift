//
//  QuizButtonView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/22.
//

import SwiftUI

struct QuizButtonView: View {
    var quizData: [PrimeQuizEntity]
    @State private var correctQuizNumber: Int = 0
    @Binding var quizNumber: Int
    @State private var showAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            HStack {
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.pink, lineWidth: 5)
                        .background(RoundedRectangle(cornerRadius: 25).fill(Color.white))
                        .frame(width: UIScreen.main.bounds.width * 2 / 5, height: UIScreen.main.bounds.height / 4)
                        .shadow(radius: 10)
                    
                    Text("❌")
                        .font(.custom("ArialRoundedMTBold", size: 80))
                }
                .onTapGesture {
                    print("❌")
                    if !quizData[quizNumber].isCorrect {
                        print("正解")
                        correctQuizNumber += 1
                    } else {
                        print("不正解")
                    }
                    if quizNumber < 9 {
                        if quizNumber < 9 {
                            quizNumber += 1
                        }
                    } else {
                        showAlert = true
                    }
                }
                
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.cyan, lineWidth: 5)
                        .background(RoundedRectangle(cornerRadius: 25).fill(Color.white))
                        .frame(width: UIScreen.main.bounds.width * 2 / 5, height: UIScreen.main.bounds.height / 4)
                        .shadow(radius: 10)
                    
                    Text("✅")
                        .font(.custom("ArialRoundedMTBold", size: 80))
                }
                .onTapGesture {
                    print("✅")
                    if quizData[quizNumber].isCorrect {
                        print("正解")
                        correctQuizNumber += 1
                    } else {
                        print("不正解")
                    }
                    if quizNumber < 9 {
                        if quizNumber < 9 {
                            quizNumber += 1
                        }
                    } else {
                        showAlert = true
                    }
                }
                
                Spacer()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("You Score is \(correctQuizNumber) points!"),
                dismissButton: .default(Text("OK!")) {
                    dismiss()
                }
            )
        }
    }
}