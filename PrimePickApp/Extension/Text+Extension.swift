//
//  Text+Extension.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/25.
//

import SwiftUI

extension View {
    /// 虹色のグラデーションで描き、色相を回し続ける。Reduce Motion と撮影モードでは止める
    ///
    /// - Parameter style: 回す速さ・鮮やかさ・脈動・揺れ。既定は 1 秒 1 周で、脈動も揺れもしない
    func gamingText(style: GamingTextStyle = .standard) -> some View {
        self.modifier(GamingText(style: style))
    }
}

/// タイトルの虹（`gamingText()`）の激しさ（Discussion #394 Q3）
struct GamingTextStyle: Equatable {
    /// 文字の脈動（拡大縮小）。`1` から `1 + amplitude` 倍の間を往復する
    struct Pulse: Equatable {
        /// 1 往復の秒数
        let period: TimeInterval
        /// 大きくする割合
        let amplitude: Double
    }

    /// 文字の横の揺れ。`-amplitude` から `amplitude` pt の間を往復する
    struct Shake: Equatable {
        /// 1 往復の秒数
        let period: TimeInterval
        /// 揺れ幅（pt）
        let amplitude: Double
    }

    /// 色相が一周する秒数。小さいほど速く回る
    let cycleDuration: TimeInterval
    /// グラデーションの鮮やかさ（1 で元の色）
    let saturation: Double
    /// nil なら脈動しない
    let pulse: Pulse?
    /// nil なら揺らさない
    let shake: Shake?

    /// 今までの虹（1 秒 1 周・元の鮮やかさ・脈動も揺れもしない）
    static let standard = GamingTextStyle(
        cycleDuration: GamingHue.defaultCycleDuration,
        saturation: 1,
        pulse: nil,
        shake: nil
    )

    /// 脈動の倍率。`elapsed` は速さを変えてからの秒数で、0 のとき 1（元の大きさ）から始まる
    func scale(elapsed: TimeInterval) -> Double {
        guard let pulse, pulse.period > 0 else { return 1 }
        return 1 + pulse.amplitude * (1 - cos(2 * .pi * elapsed / pulse.period)) / 2
    }

    /// 横の揺れ（pt）。`elapsed` が 0 のとき 0（元の位置）から始まる
    func offset(elapsed: TimeInterval) -> Double {
        guard let shake, shake.period > 0 else { return 0 }
        return shake.amplitude * sin(2 * .pi * elapsed / shake.period)
    }

    /// Reduce Motion などで動きを止めるときの形。鮮やかさだけ残す
    var stopped: GamingTextStyle {
        GamingTextStyle(cycleDuration: cycleDuration, saturation: saturation, pulse: nil, shake: nil)
    }
}

/// タイトルの虹（`gamingText()`）の色相の回り方
///
/// 時刻から色相を求める（`repeatForever` は途中で速さを変えにくい）。
/// 速さを変えたときは、変えた時刻の位相を起点（`Anchor`）にして続きを回すので、色が飛ばない。
enum GamingHue {
    /// 色相の位相の起点
    struct Anchor: Equatable {
        /// 起点の時刻
        let date: Date
        /// 起点の時刻の位相（0 以上 1 未満）
        let phase: Double

        /// 基準日時（2001-01-01）に位相 0
        static let zero = Anchor(date: Date(timeIntervalSinceReferenceDate: 0), phase: 0)
    }

    /// 色相が一周する秒数の既定値
    static let defaultCycleDuration: TimeInterval = 1

    /// 色相を回すか。Reduce Motion と撮影モードでは止める
    ///
    /// 撮影モードで止めるのは、`Tools/capture_screenshots.sh` が画面が落ち着くまで待つため。
    static func isAnimating(reduceMotion: Bool, isScreenshotDemo: Bool) -> Bool {
        !reduceMotion && !isScreenshotDemo
    }

    /// `date` の時点の位相（0 以上 1 未満）。一周の秒数が 0 以下なら起点の位相のまま
    static func phase(at date: Date, anchor: Anchor = .zero, cycleDuration: TimeInterval) -> Double {
        guard cycleDuration > 0 else { return anchor.phase }
        let phase = anchor.phase + date.timeIntervalSince(anchor.date) / cycleDuration
        return phase - phase.rounded(.down)
    }

    /// 速さを変えるときの新しい起点。`date` までは前の速さ（`previousCycleDuration`）で回したものとして位相を引き継ぐ
    static func reanchored(_ anchor: Anchor, at date: Date, previousCycleDuration: TimeInterval) -> Anchor {
        Anchor(date: date, phase: phase(at: date, anchor: anchor, cycleDuration: previousCycleDuration))
    }

    /// `date` の時点の色相の回転（度。0 以上 360 未満）
    ///
    /// 止めるときは 0（回していないときの色）を返す。
    static func degrees(
        at date: Date,
        anchor: Anchor = .zero,
        cycleDuration: TimeInterval,
        isAnimating: Bool
    ) -> Double {
        guard isAnimating else { return 0 }
        return phase(at: date, anchor: anchor, cycleDuration: cycleDuration) * 360
    }
}

struct GamingText: ViewModifier {
    let style: GamingTextStyle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 色相の位相の起点。速さが変わるたびに付け替える
    @State private var anchor = GamingHue.Anchor.zero

    func body(content: Content) -> some View {
        let isAnimating = GamingHue.isAnimating(reduceMotion: reduceMotion, isScreenshotDemo: ScreenshotDemo.isEnabled)
        let style = isAnimating ? style : style.stopped
        TimelineView(.animation(paused: !isAnimating)) { context in
            let elapsed = context.date.timeIntervalSince(anchor.date)
            content
                .foregroundColor(Color.white)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.red, Color.orange, Color.yellow, Color.green,
                            Color.blue, Color.purple, Color.red
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .mask(content)
                    .hueRotation(Angle(degrees: GamingHue.degrees(
                        at: context.date,
                        anchor: anchor,
                        cycleDuration: style.cycleDuration,
                        isAnimating: isAnimating
                    )))
                    .saturation(style.saturation)
                )
                // レイアウトを動かさない変形だけを使う（難易度ボタンの位置などが揺れないように）
                .scaleEffect(style.scale(elapsed: elapsed))
                .offset(x: style.offset(elapsed: elapsed))
        }
        .onChange(of: self.style.cycleDuration) { oldValue, _ in
            anchor = GamingHue.reanchored(anchor, at: Date(), previousCycleDuration: oldValue)
        }
    }
}

extension Difficulty {
    /// 確認のカードを出している間のタイトルの虹の激しさ（Discussion #394 Q3）
    ///
    /// 難しいほど速く回し、鮮やかにする。Hard・Expert では文字を脈動させ、Expert だけ文字を揺らす。
    /// 色相の一周は点滅に見えないよう、1 秒あたり 3 周未満にとどめる。
    /// Reduce Motion のときは回転・脈動・揺れを止め、鮮やかさの差だけで難易度を伝える（Q5。止めるのは `GamingText` 側でも行う）。
    func confirmationTitleStyle(reduceMotion: Bool) -> GamingTextStyle {
        let style: GamingTextStyle
        switch self {
        case .easy:
            style = GamingTextStyle(cycleDuration: 0.8, saturation: 0.6, pulse: nil, shake: nil)
        case .normal:
            style = GamingTextStyle(cycleDuration: 0.65, saturation: 0.75, pulse: nil, shake: nil)
        case .hard:
            style = GamingTextStyle(
                cycleDuration: 0.5,
                saturation: 0.9,
                pulse: GamingTextStyle.Pulse(period: 0.9, amplitude: 0.04),
                shake: nil
            )
        case .expert:
            style = GamingTextStyle(
                cycleDuration: 0.4,
                saturation: 1,
                pulse: GamingTextStyle.Pulse(period: 0.7, amplitude: 0.06),
                shake: GamingTextStyle.Shake(period: 0.15, amplitude: 2.5)
            )
        }
        return reduceMotion ? style.stopped : style
    }
}

#Preview {
    Text("Gaming ON!")
        .gamingText()
}
