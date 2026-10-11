//
//  SelectDifficultyButtonView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/25.
//

import SwiftUI

struct SelectDifficultyButtonView: View {
    /// ゲームモード。選択 UI は `SelectQuizSettingView` にまとめている
    var gameMode: GameMode = .practice
    var questionCount: QuizQuestionCount = .default
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack {
            selectDifficultyButton(difficulty: .expert)

            selectDifficultyButton(difficulty: .hard)

            selectDifficultyButton(difficulty: .normal)

            selectDifficultyButton(difficulty: .easy)
        }
    }
}

extension SelectDifficultyButtonView {
    func selectDifficultyButton(difficulty: Difficulty) -> some View {
        // 遷移先は MainView の navigationDestination で作る（押すまで QuizView を作らないため）
        NavigationLink(
            value: QuizSetting(
                difficulty: difficulty,
                gameMode: gameMode,
                questionCount: questionCount
            )
        ) {
            Text(difficulty.localizedTitle)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .padding()
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: GameButtonAppearance.defaultCornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.7), lineWidth: 2)
                )
        }
        .buttonStyle(
            GameButtonStyle(
                appearance: GameButtonAppearance(
                    colors: difficulty.gradientColors,
                    side: difficulty.gameButtonSideColor(for: colorScheme)
                )
            )
        )
        .padding(.horizontal, 50)
        .padding(.bottom, 10)
    }
}

extension Difficulty {
    /// 難易度ボタンの側面の色。nil なら上面のグラデーションを暗くして使う
    ///
    /// エキスパートのグラデーション（indigo→black）は、暗くすると黒に近くなり、ダークモードの背景に溶け込む。
    /// ダークモードでは indigo を暗くした単色にして、背景と見分けられるようにする。
    func gameButtonSideColor(for colorScheme: ColorScheme) -> Color? {
        switch (self, colorScheme) {
        case (.expert, .dark):
            return Color(red: 0.25, green: 0.24, blue: 0.59)
        default:
            return nil
        }
    }
}

#Preview {
    NavigationStack {
        SelectDifficultyButtonView()
    }
}

#Preview("Dark") {
    NavigationStack {
        SelectDifficultyButtonView()
            .frame(maxHeight: .infinity)
            .background(Color.appBackground)
    }
    .preferredColorScheme(.dark)
}
