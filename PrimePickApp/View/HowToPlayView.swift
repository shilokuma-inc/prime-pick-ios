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

                        timeAttackSection

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

            ruleRow(number: 1, text: "ゲームモードと問題数を選び、難易度を選ぶとクイズが始まります。")
            ruleRow(number: 2, text: "表示された数が素数かどうかを答えます。")
            ruleRow(number: 3, text: "素数だと思ったら右の「素数」、素数ではないと思ったら左の「ちがう」を選びます。")
            ruleRow(number: 4, text: "選んだ問題数に答えると、正解数がスコアとして表示されます。")
        }
    }

    /// タイムアタックだけのスコアルール（Discussion #156）
    ///
    /// 数値はルールの定数から埋め込み、ルールを変えたときに説明だけ古くならないようにする。
    var timeAttackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Time Attack")

            ruleRow(number: 1, text: "制限時間内にできるだけ高いスコアを目指します。連続で正解するとコンボになり、点が増えます。")
            ruleRow(
                number: 2,
                text: "コンボが \(ScoreCalculator.timeAttackSpeedBonusMinimumCombo) 以上のときは、早く答えるほど速度ボーナスが付きます。"
            )
            ruleRow(
                number: 3,
                text: "間違えると点が減り（Easy \(missPenalty(.easy)) / Normal \(missPenalty(.normal)) / Hard \(missPenalty(.hard)) / Expert \(missPenalty(.expert))）、残り時間も \(GameMode.timeAttackMissTimePenaltySeconds) 秒減ります。スコアは 0 点より下にはなりません。"
            )
            ruleRow(number: 4, text: "間違えた直後の 0.5 秒はボタンを押せません。")
            ruleRow(number: 5, text: "難易度と制限時間ごとに自己ベストが記録されます。")
        }
    }

    func missPenalty(_ difficulty: Difficulty) -> Int {
        ScoreCalculator.missPenalty(difficulty: difficulty, rule: .timeAttack)
    }

    var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Difficulty")

            difficultyRow(difficulty: .easy, description: "1 〜 99 から出題されます。")
            difficultyRow(difficulty: .normal, description: "100 〜 999 から出題されます。")
            difficultyRow(difficulty: .hard, description: "100 〜 999 のうち、2・3・5 の倍数を除いた数から出題されます。")
            difficultyRow(difficulty: .expert, description: "1000 〜 9999 のうち、2・3・5 の倍数を除いた数から出題されます。")
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
