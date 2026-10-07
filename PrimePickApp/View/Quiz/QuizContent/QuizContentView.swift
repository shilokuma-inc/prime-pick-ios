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

            // 上下の段は高さを固定し、残りをすべて数字カードの段に渡す。
            // 以前は 1/6・2/3・1/6 の比率で配っていたが、#146 で設問文（44pt）を足したぶんカードの余白が消えたため、
            // 画面が大きくなった分は数字カードの段だけが広がるようにした（Discussion #216 の案 C）
            VStack(spacing: .zero) {
                // `No.` の 1 行ぶんの固有の高さ（約 60pt。QuizIndexView 側の padding で決まる）
                QuizIndexView(
                    difficulty: difficulty,
                    gameMode: gameMode,
                    quizNumber: $quizNumber,
                    currentCombo: currentCombo,
                    score: score,
                    scorePopup: scorePopup
                )
                
                // GeometryReader なので残りの高さをすべて取る
                QuizNumberView(
                    quizNumber: $quizNumber,
                    difficulty: difficulty,
                    quizData: quizData,
                    comboStage: comboStage
                )
                
                QuizTimeLimitView(
                    difficulty: difficulty,
                    gameMode: gameMode,
                    remainingSeconds: remainingSeconds,
                    timePenaltyPopup: timePenaltyPopup
                )
                .frame(height: quizTimeLimitAreaHeight)
            }
            .shortShake(trigger: comboBreakCount)
        }
        .animation(.easeInOut(duration: 0.6), value: comboStage == .max)
    }
}

/// 残り時間バー（`QuizTimeLimitView`）の高さ
///
/// 以前は出題領域の 1/6（iPhone SE で約 50pt、13 で約 59pt、16 Pro Max で約 68pt）だった。
/// 出題領域を広げてもバーだけ太くならないよう、現状の iPhone 13 とほぼ同じ 60pt に固定する
private let quizTimeLimitAreaHeight: CGFloat = 60

struct QuizContentView_Previews: PreviewProvider {
    @State static var quizNumber = 0
    
    static var previews: some View {
        QuizContentView(
            quizNumber: $quizNumber,
            difficulty: .easy,
            quizData: [QuizEntity(quizId: 0, number: 3, isCorrect: true, difficulty: .easy, range: .oneOrTwoDigits)],
            currentCombo: 3
        )
    }
}
