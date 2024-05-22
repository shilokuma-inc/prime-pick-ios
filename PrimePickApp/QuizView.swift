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
        quizData = manager.makeQuizData(difficulty: difficulty)
    }

    var body: some View {
        ZStack {
            Color("appBlue")
                .ignoresSafeArea()
            
            VStack(spacing: .zero) {
                QuizIndexView(quizNumber: $quizNumber)
                    .frame(height: UIScreen.main.bounds.height / 12)
                
                QuizNumberView(
                    quizNumber: $quizNumber,
                    difficulty: difficulty,
                    quizData: quizData
                )
                .frame(height: UIScreen.main.bounds.height / 3)
                
                QuizTimeLimitView()
                    .frame(height: UIScreen.main.bounds.height / 12)
                    .border(Color.appGreen, width: 5.0)
                
                Spacer()
                
                QuizButtonView(quizData: quizData, quizNumber: $quizNumber)
                    .frame(height: UIScreen.main.bounds.height / 3)
                
                Spacer()
            }
            .onAppear {
                print(quizData)
            }
        }
    }
}

#Preview {
    QuizView(difficulty: "Easy")
}
