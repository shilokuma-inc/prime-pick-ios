//
//  HowToPlayView.swift
//  PrimePickApp
//

import SwiftUI

/// 遊び方を説明するモーダル
struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        rulesSection

                        difficultySection
                    }
                    .padding(24)
                }
            }
            .sendAnalyticsScreen(.howToPlay)
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension HowToPlayView {
    var rulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Rules")

            ruleRow(number: 1, text: "難易度を選ぶとクイズが始まります。")
            ruleRow(number: 2, text: "表示された数が素数かどうかを答えます。")
            ruleRow(number: 3, text: "素数だと思ったら ✅、素数ではないと思ったら ❌ を選びます。")
            ruleRow(number: 4, text: "全 10 問に答えると、正解数がスコアとして表示されます。")
        }
    }

    var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Difficulty")

            difficultyRow(difficulty: .easy, description: "1 〜 99 から出題されます。")
            difficultyRow(difficulty: .normal, description: "100 〜 999 から出題されます。")
            difficultyRow(difficulty: .hard, description: "100 〜 999 のうち、2・3・5 の倍数を除いた数から出題されます。")
        }
    }

    func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.system(size: 24, weight: .bold, design: .rounded))
    }

    func ruleRow(number: Int, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number).")
                .font(.body.bold())
                .frame(width: 24, alignment: .leading)

            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func difficultyRow(difficulty: Difficulty, description: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(difficulty.localizedTitle)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(gradient: Gradient(colors: difficulty.gradientColors),
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .foregroundColor(.white)
                .cornerRadius(12)

            Text(description)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    HowToPlayView()
}
