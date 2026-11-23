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
    /// 共有シートに渡す項目。値が入っている間だけ共有シートを出す
    @State private var shareItems: [Any]?
    /// リマインドの案内。解き終えた直後にだけ出す
    @StateObject private var reminderPrompt: DailyReminderPromptModel

    /// - Parameter isJustFinished: 解き終えた直後か（挑戦済みの日に開き直したときは false）。true のときだけリマインドの案内を出しうる
    init(result: DailyChallengeResult, isJustFinished: Bool = false, onPlayTimeAttack: (() -> Void)? = nil) {
        self.result = result
        self.onPlayTimeAttack = onPlayTimeAttack
        _reminderPrompt = StateObject(wrappedValue: DailyReminderPromptModel(isJustFinished: isJustFinished))
    }

    private var record: DailyChallengeRecord { result.record }
    private var shareContent: DailyChallengeShareContent? { DailyChallengeShareContent(result: result) }

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

                    // シェアできるのは最後まで解いた日だけ（途中でやめた日はボタンを出さない）
                    if let shareContent {
                        shareButton(content: shareContent)
                    }

                    // シェアボタンの下に置き、主ボタンより目立たせない
                    if reminderPrompt.state != .hidden {
                        DailyReminderPromptCard(model: reminderPrompt)
                    }

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
                .appFont(.number(.headline))
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
                    .appFont(.number(.headline))
                    .foregroundStyle(.secondary)
            }

            NextChallengeCountdown()
        }
    }

    /// シェアボタン。この画面の主ボタンなのでアクセント色で塗る
    private func shareButton(content: DailyChallengeShareContent) -> some View {
        Button {
            FirebaseAnalytics().sendDailyChallenge(content.tapEvent)
            shareItems = content.activityItems(image: DailyChallengeShareCardView.renderImage(content: content))
        } label: {
            Label("Share Result", systemImage: "square.and.arrow.up")
                .appFont(.number(size: 22))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(GameButtonStyle(appearance: GameButtonAppearance(color: .accentColor), pressSound: Self.sharePressSound))
        .accessibilityLabel(Text("Share today's Daily Challenge result"))
        // iPad では共有シートのポップオーバーをこのボタンから出す
        .background(
            ActivityShareSheet(items: $shareItems) { activityType, completed in
                if let event = content.completeEvent(activityType: activityType, completed: completed) {
                    FirebaseAnalytics().sendDailyChallenge(event)
                }
            }
        )
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            // 主ボタンはシェアボタン（アクセント色）。ここのボタンは色の付いていない neutral にして主従を分ける
            if let onPlayTimeAttack {
                Button(action: onPlayTimeAttack) {
                    Text("Play Time Attack")
                        .appFont(.number(size: 22))
                        .foregroundStyle(Color.accentColor)
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(GameButtonStyle(appearance: .neutral(), pressSound: Self.playTimeAttackPressSound))
            }

            Button {
                dismiss()
            } label: {
                Text("Return to Title")
                    .appFont(.number(size: 22))
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(GameButtonStyle(appearance: .neutral(), pressSound: Self.returnToTitlePressSound))
        }
    }

    /// シェアボタンの押下音。画面を進めも戻しもしないので、どちらでもない押下音にする
    static let sharePressSound: SoundEffect = .buttonPressNeutral
    /// 「タイムアタックで遊ぶ」の押下音。次のゲームへ進むボタンなので、進む押下音にする
    static let playTimeAttackPressSound: SoundEffect = .buttonPressForward
    /// 「タイトルに戻る」の押下音。戻るボタンなので、戻る押下音にする
    static let returnToTitlePressSound: SoundEffect = .buttonPressBack
    /// リマインドの案内の「オンにする」の押下音。画面を進めも戻しもしないので、どちらでもない押下音にする
    static let reminderTurnOnPressSound: SoundEffect = .buttonPressNeutral
    /// リマインドの案内の「今はしない」の押下音。同上
    static let reminderNotNowPressSound: SoundEffect = .buttonPressNeutral
}

/// 結果画面のリマインドの案内（「オンにする」「今はしない」）。選んだ後は結果を短く伝える
private struct DailyReminderPromptCard: View {
    @ObservedObject var model: DailyReminderPromptModel

    var body: some View {
        VStack(spacing: 12) {
            switch model.state {
            case .hidden:
                EmptyView()
            case .asking, .requesting:
                asking
            case .enabled(let time):
                message(
                    Text("Reminders are on. We'll remind you at \(Self.timeText(time)).")
                )
            case .denied:
                message(
                    Text("Notifications aren't allowed. You can turn reminders on later in Settings.")
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.2), lineWidth: 2)
        )
        .onAppear { model.didAppear() }
    }

    private var asking: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("Get a reminder?")
                    .appFont(.heading(size: 20, weight: .bold))
                Text("We'll remind you at \(Self.timeText(model.time)) on days you haven't played the Daily Challenge yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button {
                    model.decline()
                } label: {
                    Text("Not Now")
                        .appFont(.number(size: 18))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(GameButtonStyle(appearance: .neutral(), pressSound: DailyChallengeResultView.reminderNotNowPressSound))

                Button {
                    Task { await model.enable() }
                } label: {
                    Group {
                        if model.state == .requesting {
                            ProgressView()
                        } else {
                            Text("Turn On")
                                .appFont(.number(size: 18))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(GameButtonStyle(appearance: .neutral(), pressSound: DailyChallengeResultView.reminderTurnOnPressSound))
            }
            .disabled(model.state == .requesting)
        }
    }

    private func message(_ text: Text) -> some View {
        Label {
            text
                .font(.subheadline)
                .multilineTextAlignment(.leading)
        } icon: {
            Image(systemName: "bell")
                .foregroundStyle(Color.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 端末の言語と 12/24 時間制に合わせた時刻（例: 20:00 / 8:00 PM）
    private static func timeText(_ time: DailyReminderTime) -> String {
        time.date().formatted(date: .omitted, time: .shortened)
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
