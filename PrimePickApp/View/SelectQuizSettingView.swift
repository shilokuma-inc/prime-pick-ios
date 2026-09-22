//
//  SelectQuizSettingView.swift
//  PrimePickApp
//

import SwiftUI

/// タイトル画面で出題レンジと問題数を選ぶ UI
struct SelectQuizSettingView: View {
    /// `nil` は「おまかせ」＝ 難易度ごとの既定レンジ（`Difficulty.defaultRange`）を使う
    @Binding var selectedRange: QuizRange?
    @Binding var selectedQuestionCount: QuizQuestionCount

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingRow(title: "Range") {
                Picker("Range", selection: $selectedRange) {
                    Text("Auto").tag(QuizRange?.none)

                    ForEach(QuizRange.allCases) { range in
                        Text(range.localizedTitle).tag(QuizRange?.some(range))
                    }
                }
                .pickerStyle(.segmented)
            }

            settingRow(title: "Questions") {
                Picker("Questions", selection: $selectedQuestionCount) {
                    ForEach(QuizQuestionCount.allCases) { count in
                        Text(verbatim: count.value.description).tag(count)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}

private extension SelectQuizSettingView {
    func settingRow<Content: View>(
        title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            content()
        }
    }
}

struct SelectQuizSettingView_Previews: PreviewProvider {
    @State static var range: QuizRange?
    @State static var questionCount: QuizQuestionCount = .default

    static var previews: some View {
        SelectQuizSettingView(
            selectedRange: $range,
            selectedQuestionCount: $questionCount
        )
    }
}
