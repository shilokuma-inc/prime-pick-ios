//
//  QuizButtonView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/22.
//

import SwiftUI

struct QuizButtonView: View {
    var quizData: [QuizEntity]
    let difficulty: Difficulty
    /// 現在の問題が表示された時刻。速度ボーナスの計測基準
    let questionStartDate: Date
    /// 解答してから次の問題（またはリザルト）へ進むまでの待ち時間。0 なら即座に進む
    ///
    /// 練習モードではミニ解説を読み終えてから次の問題を出し、解説を読む時間が次の問題の速度ボーナスを削らないようにする。
    var advanceDelay: TimeInterval = 0
    /// 誤答後に入力を受け付けない時間。0 ならロックしない
    ///
    /// タイムアタックで誤答を連打して当てずっぽうに進めないよう、次の問題を出したうえで短時間だけボタンを止める。
    var incorrectInputLockDuration: TimeInterval = 0
    @Binding var scoreCalculator: ScoreCalculator
    @Binding var quizIndex: Int
    @Binding var isPresentedResult: Bool
    @Binding var answerRecords: [QuizAnswerRecord]
    @State private var notPrimeButtonTrigger: AnswerFeedbackTrigger?
    @State private var primeButtonTrigger: AnswerFeedbackTrigger?
    @State private var feedbackSequence: Int = 0
    /// 解答後、次の問題へ進むのを待っている間は true。その間の解答は受け付けない
    @State private var isWaitingToAdvance = false
    /// 誤答後の入力ロック中は true。ボタンをグレーアウトし、解答を受け付けない
    @State private var isInputLocked = false
    private let analytics = FirebaseAnalytics()

    var body: some View {
        GeometryReader { geometry in
            let buttonSize = CGSize(
                width: geometry.size.width * 2 / 5,
                height: geometry.size.height * 3 / 4
            )

            // 左 = 素数ではない / 右 = 素数 で固定する（Discussion #138 で決定）。
            // プレイヤーは位置で押し分けるため、問題ごと・画面ごとに入れ替えない。
            HStack {
                Spacer()

                answerButton(.notPrime, size: buttonSize, trigger: notPrimeButtonTrigger)

                Spacer()

                answerButton(.prime, size: buttonSize, trigger: primeButtonTrigger)

                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func answerButton(_ choice: AnswerChoice, size: CGSize, trigger: AnswerFeedbackTrigger?) -> some View {
        // 触覚は正誤の触覚（`trigger`）だけを返す。触れた瞬間に解答するため、押した触覚と正誤の触覚は同時になる
        AnswerTouchArea(isEnabled: !isInputLocked) {
            answer(choice)
        } label: { isPressed in
            quizButton(choice: choice, size: size, isPressed: isPressed)
        }
        .grayscale(isInputLocked ? 1 : 0)
        .opacity(isInputLocked ? 0.4 : 1)
        .animation(.easeInOut(duration: 0.1), value: isInputLocked)
        .answerFeedbackEffect(trigger: trigger)
        .sensoryFeedback(trigger: trigger) { _, trigger in
            trigger?.sensoryFeedback
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(choice.accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            answer(choice)
        }
    }

    /// 解答を記録してスコアに反映し、フィードバックを再生して次の問題へ進める。最後の問題ならリザルトを表示する。
    /// タイムアタックでは `QuizView` が問題を補充するため、通常ここでは終了しない。
    private func answer(_ choice: AnswerChoice) {
        // 時間切れでリザルトを表示したあとは、背後のボタンに触れても解答・遷移させない
        guard Self.acceptsAnswer(
            isPresentedResult: isPresentedResult,
            isWaitingToAdvance: isWaitingToAdvance,
            isInputLocked: isInputLocked
        ) else { return }

        let quiz = quizData[quizIndex]
        let elapsedTime = Date().timeIntervalSince(questionStartDate)
        let record = QuizAnswerRecord(
            id: quiz.quizId,
            number: quiz.number,
            isPrime: quiz.isCorrect,
            answeredPrime: choice.isPrime,
            elapsedSeconds: elapsedTime
        )
        answerRecords.append(record)
        scoreCalculator.submit(
            isCorrect: record.isAnswerCorrect,
            difficulty: difficulty,
            elapsedTime: elapsedTime
        )
        analytics.sendAnswer(
            AnswerAnalyticsEvent(
                difficulty: quiz.difficulty,
                range: quiz.range,
                questionNumber: quizIndex + 1,
                isCorrect: record.isAnswerCorrect,
                elapsedSeconds: elapsedTime
            )
        )
        playFeedback(
            record.isAnswerCorrect ? .correct : .incorrect,
            on: choice
        )
        if !record.isAnswerCorrect {
            lockInputIfNeeded()
        }
        guard advanceDelay > 0 else {
            advance()
            return
        }
        isWaitingToAdvance = true
        DispatchQueue.main.asyncAfter(deadline: .now() + advanceDelay) {
            isWaitingToAdvance = false
            advance()
        }
    }

    /// 解答を受け付けるか。リザルト表示後・次の問題へ進むのを待っている間・誤答後のロック中は受け付けない
    static func acceptsAnswer(isPresentedResult: Bool, isWaitingToAdvance: Bool, isInputLocked: Bool) -> Bool {
        !isPresentedResult && !isWaitingToAdvance && !isInputLocked
    }

    /// 誤答後、`incorrectInputLockDuration` の間だけ解答を受け付けない
    private func lockInputIfNeeded() {
        guard incorrectInputLockDuration > 0 else { return }
        isInputLocked = true
        DispatchQueue.main.asyncAfter(deadline: .now() + incorrectInputLockDuration) {
            isInputLocked = false
        }
    }

    /// 次の問題へ進める。最後の問題ならリザルトを表示する
    private func advance() {
        guard !isPresentedResult else { return }
        if quizIndex < quizData.count - 1 {
            quizIndex += 1
        } else {
            isPresentedResult = true
        }
    }

    /// 効果音を鳴らし、タップされたボタンに触覚とアニメーションのきっかけを渡す
    ///
    /// 触覚は `sensoryFeedback` がこのきっかけの変化を検知して再生する。
    /// 効果音・触覚とも再生完了を待たないため、この直後の次の問題への遷移をブロックしない。
    private func playFeedback(_ result: AnswerFeedback, on button: AnswerChoice) {
        SoundFeedback.play(result.sound(combo: scoreCalculator.currentCombo))

        // 同じ結果が続いても触覚とアニメーションが再生されるよう、解答ごとに異なる ID を発行する
        feedbackSequence += 1
        let trigger = AnswerFeedbackTrigger(id: feedbackSequence, result: result, combo: scoreCalculator.currentCombo)
        switch button {
        case .prime:
            primeButtonTrigger = trigger
        case .notPrime:
            notPrimeButtonTrigger = trigger
        }
    }
}

/// 指が触れた瞬間に `onTouchDown` を呼ぶ押下領域（Discussion #307 Q4）
///
/// `Button` は指を離したときに action を呼ぶため使わず、`DragGesture(minimumDistance: 0)` で触れた瞬間を拾う。
/// 呼ぶのは 1 回のタッチにつき触れた瞬間の 1 回だけ。指を離すまでの間に次の問題へ進んでも、同じタッチで再び解答しない。
private struct AnswerTouchArea<Label: View>: View {
    /// false の間（誤答後のロック中）は沈み込みを見せない。解答を受け付けるかは `onTouchDown` の側で判定する
    let isEnabled: Bool
    let onTouchDown: () -> Void
    @ViewBuilder let label: (_ isPressed: Bool) -> Label

    /// 指が触れている間は true。タッチが取り消されたとき（着信など）も自動で false に戻る
    @GestureState private var isTouching = false
    /// 今のタッチで `onTouchDown` を呼んだか
    @State private var hasHandledCurrentTouch = false

    var body: some View {
        label(isEnabled && isTouching)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isTouching) { _, state, _ in
                        state = true
                    }
                    .onChanged { _ in
                        guard !hasHandledCurrentTouch else { return }
                        hasHandledCurrentTouch = true
                        onTouchDown()
                    }
                    .onEnded { _ in
                        hasHandledCurrentTouch = false
                    }
            )
            .onChange(of: isTouching) { _, isTouching in
                // onEnded が呼ばれずにタッチが取り消された場合も、次のタッチを受け付けられるよう戻す
                if !isTouching {
                    hasHandledCurrentTouch = false
                }
            }
    }
}

private func quizButton(choice: AnswerChoice, size: CGSize, isPressed: Bool) -> some View {
    let color = choice.isPrime ? Color.quizCorrectButton : Color.quizIncorrectButton
    // 上面は色の付いていない面にし、ボタンの色は枠線と側面で見せる
    let appearance = GameButtonAppearance.neutral(side: color)

    // 意味は文言で伝え、絵文字は一目で見分けるための補助として添える
    return VStack(spacing: 8) {
        Text(choice.symbol)
            .appFont(.number(size: 56))
            .minimumScaleFactor(0.5)

        Text(choice.title)
            // 選択肢の名前は見出しの書体で出す（数字の書体だった頃は日本語の字形が無く細字で描かれていた）
            .appFont(.heading(size: 30, weight: .bold))
            .foregroundStyle(Color.primary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.5)
    }
    .padding(12)
    // 側面の厚みの分だけ上面を低くし、ボタン全体の高さはこれまでと同じにする
    .frame(width: size.width, height: max(size.height - appearance.depth, 0))
    .overlay(
        RoundedRectangle(cornerRadius: GameButtonAppearance.defaultCornerRadius, style: .continuous)
            .strokeBorder(color, lineWidth: 5)
    )
    .gameButtonSurface(appearance, isPressed: isPressed)
}

private extension AnswerChoice {
    /// ボタンに表示する文言
    var title: LocalizedStringKey {
        switch self {
        case .notPrime:
            return "NOT PRIME"
        case .prime:
            return "PRIME"
        }
    }

    /// 文言に添える絵文字
    var symbol: String {
        switch self {
        case .notPrime:
            return "❌"
        case .prime:
            return "✅"
        }
    }

    /// VoiceOver で読み上げる文言
    var accessibilityLabel: Text {
        switch self {
        case .notPrime:
            return Text("Answer not prime")
        case .prime:
            return Text("Answer prime")
        }
    }
}
