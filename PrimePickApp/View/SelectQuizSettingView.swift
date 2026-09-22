//
//  SelectQuizSettingView.swift
//  PrimePickApp
//

import SwiftUI

/// タイトル画面でゲームモード・出題レンジ・問題数を選ぶ UI
struct SelectQuizSettingView: View {
    @Binding var gameMode: GameMode
    /// `nil` は「おまかせ」＝ 難易度ごとの既定レンジ（`Difficulty.defaultRange`）を使う
    @Binding var selectedRange: QuizRange?
    @Binding var selectedQuestionCount: QuizQuestionCount

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            settingRow(title: "Game Mode") {
                Picker("Game Mode", selection: $gameMode) {
                    ForEach(GameMode.allCases) { mode in
                        Text(mode.localizedTitle).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            settingRow(title: "Range") {
                // 選択肢のラベルが長いため、幅に左右されないメニュー形式にする
                Picker("Range", selection: $selectedRange) {
                    Text("Auto").tag(QuizRange?.none)

                    ForEach(QuizRange.allCases) { range in
                        Text(range.localizedTitle).tag(QuizRange?.some(range))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // タイムアタックは時間切れまで出題し続けるため、問題数の選択は意味を持たない
            if gameMode.isTimeAttack {
                Text("タイムアタックでは制限時間まで出題が続きます。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                settingRow(title: "Questions") {
                    Picker("Questions", selection: $selectedQuestionCount) {
                        ForEach(QuizQuestionCount.allCases) { count in
                            Text(verbatim: count.value.description).tag(count)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding(.horizontal, 50)
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

struct SelectQuizSettingView_Previews: PreviewProvider {
    @State static var gameMode: GameMode = .practice
    @State static var range: QuizRange?
    @State static var questionCount: QuizQuestionCount = .default

    static var previews: some View {
        SelectQuizSettingView(
            gameMode: $gameMode,
            selectedRange: $range,
            selectedQuestionCount: $questionCount
        )
    }
}
