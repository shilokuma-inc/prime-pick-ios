//
//  Text+Extension.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/25.
//

import SwiftUI

public extension View {
    /// 虹色のグラデーションで描き、色相を回し続ける
    ///
    /// - Parameter cycleDuration: 色相が一周する秒数。小さいほど速く回る
    func gamingText(cycleDuration: TimeInterval = GamingHue.defaultCycleDuration) -> some View {
        self.modifier(GamingText(cycleDuration: cycleDuration))
    }
}

/// タイトルの虹（`gamingText()`）の色相の回り方
///
/// 時刻から色相を求めるので、途中で速さを変えても色が飛ばない（`repeatForever` は途中で速さを変えにくい）。
public enum GamingHue {
    /// 色相が一周する秒数の既定値
    public static let defaultCycleDuration: TimeInterval = 1

    /// 色相を回すか。Reduce Motion と撮影モードでは止める
    ///
    /// 撮影モードで止めるのは、`Tools/capture_screenshots.sh` が画面が落ち着くまで待つため。
    static func isAnimating(reduceMotion: Bool, isScreenshotDemo: Bool) -> Bool {
        !reduceMotion && !isScreenshotDemo
    }

    /// `date` の時点の色相の回転（度。0 以上 360 未満）
    ///
    /// 止めるときと、一周の秒数が 0 以下のときは 0（回していないときの色）を返す。
    static func degrees(at date: Date, cycleDuration: TimeInterval, isAnimating: Bool) -> Double {
        guard isAnimating, cycleDuration > 0 else { return 0 }
        let phase = date.timeIntervalSinceReferenceDate / cycleDuration
        return (phase - phase.rounded(.down)) * 360
    }
}

struct GamingText: ViewModifier {
    let cycleDuration: TimeInterval

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let isAnimating = GamingHue.isAnimating(reduceMotion: reduceMotion, isScreenshotDemo: ScreenshotDemo.isEnabled)
        content
            .foregroundColor(Color.white)
            .overlay(
                TimelineView(.animation(paused: !isAnimating)) { context in
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
                        cycleDuration: cycleDuration,
                        isAnimating: isAnimating
                    )))
                }
            )
    }
}

#Preview {
    Text("Gaming ON!")
        .gamingText()
}
