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
    
    let primeData = PrimeData()
    let difficulty: String
    let manager = QuizDataManager()
    let quizData: [PrimeQuizEntity]
    
    init(difficulty: String) {
        self.difficulty = difficulty
        quizData = manager.makeQuizData()
    }

    var body: some View {
        VStack {
            Color.yellow
                .frame(height: UIScreen.main.bounds.height / 3)
            Text(quizData[quizNumber].number.description)
            HStack {
                if quizNumber < 9 {
                    Button {
                        print("正解")
                        if quizNumber < 9 {
                            quizNumber += 1
                        } else {
//                            dismiss()
                        }
                    } label: {
                        Text("正解")
                    }
                    
                    Button {
                        print("不正解")
                        if quizNumber < 9 {
                            quizNumber += 1
                        } else {
//                            dismiss()
                        }
                    } label: {
                        Text("不正解")
                    }
                } else {
                    Text("終わり")
                }
            }
            Spacer()
        }
        .onAppear {
            print(quizData)
        }
    }
}

#Preview {
    QuizView(difficulty: "Easy")
}
