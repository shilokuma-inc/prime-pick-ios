//
//  QuizResultView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/31.
//

import QuizCore
import SwiftUI

struct QuizResultView: View {
    /// スコアを 0 から数え上げる秒数
    static let scoreCountUpDuration: TimeInterval = 1.2

    @Environment(\.dismiss) private var dismiss
    @State private var rainbowColor: Color = .red
    /// 数え上げ中のスコア
    @State private var displayedScore: Double = 0
    let score: Int
    let correctCount: Int
    let maxCombo: Int
    let answerRecords: [QuizAnswerRecord]
    var gameMode: GameMode = .practice
    /// 自己ベストを更新したか（タイムアタックのみ）
    var isNewRecord: Bool = false
    /// それまでの記録との比べ（タイムアタックのみ。#549）
    var timeAttackComparison: TimeAttackComparison?
    /// 獲得点・減点の内訳
    var breakdown = ScoreBreakdown()
    /// 「もう一度」で同じ設定のプレイを始める。nil ならボタンを出さない（#547）
    var onPlayAgain: (() -> Void)?

    var body: some View {
        // 広告はカードの下に並べ、カードに重ねない。撮影モードなどで広告が無いときは今までと同じ全画面のレイアウトになる
        VStack(spacing: 0) {
            resultCard

            AdNativeAdView(placement: .quizResult)
                .background {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea(edges: .bottom)
                }
        }
        .sendAnalyticsScreen(.quizResult)
        .onAppear {
            startColorAnimation()
            withAnimation(.easeOut(duration: Self.scoreCountUpDuration)) {
                displayedScore = Double(score)
            }
        }
    }

    private var resultCard: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    // 小さい画面や大きい文字の設定でカードに収まらないときは、カードの中でスクロールして読めるようにする。
                    // 収まるときの見た目は今までどおり（スコアなどは上、戻るボタンは下）
                    ScrollView {
                        scoreSections
                    }
                    .scrollBounceBehavior(.basedOnSize)

                    buttons
                }
                .padding(20)
                .frame(width: geometry.size.width * 5 / 6)
                .frame(maxHeight: geometry.size.height * 5 / 6)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.appBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(rainbowColor, lineWidth: 5)
                )
                .shadow(radius: 10)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .edgesIgnoringSafeArea(.all)
    }

    /// スコア・正答数の内訳・復習一覧。カードの中でスクロールする入れ物に入れて使う
    private var scoreSections: some View {
        VStack(spacing: 16) {
            if isNewRecord {
                Text("NEW RECORD!")
                    .appFont(.heading(size: 32, weight: .heavy))
                    .foregroundStyle(rainbowColor)
            }

            // 最終スコアの文で場所を取り、数え上げの途中の値をその上に重ねる。
            // 途中で桁が増えて行数が変わっても、下の行がずれない（明朝は文字幅が広く、2 行になりやすい）
            CountingScoreText(value: Double(score))
                .hidden()
                .overlay {
                    CountingScoreText(value: displayedScore)
                }
                .appFont(.number(.title))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                // 数え上げ途中の値ではなく、最終スコアを読み上げる
                .accessibilityLabel(Text("Your Score is \(score) points!"))

            if let timeAttackComparison {
                comparisonSection(timeAttackComparison)
            }

            summarySection

            breakdownSection

            // 入れ子のスクロールを避けるため、復習一覧は外側の `ScrollView` に任せる
            QuizReviewList(answerRecords: answerRecords, scrolls: false)
        }
    }

    /// 合計スコアの内訳。タイムアタックは問題数が固定ではないため解答数も並べる
    private var summarySection: some View {
        VStack(spacing: 4) {
            HStack(spacing: 16) {
                if gameMode.isTimeAttack {
                    Text("Correct \(correctCount) / Answered \(answerRecords.count)")
                } else {
                    Text("Correct \(correctCount)")
                }

                Text("Max Combo \(maxCombo)")
            }

            // 1 行に並べると縮小されて読みにくいため、正答率は別の行に出す
            if let accuracy = Self.accuracyPercent(correctCount: correctCount, answeredCount: answerRecords.count) {
                Text("Accuracy \(accuracy)%")
            }
        }
        .appFont(.number(.headline))
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }

    /// スコアの内訳。減点はタイムアタックにしか無いので、タイムアタックのときだけ並べる
    private var breakdownSection: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
            breakdownRow("Base Points", value: breakdown.correctPoints)
            breakdownRow("Combo Bonus", value: breakdown.comboBonus)
            breakdownRow("Speed Bonus", value: breakdown.speedBonus)
            if gameMode.isTimeAttack {
                breakdownRow("Penalty", value: -breakdown.penalty)
            }
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity)
    }

    private func breakdownRow(_ title: LocalizedStringKey, value: Int) -> some View {
        GridRow {
            Text(title)
                .foregroundStyle(.secondary)

            Text(verbatim: Self.signedPointsText(value))
                .monospacedDigit()
                .foregroundStyle(value < 0 ? Color.red : Color.primary)
                .gridColumnAlignment(.trailing)
        }
    }

    /// 「もう一度」と「タイトルに戻る」。「もう一度」があるときはそちらを主ボタンにし、「タイトルに戻る」は低く控えめにする
    private var buttons: some View {
        VStack(spacing: 12) {
            if let onPlayAgain {
                playAgainButton(action: onPlayAgain)
            }

            returnToTitleButton
        }
    }

    /// 同じ設定でもう一度遊ぶ主ボタン。モードの色（練習は緑〜水色、タイムアタックはオレンジ〜赤）で塗る
    private func playAgainButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label("Play Again", systemImage: "arrow.counterclockwise")
                .appFont(.number(size: 24))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .frame(height: Self.primaryButtonHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: GameButtonAppearance.defaultCornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.7), lineWidth: 2)
                )
        }
        .buttonStyle(
            GameButtonStyle(
                appearance: GameButtonAppearance(colors: gameMode.themeColors),
                pressSound: Self.playAgainPressSound
            )
        )
    }

    private var returnToTitleButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Return to Title")
                .appFont(.number(size: onPlayAgain == nil ? 24 : 20))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .frame(height: onPlayAgain == nil ? Self.primaryButtonHeight : Self.secondaryButtonHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: GameButtonAppearance.defaultCornerRadius, style: .continuous)
                        .strokeBorder(Color.primary, lineWidth: onPlayAgain == nil ? 3 : 2)
                )
        }
        .buttonStyle(GameButtonStyle(appearance: .neutral(), pressSound: Self.returnToTitlePressSound))
    }

    /// 主ボタンの高さ（「もう一度」。無いときの「タイトルに戻る」）
    static let primaryButtonHeight: CGFloat = 60
    /// 「もう一度」の下に置く「タイトルに戻る」の高さ。主ボタンより低くし、2 つ並べても結果を読む場所を狭めすぎない
    static let secondaryButtonHeight: CGFloat = 48

    /// 「もう一度」の押下音。新しいプレイへ進むボタンなので、進む押下音にする
    static let playAgainPressSound: SoundEffect = .buttonPressForward
    /// 「タイトルに戻る」の押下音。戻るボタンなので、戻る押下音にする
    static let returnToTitlePressSound: SoundEffect = .buttonPressBack

    /// 正答率（%、四捨五入）。1 問も解答していなければ nil
    static func accuracyPercent(correctCount: Int, answeredCount: Int) -> Int? {
        guard answeredCount > 0 else { return nil }
        return Int((Double(correctCount) / Double(answeredCount) * 100).rounded())
    }

    /// 内訳の点数表示。マイナスは数字の幅に揃う U+2212 を使う
    static func signedPointsText(_ value: Int) -> String {
        value < 0 ? "\u{2212}\(-value)" : "+\(value)"
    }

    private func startColorAnimation() {
        // 撮影モードでは枠の色を変えずに止めておく
        guard !ScreenshotDemo.isEnabled else { return }
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
        var currentIndex = 0

        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            withAnimation {
                rainbowColor = colors[currentIndex]
            }
            currentIndex = (currentIndex + 1) % colors.count
        }
    }

    /// 自己ベストとの差・記録の順位・前回との差（タイムアタックのみ。#549）
    ///
    /// 初めての記録は自己ベストとの差を、上位 10 件に入らなければ順位を、前回の履歴が無ければ前回との差を出さない。
    @ViewBuilder
    private func comparisonSection(_ comparison: TimeAttackComparison) -> some View {
        let details = [
            comparison.rank.map { Text("#\($0) in your records") },
            comparison.previousDifference.map(Self.previousDifferenceText)
        ].compactMap { $0 }

        if comparison.best != nil || !details.isEmpty {
            VStack(spacing: 4) {
                if let best = comparison.best {
                    Self.bestDifferenceText(best)
                        .appFont(.heading(.headline, weight: .bold))
                        .foregroundStyle(Self.isBestUpdated(best) ? Color.primary : Color.secondary)
                }

                // 順位と前回との差は 1 行に並べる。収まらなければ縮める
                if !details.isEmpty {
                    details.dropFirst().reduce(details[0]) { $0 + Text(verbatim: "  ·  ") + $1 }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .accessibilityElement(children: .combine)
        }
    }

    /// 自己ベストとの差の文言
    static func bestDifferenceText(_ best: TimeAttackComparison.BestDifference) -> Text {
        switch best {
        case .updated(let points):
            return Text("Beat your best by \(points) points")
        case .tied:
            return Text("Tied your best")
        case .short(let points):
            return Text("\(points) points short of your best")
        }
    }

    /// 前回との差の文言
    static func previousDifferenceText(_ difference: Int) -> Text {
        if difference > 0 {
            return Text("\(difference) points higher than last time")
        } else if difference < 0 {
            return Text("\(-difference) points lower than last time")
        }
        return Text("Same score as last time")
    }

    private static func isBestUpdated(_ best: TimeAttackComparison.BestDifference) -> Bool {
        if case .updated = best { return true }
        return false
    }
}

#Preview("自己ベスト更新") {
    QuizResultView(
        score: 2_480,
        correctCount: 14,
        maxCombo: 9,
        answerRecords: [],
        gameMode: .timeAttack(.thirtySeconds),
        isNewRecord: true,
        timeAttackComparison: TimeAttackComparison(
            score: 2_480,
            recordsBefore: [ScoreRecord(score: 2_160, achievedAt: .now)],
            previousScore: 1_900
        ),
        breakdown: ScoreBreakdown(correctPoints: 1_400, comboBonus: 780, speedBonus: 600, penalty: 300),
        onPlayAgain: {}
    )
}

#Preview {
    QuizResultView(
        score: 1_250,
        correctCount: 6,
        maxCombo: 4,
        answerRecords: [
            QuizAnswerRecord(id: 1, number: 391, isPrime: false, answeredPrime: true),
            QuizAnswerRecord(id: 2, number: 397, isPrime: true, answeredPrime: false),
            QuizAnswerRecord(id: 3, number: 8, isPrime: false, answeredPrime: true),
            QuizAnswerRecord(id: 4, number: 1, isPrime: false, answeredPrime: true)
        ]
    )
}

/// 0 から目標の値まで数え上げながら表示するスコア
///
/// `Animatable` にすることで、`withAnimation` の途中の値ごとに本文が描き直される。
/// `contentTransition(.numericText)` は桁の切り替わりを演出するだけで途中の数を経由しないため、こちらを使う。
private struct CountingScoreText: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text("Your Score is \(Int(value.rounded())) points!")
    }
}
