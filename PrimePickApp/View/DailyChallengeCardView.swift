//
//  DailyChallengeCardView.swift
//  PrimePickApp
//

import SwiftUI

/// タイトル画面の最上段に置く「今日のチャレンジ」カード
///
/// iPhone SE クラスでは縦の余白に余裕がないため、1 行に畳んだ高さ（約 60pt）に収める（Discussion #181 本文 2-6）。
/// 左に「今日のチャレンジ #n」と状態、右にストリーク `🔥 n` を出す。
struct DailyChallengeCardView: View {
    let state: DailyChallengeCardState

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Daily Challenge")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(verbatim: "#\(state.dayNumber)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                statusText
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(state.isPlayable ? Color.accentColor : .secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Spacer(minLength: 0)

            Text(verbatim: "🔥 \(state.streak)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .accessibilityLabel(Text("Streak \(state.streak) days"))

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(state.isPlayable ? Color.accentColor : Color.primary.opacity(0.2), lineWidth: 2)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var statusText: some View {
        switch state.status {
        case .notStarted:
            Text("Start today's 10 questions")
        case .incomplete(let answeredCount, let questionCount):
            Text("Incomplete \(answeredCount) / \(questionCount)")
        case .completed(let correctCount, let questionCount):
            Text("\(correctCount) / \(questionCount) correct")
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        DailyChallengeCardView(state: DailyChallengeCardState(status: .notStarted, dayNumber: 12, streak: 4))
        DailyChallengeCardView(state: DailyChallengeCardState(status: .incomplete(answeredCount: 3, questionCount: 10), dayNumber: 12, streak: 4))
        DailyChallengeCardView(state: DailyChallengeCardState(status: .completed(correctCount: 8, questionCount: 10), dayNumber: 12, streak: 5))
    }
    .padding()
}
