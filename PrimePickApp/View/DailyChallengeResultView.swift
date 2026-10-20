//
//  DailyChallengeResultView.swift
//  PrimePickApp
//

import SwiftUI

/// デイリーチャレンジの結果画面（Discussion #181 本文 2-4）
///
/// 解き終えた直後と、挑戦済みの日に開いたとき（2 回目以降は結果の表示だけ）の両方で出す。
/// タイムアタックのスコアは出さず、正解数と合計解答時間だけで評価する（Q2）。インタースティシャルは出さない（本文 7 章）。
struct DailyChallengeResultView: View {
    let result: DailyChallengeResult
    /// 「タイムアタックで遊ぶ」を押したとき。nil ならボタンを出さない
    var onPlayTimeAttack: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    private var record: DailyChallengeRecord { result.record }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    Text(verbatim: result.resultPattern)
                        .font(.system(size: 30))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        // 絵文字の並びは読み上げても意味が伝わらないため、問題ごとの番号と結果を順に読み上げる
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(verbatim: DailyChallengeResult.accessibilityDescription(of: record.results)))

                    summary

                    streakAndCountdown

                    QuizReviewList(answerRecords: result.answerRecords, isComplete: record.isCompleted)

                    buttons
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
        // 広告の分だけ下を空け、ボタンに重ねない（結果はスクロールで読める）
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AdNativeAdView(placement: .dailyChallengeResult)
        }
        .sendAnalyticsScreen(.quizResult)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Daily Challenge")
                .appFont(.heading(size: 28, weight: .bold))
            if let dayNumber = result.dayNumber {
                Text(verbatim: "#\(dayNumber)")
                    .appFont(.heading(size: 20, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var summary: some View {
        VStack(spacing: 6) {
            if record.isCompleted {
                Text("\(record.correctCount) / \(record.results.count) correct")
                    .appFont(.heading(size: 26, weight: .bold))
            } else {
                Text("Incomplete \(record.answeredCount) / \(record.results.count)")
                    .appFont(.heading(size: 26, weight: .bold))
            }
            Text("Total Time \(DailyChallengeResult.totalSecondsText(record.totalAnswerSeconds)) sec")
                .font(.headline)
                .monospacedDigit()
        }
    }

    private var streakAndCountdown: some View {
        VStack(spacing: 6) {
            HStack(spacing: 16) {
                Text(verbatim: "🔥 \(result.streak.current)")
                    .appFont(.heading(size: 24, weight: .bold))
                    .accessibilityLabel(Text("Streak \(result.streak.current) days"))
                Text("Best \(result.streak.longest)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            NextChallengeCountdown()
        }
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            // 主ボタンはアクセント色で塗り、副ボタンは色の付いていない neutral にして主従を分ける
            if let onPlayTimeAttack {
                Button(action: onPlayTimeAttack) {
                    Text("Play Time Attack")
                        .appFont(.number(size: 22))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(GameButtonStyle(appearance: GameButtonAppearance(color: .accentColor)))
            }

            Button {
                dismiss()
            } label: {
                Text("Return to Title")
                    .appFont(.number(size: 22))
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(GameButtonStyle(appearance: .neutral()))
        }
    }
}

/// 次のデイリーまでの残り時間。毎秒更新し、撮影モードでは止める
private struct NextChallengeCountdown: View {
    var body: some View {
        if ScreenshotDemo.isEnabled {
            label(now: Date())
        } else {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                label(now: context.date)
            }
        }
    }

    private func label(now: Date) -> some View {
        let seconds = DailyChallengeResult.secondsUntilNextChallenge(now: now, timeZone: .current)
        return Text("Next challenge in \(DailyChallengeResult.countdownText(seconds: seconds))")
            .font(.subheadline)
            .monospacedDigit()
            .foregroundStyle(.secondary)
    }
}
