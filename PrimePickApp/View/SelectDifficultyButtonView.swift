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
    /// 始める前に確認を挟むモード（タイムアタック）で難易度を押したときに呼ぶ。nil ならどのモードでもすぐ遷移する
    var onRequestStartConfirmation: ((QuizSetting) -> Void)?
    /// 難易度ごとの、選んでいる制限時間の自己ベスト（#548）。nil ならボタンに自己ベストの行を出さない（練習・撮影モード）
    ///
    /// タイムアタックでは、記録の無い難易度にも「—」の行を出し、4 つのボタンの高さをそろえる。
    var bestScores: [Difficulty: Int]?
    @Environment(\.colorScheme) private var colorScheme

    /// 難易度ボタンの押下音。出題（タイムアタックでは確認カード）へ進むボタンなので、進む押下音にする。
    /// 練習でもタイムアタックでも同じ音にする（Discussion #463 Q3。タイムアタックでは確認カードの「Start」と進む音が 2 回続く）
    static let pressSound: SoundEffect = .buttonPressForward

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
        let setting = QuizSetting(
            difficulty: difficulty,
            gameMode: gameMode,
            questionCount: questionCount
        )
        return Group {
            if gameMode.confirmsBeforeStarting, let onRequestStartConfirmation {
                // タイムアタックはすぐ始めず、MainView が確認のカードを出す（Discussion #394）
                Button {
                    onRequestStartConfirmation(setting)
                } label: {
                    difficultyLabel(difficulty)
                }
            } else {
                // 遷移先は MainView の navigationDestination で作る（押すまで QuizView を作らないため）
                NavigationLink(value: setting) {
                    difficultyLabel(difficulty)
                }
            }
        }
        .buttonStyle(
            GameButtonStyle(
                appearance: GameButtonAppearance(
                    colors: difficulty.gradientColors,
                    side: difficulty.gameButtonSideColor(for: colorScheme)
                ),
                pressSound: Self.pressSound
            )
        )
        // 自己ベストは難易度名に続けて読み上げる（行そのものは読み上げから外している）
        .accessibilityValue(bestScores.map { Self.bestScoreAccessibilityValue($0[difficulty]) } ?? Text(verbatim: ""))
        .padding(.horizontal, 50)
        .padding(.bottom, 10)
    }

    private func difficultyLabel(_ difficulty: Difficulty) -> some View {
        VStack(spacing: Self.bestScoreSpacing) {
            Text(difficulty.localizedTitle)
                .appFont(.heading(size: 24, weight: .bold))

            if let bestScores {
                bestScoreLine(bestScores[difficulty])
            }
        }
        // 自己ベストの行を出すときは上下の余白を詰め、練習モードのボタンとほぼ同じ高さに収める
        .padding(.horizontal)
        .padding(.vertical, bestScores == nil ? 16 : Self.verticalPaddingWithBestScore)
        .frame(maxWidth: .infinity)
        .foregroundColor(.white)
        .overlay(
            RoundedRectangle(cornerRadius: GameButtonAppearance.defaultCornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.7), lineWidth: 2)
        )
    }

    /// 難易度名の下に出す自己ベスト（トロフィーと点数）。記録が無ければ「—」
    private func bestScoreLine(_ score: Int?) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "trophy.fill")
                .imageScale(.small)

            if let score {
                Text(score, format: .number)
                    .monospacedDigit()
            } else {
                Text(verbatim: "—")
            }
        }
        .appFont(.number(size: 13))
        .foregroundStyle(Color.white.opacity(0.9))
        .lineLimit(1)
        // 読み上げは難易度のボタンの値（`accessibilityValue`）にまとめる
        .accessibilityHidden(true)
    }

    /// 自己ベストの読み上げ。記録が無ければ「記録なし」
    static func bestScoreAccessibilityValue(_ score: Int?) -> Text {
        if let score {
            return Text("Best score: \(score)")
        }
        return Text("No records yet")
    }

    /// 難易度名と自己ベストの行の間隔
    static let bestScoreSpacing: CGFloat = 2
    /// 自己ベストの行を出すときの上下の余白（練習モードは 16）
    static let verticalPaddingWithBestScore: CGFloat = 8
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
