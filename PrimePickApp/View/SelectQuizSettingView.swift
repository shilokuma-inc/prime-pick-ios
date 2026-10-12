//
//  SelectQuizSettingView.swift
//  PrimePickApp
//

import SwiftUI

/// タイトル画面でゲームモード・問題数を選ぶ UI。出題範囲は難易度ボタンで決まる
///
/// 選択肢はモードの色のカプセルで並べる（Discussion #330）。問題数の行も、選んでいるモードの色にする。
struct SelectQuizSettingView: View {
    @Binding var gameMode: GameMode
    @Binding var selectedQuestionCount: QuizQuestionCount

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            settingRow(title: "Game Mode") {
                CapsuleChoicePicker(
                    selection: $gameMode,
                    options: GameMode.allCases,
                    colors: \.themeColors
                ) { mode in
                    Text(mode.localizedTitle)
                }
            }

            // タイムアタックは時間切れまで出題し続けるため、問題数の選択は意味を持たない
            if gameMode.isTimeAttack {
                Text("タイムアタックでは制限時間まで出題が続きます。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                settingRow(title: "Questions") {
                    CapsuleChoicePicker(
                        selection: $selectedQuestionCount,
                        options: QuizQuestionCount.allCases,
                        colors: { [gameMode] _ in gameMode.themeColors }
                    ) { count in
                        Text(verbatim: count.value.description)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}

private extension SelectQuizSettingView {
    /// 左にラベル、右にコントロールを並べる 1 行
    func settingRow<Content: View>(
        title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: 84, alignment: .leading)

            content()
        }
    }
}

/// 選択肢をカプセル型のボタンで横に並べる。`Picker` の `.segmented` の代わり
///
/// 選択中はその選択肢の色のグラデーション＋白い太字、非選択は同じ色の薄い塗り＋枠線にする。
/// 選択中の塗りは選び直すとスライドして移る（Reduce Motion のときは動かさずに切り替える）。
/// 押すとすぐ始まる難易度ボタンと見分けられるよう、高さは `Picker` のセグメントと同じくらいに抑えている。
private struct CapsuleChoicePicker<Option: Hashable & Identifiable, Label: View>: View {
    @Binding var selection: Option
    let options: [Option]
    /// 選択肢ごとの 2 色のグラデーション
    let colors: (Option) -> [Color]
    @ViewBuilder let label: (Option) -> Label

    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// カプセルの高さの下限。Dynamic Type で文字を大きくしたときは文字に合わせて高くなる
    static var minHeight: CGFloat { 36 }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options) { option in
                chip(option)
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: selection)
        .sensoryFeedback(.selection, trigger: selection)
    }

    func chip(_ option: Option) -> some View {
        let isSelected = option == selection
        let gradient = colors(option)
        let tint = gradient.first ?? .accentColor
        return Button {
            selection = option
        } label: {
            label(option)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                // 4 つ並びは 1 つあたりの幅が狭いので、文字を大きくしても省略せずに縮めて収める
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: Self.minHeight)
                .background {
                    ZStack {
                        Capsule()
                            .fill(tint.opacity(0.12))
                            .overlay(Capsule().strokeBorder(tint.opacity(0.5), lineWidth: 1.5))

                        // 選択中の塗りは 1 つだけ置き、選び直すとその位置へスライドさせる
                        if isSelected {
                            Capsule()
                                .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: (gradient.last ?? tint).opacity(0.35), radius: 4, y: 2)
                                .matchedGeometryEffect(id: "selection", in: namespace)
                        }
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        // Picker が持っていた「選択中」の読み上げを残す
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct SelectQuizSettingView_Previews: PreviewProvider {
    @State static var gameMode: GameMode = .practice
    @State static var questionCount: QuizQuestionCount = .default

    static var previews: some View {
        SelectQuizSettingView(
            gameMode: $gameMode,
            selectedQuestionCount: $questionCount
        )

        SelectQuizSettingView(
            gameMode: .constant(.timeAttack(.thirtySeconds)),
            selectedQuestionCount: $questionCount
        )
        .frame(maxHeight: .infinity)
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark / Time Attack")
    }
}
