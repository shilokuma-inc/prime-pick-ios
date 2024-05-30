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
    @State var isPresentedResult: Bool = false
    @State var resultScore: Int = 0
    
    let primeData = PrimeData()
    let difficulty: Difficulty
    let manager = QuizDataManager()
    let quizData: [QuizEntity]
    
    init(difficulty: Difficulty) {
        self.difficulty = difficulty
        quizData = manager.makeQuizData(difficulty: difficulty)
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: .zero) {
                QuizIndexView(difficulty: difficulty, quizNumber: $quizNumber)
                    .frame(height: UIScreen.main.bounds.height / 12)
                
                QuizNumberView(
                    quizNumber: $quizNumber,
                    difficulty: difficulty,
                    quizData: quizData
                )
                .frame(height: UIScreen.main.bounds.height / 3)
                
                QuizTimeLimitView(difficulty: difficulty)
                    .frame(height: UIScreen.main.bounds.height / 12)
                
                Spacer()
                
                QuizButtonView(
                    quizData: quizData,
                    correctQuizNumber: $resultScore,
                    quizIndex: $quizNumber,
                    isPresentedResult: $isPresentedResult
                )
                .frame(height: UIScreen.main.bounds.height / 3)
                
                Spacer()
            }
            .onAppear {
                print(quizData)
            }
            
            if isPresentedResult {
                QuizResultView(score: resultScore)
            }
        }
    }
}

#Preview {
    QuizView(difficulty: .easy)
}
