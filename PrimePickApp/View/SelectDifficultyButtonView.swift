//
//  SelectDifficultyButtonView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/25.
//

import SwiftUI

struct SelectDifficultyButtonView: View {
    @State private var gameMode: GameMode = .practice
    /// `nil` は「おまかせ」＝ 難易度ごとの既定レンジを使う
    var selectedRange: QuizRange?
    var questionCount: QuizQuestionCount = .default

    var body: some View {
        VStack {
            selectGameModePicker

            selectDifficultyButton(difficulty: .hard)

            selectDifficultyButton(difficulty: .normal)

            selectDifficultyButton(difficulty: .easy)
        }
    }
}

extension SelectDifficultyButtonView {
    var selectGameModePicker: some View {
        Picker("Game Mode", selection: $gameMode) {
            ForEach(GameMode.allCases) { gameMode in
                Text(gameMode.localizedTitle)
                    .tag(gameMode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 50)
        .padding(.bottom, 16)
    }

    func selectDifficultyButton(difficulty: Difficulty) -> some View {
        NavigationLink(
            destination: LazyView(
                QuizView(
                    difficulty: difficulty,
                    gameMode: gameMode,
                    range: selectedRange,
                    questionCount: questionCount
                )
            )
        ) {
            Text(difficulty.localizedTitle)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(gradient: Gradient(colors: difficulty.gradientColors),
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .foregroundColor(.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 5, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.7), lineWidth: 2)
                )
                .padding(.horizontal, 50)
                .padding(.bottom, 10)
        }
    }
}

#Preview {
    SelectDifficultyButtonView()
}
