//
//  QuizContentView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/31.
//

import SwiftUI

struct QuizContentView: View {
    @Binding var quizNumber: Int
    let difficulty: Difficulty
    var gameMode: GameMode = .practice
    var remainingSeconds: Int = 0
    let quizData: [QuizEntity]
    let currentCombo: Int
    /// 現在の合計スコア。タイムアタックで左上に表示する
    var score: Int = 0
    /// スコアの増減のポップアップ
    var scorePopup: ScorePopup?
    /// 時間ペナルティのポップアップ
    var timePenaltyPopup: ScorePopup?
    /// コンボが切れた回数。変わるたびに画面を短く揺らす（「視差効果を減らす」が有効なときは呼び出し側で増やさない）
    var comboBreakCount: Int = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var comboStage: ComboStage {
        ComboStage(combo: currentCombo)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                switch difficulty {
                case .easy:
                    Color("appGreen")
                        .opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                case .normal:
                    Color.blue
                        .opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                case .hard:
                    Color.red
                        .opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                }

                // MAX 段階では背景をゆっくり虹色にし、光の粒を流す
                if comboStage == .max && !reduceMotion {
                    MaxComboBackground()
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                }

                VStack(spacing: .zero) {
                    QuizIndexView(
                        difficulty: difficulty,
                        gameMode: gameMode,
                        quizNumber: $quizNumber,
                        currentCombo: currentCombo,
                        score: score,
                        scorePopup: scorePopup
                    )
                    .frame(height: geometry.size.height / 6)
                    
                    QuizNumberView(
                        quizNumber: $quizNumber,
                        difficulty: difficulty,
                        quizData: quizData,
                        comboStage: comboStage
                    )
                    .frame(height: geometry.size.height * 2 / 3)
                    
                    QuizTimeLimitView(
                        difficulty: difficulty,
                        gameMode: gameMode,
                        remainingSeconds: remainingSeconds,
                        timePenaltyPopup: timePenaltyPopup
                    )
                        .frame(height: geometry.size.height / 6)
                }
                .shortShake(trigger: comboBreakCount)
            }
            .animation(.easeInOut(duration: 0.6), value: comboStage == .max)
        }
    }
}

struct QuizContentView_Previews: PreviewProvider {
    @State static var quizNumber = 0
    
    static var previews: some View {
        QuizContentView(
            quizNumber: $quizNumber,
            difficulty: .easy,
            quizData: [QuizEntity(quizId: 0, number: 3, isCorrect: true)],
            currentCombo: 3
        )
    }
}
