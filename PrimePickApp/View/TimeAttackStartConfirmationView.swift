//
//  TimeAttackStartConfirmationView.swift
//  PrimePickApp
//

import SwiftUI

/// タイムアタックを始める前に、タイトル画面に重ねて出す確認のカード（Discussion #394 Q1）
///
/// 後ろのタイトル画面（背景・「Prime Pick」の虹）が見えたままになるよう、画面全体は覆わずカードだけを出す。
/// VoiceOver ではモーダルとして扱い、エスケープのジェスチャー（2 本指の Z）で「やめる」と同じにする。
struct TimeAttackStartConfirmationView: View {
    let setting: QuizSetting
    let onStart: () -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    static let cornerRadius: CGFloat = 28

    /// 「Start」の押下音。進むボタンなので、音程が上がる進む押下音にする（Discussion #454）
    static let startPressSound: SoundEffect = .buttonPressForward
    /// 「Quit」の押下音。戻るボタンなので、ほかのボタンと同じ今の押下音のままにする
    static let quitPressSound: SoundEffect = .buttonPressBack

    var body: some View {
        VStack(spacing: 20) {
            Text("Start Time Attack?")
                .appFont(.heading(size: 22, weight: .bold))
                .multilineTextAlignment(.center)
                // 明朝は文字幅が広く、カードの幅（360pt）では「始め／ますか？」と語の途中で折り返すため、縮めて 1 行に収める
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)

            summary

            VStack(spacing: 12) {
                Button(action: onStart) {
                    Text("Start")
                        .appFont(.heading(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    GameButtonStyle(
                        appearance: GameButtonAppearance(
                            colors: setting.difficulty.gradientColors,
                            side: setting.difficulty.gameButtonSideColor(for: colorScheme)
                        ),
                        pressSound: Self.startPressSound
                    )
                )

                Button(action: onCancel) {
                    Text("Quit")
                        .appFont(.heading(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GameButtonStyle(appearance: .neutral(shape: .capsule, depth: 4), pressSound: Self.quitPressSound))
            }
        }
        .padding(24)
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .fill(Color.appBackground)
        )
        .overlay(
            // 難易度の色の縁取りで、どの難易度を始めるかをカードの見た目でも伝える
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: setting.difficulty.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
        .padding(.horizontal, 32)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onCancel)
    }

    /// 難易度と制限時間。何が始まるかが分かるように並べる
    private var summary: some View {
        HStack(spacing: 12) {
            Text(setting.difficulty.localizedTitle)
                .appFont(.heading(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.vertical, 6)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: setting.difficulty.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                // 見た目は難易度名だけだが、読み上げでは何の値かが分かるようにする
                .accessibilityLabel(Text("Difficulty: \(Text(setting.difficulty.localizedTitle))"))

            if case .timeAttack(let duration) = setting.gameMode {
                Label {
                    Text(duration.localizedTitle)
                } icon: {
                    Image(systemName: "timer")
                }
                .appFont(.heading(size: 18, weight: .bold))
                // 時計のアイコンは読み上げないので、制限時間であることを言葉で伝える
                .accessibilityLabel(Text("Time limit: \(duration.seconds) sec"))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        TimeAttackStartConfirmationView(
            setting: QuizSetting(difficulty: .expert, gameMode: .timeAttack(.thirtySeconds), questionCount: .default),
            onStart: {},
            onCancel: {}
        )
    }
}
