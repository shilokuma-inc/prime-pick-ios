//
//  ComboEffects.swift
//  PrimePickApp
//

import SwiftUI

// コンボ段階に応じた演出（Discussion #156 の 6 章）。
// どれも見た目だけを変えるもので、タップ判定や VoiceOver の読み上げには関与しない。

/// コンボが切れたとき、コンボ表示を左右に割って落とす
///
/// `progress` が 0 で元の表示、1 で割れて落ちきった状態。`AnyTransition.modifier` の両端に使う。
///
/// 左右に割るためのマスクはレイアウト上の枠で切り取るため、`scaleEffect` などで枠からはみ出した部分まで消えてしまう。
/// 割れていない間（`progress` が 0）はマスクを掛けずにそのまま表示する。
/// そのために `Animatable` にして、アニメーション途中の値ごとに本文を組み立て直している。
struct ComboBreakEffect: ViewModifier, Animatable {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        if progress == 0 {
            content
        } else {
            ZStack {
                half(content, isLeading: true)
                half(content, isLeading: false)
            }
            .opacity(1 - progress)
        }
    }

    private func half(_ content: Content, isLeading: Bool) -> some View {
        let direction: Double = isLeading ? -1 : 1
        return content
            .mask {
                GeometryReader { geometry in
                    Rectangle()
                        .frame(width: geometry.size.width / 2)
                        .frame(maxWidth: .infinity, alignment: isLeading ? .leading : .trailing)
                }
            }
            .rotationEffect(.degrees(24 * direction * progress), anchor: isLeading ? .bottomLeading : .bottomTrailing)
            .offset(x: 8 * direction * progress, y: 36 * progress)
    }
}

extension AnyTransition {
    /// コンボ切れで割れて落ちる退場
    static var comboBreak: AnyTransition {
        .modifier(active: ComboBreakEffect(progress: 1), identity: ComboBreakEffect(progress: 0))
    }
}

/// 時間とともに色相が一周する色。MAX 段階の文字と背景に使う
enum RainbowHue {
    /// 色相が一周する秒数。「ゆっくり」変わるよう長めにとる
    static let cycleDuration: TimeInterval = 6

    static func hue(at date: Date, offset: Double = 0) -> Double {
        let phase = date.timeIntervalSinceReferenceDate / cycleDuration + offset
        return phase - phase.rounded(.down)
    }
}

/// MAX 段階で色相が回り続ける文字
struct RainbowText<Content: View>: View {
    let content: Content

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            content.foregroundStyle(Color(hue: RainbowHue.hue(at: context.date), saturation: 0.8, brightness: 0.95))
        }
    }
}

/// MAX 段階の背景。ゆっくり色が変わるグラデーションの上に、光の粒が立ち上る
///
/// 「視差効果を減らす」が有効なときは呼び出し側で出さない。
struct MaxComboBackground: View {
    /// 画面に出す粒の数
    private static let particleCount = 24

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let hue = RainbowHue.hue(at: context.date)
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hue: hue, saturation: 0.6, brightness: 1),
                        Color(hue: RainbowHue.hue(at: context.date, offset: 0.33), saturation: 0.6, brightness: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.35)

                Canvas { canvas, size in
                    drawParticles(in: &canvas, size: size, time: context.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// 粒ごとに決まった横位置・速さ・大きさで下から上へ流す。乱数を使わず番号から決めるので、描き直しても位置が飛ばない
    private func drawParticles(in canvas: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        for index in 0..<Self.particleCount {
            let seed = Double(index)
            let x = size.width * fraction(seed * 0.618)
            let speed = 0.25 + 0.35 * fraction(seed * 0.377)
            let progress = fraction(time * speed + fraction(seed * 0.123))
            let y = size.height * (1 - progress)
            let radius = 2 + 3 * fraction(seed * 0.271)
            let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
            let color = Color(hue: fraction(seed * 0.09 + time / RainbowHue.cycleDuration), saturation: 0.5, brightness: 1)
            // 上に行くほど薄くして、画面の上端で唐突に消えないようにする
            canvas.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.9 * (1 - progress))))
        }
    }

    private func fraction(_ value: Double) -> Double {
        value - value.rounded(.down)
    }
}

extension View {
    /// `trigger` が変わるたびに横に短く揺らす。コンボ切れで画面を揺らすのに使う
    func shortShake(trigger: Int) -> some View {
        keyframeAnimator(initialValue: 0.0, trigger: trigger) { content, offset in
            content.offset(x: offset)
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(-8, duration: 0.05)
                LinearKeyframe(8, duration: 0.07)
                LinearKeyframe(-5, duration: 0.06)
                LinearKeyframe(3, duration: 0.05)
                LinearKeyframe(0, duration: 0.05)
            }
        }
    }
}
