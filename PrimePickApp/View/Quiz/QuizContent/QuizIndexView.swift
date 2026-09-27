//
//  QuizIndexView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/22.
//

import SwiftUI

struct QuizIndexView: View {
    let difficulty: Difficulty
    var gameMode: GameMode = .practice
    @Binding var quizNumber: Int
    let currentCombo: Int
    /// 現在の合計スコア。タイムアタックでだけ表示する
    var score: Int = 0
    /// スコアの横に出す増減のポップアップ。タイムアタックでだけ渡される
    var scorePopup: ScorePopup?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// コンボが 2 以上のときだけ表示する（1 連続目は倍率が 1.0 倍で意味がないため）
    private var isComboVisible: Bool {
        currentCombo >= 2
    }

    private var comboStage: ComboStage {
        ComboStage(combo: currentCombo)
    }
    
    var body: some View {
        HStack {
            leadingLabel
                .font(.custom("ArialRoundedMTBold", size: 45))
                .foregroundStyle(Color.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            // スコアの右に出す。Spacer より手前に置くので、出し入れしてもスコアやコンボの位置は動かない
            if let scorePopup {
                ScorePopupView(popup: scorePopup)
                    .id(scorePopup.id)
            }

            Spacer()

            // 表示の出し入れにだけアニメーションを付け、コンボ切れで割れて落ちる退場を再生する
            ZStack {
                if isComboVisible {
                    comboLabel
                        .transition(
                            .asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: reduceMotion ? .opacity : .comboBreak
                            )
                        )
                }
            }
            .animation(.easeIn(duration: 0.45), value: isComboVisible)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// コンボ数と倍率。段階が上がるほど目立たせる
    ///
    /// - 通常: 灰色
    /// - Good: オレンジで少し拡大
    /// - Great: さらに脈打つ
    /// - MAX: 色が回り、倍率の代わりに `MAX ×2.0` を出す
    private var comboLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("Combo \(currentCombo)")
                .font(.custom("ArialRoundedMTBold", size: 28))

            // 倍率の数字は言語によらず同じ表記なので、ローカライズしない
            if comboStage == .max {
                Text(verbatim: "MAX" + (gameMode.isTimeAttack ? " " + Self.multiplierText(combo: currentCombo) : ""))
                    .font(.custom("ArialRoundedMTBold", size: 22))
            } else if gameMode.isTimeAttack {
                Text(verbatim: Self.multiplierText(combo: currentCombo))
                    .font(.custom("ArialRoundedMTBold", size: 22))
            }
        }
        .modifier(ComboStageStyle(stage: comboStage, reduceMotion: reduceMotion))
        .scaleEffect(comboStage >= .good ? 1.1 : 1, anchor: .trailing)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: comboStage)
    }

    /// 左上の表示。タイムアタックは問題数に上限がなく「何問目か」より点数の方が意味を持つため、スコアに置き換える
    @ViewBuilder
    private var leadingLabel: some View {
        if gameMode.isTimeAttack {
            Text(verbatim: "\(score)")
                .contentTransition(.numericText(value: Double(score)))
                .animation(.snappy, value: score)
                .accessibilityLabel(Text("Score \(score)"))
        } else {
            Text("No.\(quizNumber + 1)")
        }
    }

    /// コンボ倍率の表示文言（例: `×1.6`）
    static func multiplierText(combo: Int) -> String {
        String(format: "×%.1f", ScoreCalculator.comboMultiplier(combo: combo))
    }
}

/// コンボ段階ごとの色と脈打ち
private struct ComboStageStyle: ViewModifier {
    let stage: ComboStage
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        switch stage {
        case .normal:
            content.foregroundStyle(Color.gray)
        case .good:
            content.foregroundStyle(Color.orange)
        case .great:
            if reduceMotion {
                content.foregroundStyle(Color.orange)
            } else {
                content
                    .foregroundStyle(Color.orange)
                    .phaseAnimator([1.0, 1.08]) { view, scale in
                        view.scaleEffect(scale, anchor: .trailing)
                    } animation: { _ in
                        .easeInOut(duration: 0.4)
                    }
            }
        case .max:
            if reduceMotion {
                content.foregroundStyle(Color.orange)
            } else {
                RainbowText(content: content)
            }
        }
    }
}

#Preview("練習") {
    QuizIndexView(difficulty: .easy, quizNumber: .constant(2), currentCombo: 3)
}

#Preview("タイムアタック") {
    QuizIndexView(
        difficulty: .easy,
        gameMode: .timeAttack(.thirtySeconds),
        quizNumber: .constant(2),
        currentCombo: 7,
        score: 1_245
    )
}
