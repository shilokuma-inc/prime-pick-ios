//
//  GameButtonStyle.swift
//  PrimePickApp
//

import SwiftUI

/// ゲーム内の主なボタンの見た目（Discussion #307）
///
/// 上面の下に少し濃い「側面」を `depth` だけ見せ、押すと上面がその分沈んで側面が隠れる、厚み（段差）型のボタン。
/// 側面の分だけ高さが増えるので、並べる側はその分の余白を見込む必要は無い（レイアウト上の高さに含めている）。
struct GameButtonAppearance {
    /// ボタンの形
    enum Shape {
        /// 角丸の矩形
        case roundedRectangle(cornerRadius: CGFloat)
        /// カプセル型（両端が半円）
        case capsule
    }

    /// 上面の塗り（単色・グラデーション）
    var face: AnyShapeStyle
    /// 側面の色。nil なら上面の塗りを暗くして使う
    var side: Color?
    var shape: Shape = .roundedRectangle(cornerRadius: GameButtonAppearance.defaultCornerRadius)
    /// 側面の見える厚み（pt）
    var depth: CGFloat = GameButtonAppearance.defaultDepth

    static let defaultCornerRadius: CGFloat = 20
    static let defaultDepth: CGFloat = 6
    /// 側面を上面の塗りから作るときに重ねる黒の不透明度
    static let sideDarkening: Double = 0.3

    /// 左上から右下へのグラデーション（難易度ボタンと同じ向き）
    init(
        colors: [Color],
        side: Color? = nil,
        shape: Shape = .roundedRectangle(cornerRadius: GameButtonAppearance.defaultCornerRadius),
        depth: CGFloat = GameButtonAppearance.defaultDepth
    ) {
        self.face = AnyShapeStyle(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        self.side = side
        self.shape = shape
        self.depth = depth
    }

    /// 単色
    init(
        color: Color,
        side: Color? = nil,
        shape: Shape = .roundedRectangle(cornerRadius: GameButtonAppearance.defaultCornerRadius),
        depth: CGFloat = GameButtonAppearance.defaultDepth
    ) {
        self.face = AnyShapeStyle(color)
        self.side = side
        self.shape = shape
        self.depth = depth
    }

    /// 色の付いていない控えめなボタン（遊び方・今日のチャレンジなど）
    ///
    /// 上面はライトで白・ダークで背景より明るい紺、側面はそれより暗い色にする。
    /// 上面に半透明の色を使うと側面が透けるため、不透明な色にしている。
    /// `side` を渡すと側面だけその色にする（解答ボタンのように、ボタンの色を側面で見せたいとき）。
    static func neutral(
        side: Color? = nil,
        shape: Shape = .roundedRectangle(cornerRadius: GameButtonAppearance.defaultCornerRadius),
        depth: CGFloat = GameButtonAppearance.defaultDepth
    ) -> GameButtonAppearance {
        GameButtonAppearance(color: .gameButtonNeutralFace, side: side ?? .gameButtonNeutralSide, shape: shape, depth: depth)
    }

    /// 押されているときに上面を下げる量。沈みきると側面は隠れる
    func faceOffset(isPressed: Bool) -> CGFloat {
        isPressed ? depth : 0
    }

    /// 沈み込みのアニメーション。Reduce Motion のときは動かさずに切り替える
    static func pressAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.08)
    }

    var anyShape: AnyShape {
        switch shape {
        case .roundedRectangle(let cornerRadius):
            return AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        case .capsule:
            return AnyShape(Capsule())
        }
    }
}

private extension Color {
    static let gameButtonNeutralFace = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.22, green: 0.22, blue: 0.34, alpha: 1)
            : .white
    })

    static let gameButtonNeutralSide = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.04, green: 0.04, blue: 0.10, alpha: 1)
            : UIColor(red: 0.70, green: 0.76, blue: 0.80, alpha: 1)
    })
}

/// 立体の見た目だけを付ける。押されているかどうかは呼び出し側が渡す
///
/// `Button` には `GameButtonStyle` を使う。指が触れた瞬間に処理したいボタン（解答ボタン）のように、
/// `Button` を使わずに押下を扱う View はこれを直接使う。
struct GameButtonSurface: ViewModifier {
    let appearance: GameButtonAppearance
    let isPressed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let shape = appearance.anyShape
        content
            .background(shape.fill(appearance.face))
            .clipShape(shape)
            .offset(y: appearance.faceOffset(isPressed: isPressed))
            .background {
                sideView(shape: shape)
                    .offset(y: appearance.depth)
            }
            .padding(.bottom, appearance.depth)
            // 側面の部分に触れても押せるようにする
            .contentShape(Rectangle())
            .animation(GameButtonAppearance.pressAnimation(reduceMotion: reduceMotion), value: isPressed)
    }

    @ViewBuilder
    private func sideView(shape: AnyShape) -> some View {
        if let side = appearance.side {
            shape.fill(side)
        } else {
            shape.fill(appearance.face)
                .overlay(shape.fill(Color.black.opacity(GameButtonAppearance.sideDarkening)))
        }
    }
}

extension View {
    /// 厚み（段差）型の見た目を付ける。押下の状態は `isPressed` で渡す
    func gameButtonSurface(_ appearance: GameButtonAppearance, isPressed: Bool) -> some View {
        modifier(GameButtonSurface(appearance: appearance, isPressed: isPressed))
    }
}

/// 厚み（段差）型のボタンスタイル
///
/// 押した瞬間に上面が沈み、軽い触覚と押下音（`SoundEffect.buttonPress`）を返す。
/// `NavigationLink` にも `.buttonStyle(GameButtonStyle(...))` で当てられ、画面遷移の仕組みは変えない。
/// 撮影モード（`ScreenshotDemo`）では効果音と触覚を止める。
struct GameButtonStyle: ButtonStyle {
    var appearance: GameButtonAppearance
    /// 押したときに押下音を鳴らすか
    var playsSound = true

    func makeBody(configuration: Configuration) -> some View {
        GameButtonStyleBody(configuration: configuration, appearance: appearance, playsSound: playsSound)
    }

    /// 押し始めた瞬間（離している → 押している）だけ触覚・効果音を返す。撮影モードでは返さない
    static func shouldPlayPressFeedback(wasPressed: Bool, isPressed: Bool, isScreenshotDemo: Bool) -> Bool {
        !wasPressed && isPressed && !isScreenshotDemo
    }
}

private struct GameButtonStyleBody: View {
    let configuration: ButtonStyleConfiguration
    let appearance: GameButtonAppearance
    let playsSound: Bool

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .gameButtonSurface(appearance, isPressed: configuration.isPressed)
            .opacity(isEnabled ? 1 : 0.5)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { wasPressed, isPressed in
                GameButtonStyle.shouldPlayPressFeedback(
                    wasPressed: wasPressed,
                    isPressed: isPressed,
                    isScreenshotDemo: ScreenshotDemo.isEnabled
                )
            }
            .onChange(of: configuration.isPressed) { wasPressed, isPressed in
                guard playsSound,
                      GameButtonStyle.shouldPlayPressFeedback(
                          wasPressed: wasPressed,
                          isPressed: isPressed,
                          isScreenshotDemo: ScreenshotDemo.isEnabled
                      )
                else { return }
                SoundFeedback.play(.buttonPress)
            }
    }
}

#Preview {
    VStack(spacing: 16) {
        Button {} label: {
            Text(verbatim: "Expert")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(GameButtonStyle(appearance: GameButtonAppearance(colors: [.indigo, .black], side: .indigo.opacity(0.6))))

        Button {} label: {
            Text(verbatim: "Easy")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(GameButtonStyle(appearance: GameButtonAppearance(colors: [.green, .mint])))

        Button {} label: {
            Text(verbatim: "How to play")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
        }
        .buttonStyle(GameButtonStyle(appearance: GameButtonAppearance(color: .orange, shape: .capsule, depth: 4)))

        Button {} label: {
            Text(verbatim: "Disabled")
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(GameButtonStyle(appearance: GameButtonAppearance(color: .blue)))
        .disabled(true)
    }
    .padding(40)
}
