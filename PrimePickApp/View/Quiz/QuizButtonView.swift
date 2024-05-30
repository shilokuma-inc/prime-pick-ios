//
//  QuizButtonView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/22.
//

import SwiftUI

struct QuizButtonView: View {
    var quizData: [PrimeQuizEntity]
    @Binding var correctQuizNumber: Int
    @Binding var quizIndex: Int
    @Binding var isPresentedResult: Bool
    @State private var showAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            HStack {
                Spacer()
                
                quizButton(option: "Incorrect")
                .onTapGesture {
                    print("❌")
                    if !quizData[quizIndex].isCorrect {
                        print("正解")
                        correctQuizNumber += 1
                    } else {
                        print("不正解")
                    }
                    if quizIndex < 9 {
                        if quizIndex < 9 {
                            quizIndex += 1
                        }
                    } else {
//                        showAlert = true
                        isPresentedResult = true
                    }
                }
                
                Spacer()
                
                quizButton(option: "Correct")
                .onTapGesture {
                    print("✅")
                    if quizData[quizIndex].isCorrect {
                        print("正解")
                        correctQuizNumber += 1
                    } else {
                        print("不正解")
                    }
                    if quizIndex < 9 {
                        if quizIndex < 9 {
                            quizIndex += 1
                        }
                    } else {
//                        showAlert = true
                        isPresentedResult = true
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
