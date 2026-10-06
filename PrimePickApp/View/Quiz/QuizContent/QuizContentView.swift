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

            // 上下の段は高さを固定し、残りをすべて数字カードの段に渡す。
            // 以前は 1/6・2/3・1/6 の比率で配っていたが、#146 で設問文（44pt）を足したぶんカードの余白が消えたため、
            // 画面が大きくなった分は数字カードの段だけが広がるようにした（Discussion #216 の案 C）
            VStack(spacing: .zero) {
                // `No.` の 1 行ぶんの固有の高さ（約 60pt。QuizIndexView 側の padding で決まる）
                QuizIndexView(
                    difficulty: difficulty,
                    quizNumber: $quizNumber,
                    currentCombo: currentCombo
                )
                
                // GeometryReader なので残りの高さをすべて取る
                QuizNumberView(
                    quizNumber: $quizNumber,
                    difficulty: difficulty,
                    quizData: quizData
                )
                
                QuizTimeLimitView(
                    difficulty: difficulty,
                    gameMode: gameMode,
                    remainingSeconds: remainingSeconds
                )
                .frame(height: quizTimeLimitAreaHeight)
            }
        }
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
            quizData: [QuizEntity(quizId: 0, number: 3, isCorrect: true)],
            currentCombo: 3
        )
    }
}
