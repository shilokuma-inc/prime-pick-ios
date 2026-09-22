//
//  QuizTimeLimitView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/21.
//

import SwiftUI

struct QuizTimeLimitView: View {
    let difficulty: Difficulty
    var gameMode: GameMode = .practice
    var remainingSeconds: Int = 0

    var borderColor: Color {
        switch difficulty {
        case .easy:
            return Color.green
        case .normal:
            return Color.blue
        case .hard:
            return Color.red
        }
    }
    
    /// 残り時間の割合。練習モードは従来どおり僅かに進んだ見た目を維持する
    private var progress: Double {
        guard let timeLimitSeconds = gameMode.timeLimitSeconds, timeLimitSeconds > 0 else {
            return 0.01
        }
        return Double(remainingSeconds) / Double(timeLimitSeconds)
    }
    
    var body: some View {
        ZStack {
            switch difficulty {
            case .easy:
                Color.appGreen
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
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .gray))
                .scaleEffect(x: 1, y: 4, anchor: .center)
                .padding(.horizontal, 20)
                .animation(.linear(duration: 1), value: progress)
            
            switch gameMode {
            case .practice:
                outlinedTitle("No Timelimit!")
            case .timeAttack:
                outlinedTitle("\(remainingSeconds) sec")
            }
        }
        .border(borderColor, width: 5.0)
    }
}

private extension QuizTimeLimitView {
    /// 縁取りを描くためのずらし幅
    /// `CGSize` の `Hashable` 準拠は iOS 18 以降のため、タプルの配列で保持する
    static var outlineOffsets: [(x: CGFloat, y: CGFloat)] {
        [(1, 1), (1, -1), (-1, 1), (-1, -1)]
    }

    /// 背景に紛れないよう黒い縁取りを付けたタイトル
    func outlinedTitle(_ key: LocalizedStringKey) -> some View {
        ZStack {
            ForEach(Self.outlineOffsets.indices, id: \.self) { index in
                titleText(key)
                    .foregroundColor(.black)
                    .offset(
                        x: Self.outlineOffsets[index].x,
                        y: Self.outlineOffsets[index].y
                    )
            }

            titleText(key)
                .foregroundColor(.white)
        }
        .padding()
    }

    func titleText(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.largeTitle)
            .fontWeight(.heavy)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }
}

#Preview {
    VStack {
        QuizTimeLimitView(difficulty: .easy)

        QuizTimeLimitView(difficulty: .hard, gameMode: .timeAttack, remainingSeconds: 42)
    }
}
