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
    /// タイムアタックのカウントダウンが最後に進んだ時刻（`session.start()` か最後の `.tick`）。まだ始めていなければ nil
    var countdownAdvancedAt: Date?
    /// 残り時間の近くに出す時間ペナルティのポップアップ
    var timePenaltyPopup: ScorePopup?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 残り 5 秒以下か。残り時間とバーを赤くし、1 秒ごとにパルスさせる
    private var isInFinalCountdown: Bool {
        gameMode.isInFinalCountdown(remainingSeconds: remainingSeconds)
    }

    /// 実時間の残り時間。残り 5 秒未満を小数 2 桁で出すのに使う（Discussion #484）
    private var countdown: TimeAttackCountdown {
        TimeAttackCountdown(gameMode: gameMode, remainingSeconds: remainingSeconds, lastAdvancedAt: countdownAdvancedAt)
    }

    var borderColor: Color {
        switch difficulty {
        case .easy:
            return Color.green
        case .normal:
            return Color.blue
        case .hard:
            return Color.red
        case .expert:
            return Color.indigo
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
            case .expert:
                Color.indigo
                    .opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: isInFinalCountdown ? .red : .gray))
                .scaleEffect(x: 1, y: 4, anchor: .center)
                .padding(.horizontal, 20)
                .animation(.linear(duration: 1), value: progress)
            
            switch gameMode {
            case .practice, .dailyChallenge:
                outlinedTitle("No Timelimit!")
            case .timeAttack:
                // 小数で表示する間（残り 5 秒以下）だけ毎フレーム描き直す。それ以外とタイムアップの後は止める。
                // パルスと tick 音は今どおり整数の残り秒が変わるたびに出す
                TimelineView(.animation(paused: !countdown.updatesEveryFrame)) { context in
                    remainingTimeTitle(countdown.displayValue(at: context.date))
                }
                .modifier(FinalCountdownPulse(isActive: isInFinalCountdown && !reduceMotion, trigger: remainingSeconds))
            }
        }
        .overlay(alignment: .trailing) {
            if let timePenaltyPopup {
                ScorePopupView(popup: timePenaltyPopup, fontSize: 26)
                    .id(timePenaltyPopup.id)
                    .padding(.trailing, 24)
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

    /// 残り時間のタイトル。5 秒以上は今どおり整数、5 秒未満は小数 2 桁
    func remainingTimeTitle(_ display: TimeAttackRemainingTimeDisplay) -> some View {
        let color: Color = isInFinalCountdown ? .red : .white
        switch display {
        case .wholeSeconds(let seconds):
            return outlinedTitle("\(seconds) sec", color: color)
        case .fractionalSeconds(let text):
            return outlinedTitle("\(text) sec", color: color)
        }
    }

    /// 背景に紛れないよう黒い縁取りを付けたタイトル
    func outlinedTitle(_ key: LocalizedStringKey, color: Color = .white) -> some View {
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
                .foregroundColor(color)
        }
        .padding()
    }

    func titleText(_ key: LocalizedStringKey) -> some View {
        // 数字が変わっても幅が揺れないよう、数字の幅をそろえる。縁取りの 4 枚にも同じ指定が効くよう、ここで付ける
        Text(key)
            .monospacedDigit()
            .appFont(.heading(.largeTitle, weight: .heavy))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }
}

/// 残り時間が 1 秒減るたびに一瞬拡大して戻す
private struct FinalCountdownPulse: ViewModifier {
    let isActive: Bool
    let trigger: Int

    func body(content: Content) -> some View {
        if isActive {
            content.keyframeAnimator(initialValue: 1.0, trigger: trigger) { view, scale in
                view.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack {
                    SpringKeyframe(1.25, duration: 0.12)
                    CubicKeyframe(1.0, duration: 0.35)
                }
            }
        } else {
            content
        }
    }
}

#Preview {
    VStack {
        QuizTimeLimitView(difficulty: .easy)

        QuizTimeLimitView(difficulty: .hard, gameMode: .timeAttack(.sixtySeconds), remainingSeconds: 42)

        QuizTimeLimitView(difficulty: .normal, gameMode: .timeAttack(.fifteenSeconds), remainingSeconds: 4, countdownAdvancedAt: .now)
    }
}
