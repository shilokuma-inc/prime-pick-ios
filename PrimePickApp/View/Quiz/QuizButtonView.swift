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
    let range: QuizRange
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
        quizButton(choice: choice, size: size)
            .grayscale(isInputLocked ? 1 : 0)
            .opacity(isInputLocked ? 0.4 : 1)
            .animation(.easeInOut(duration: 0.1), value: isInputLocked)
            .answerFeedbackEffect(trigger: trigger)
            .sensoryFeedback(trigger: trigger) { _, trigger in
                trigger?.result.sensoryFeedback
            }
            .onTapGesture {
                answer(choice)
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
        guard !isPresentedResult, !isWaitingToAdvance, !isInputLocked else { return }

        let quiz = quizData[quizIndex]
        let record = QuizAnswerRecord(
            id: quiz.quizId,
            number: quiz.number,
            isPrime: quiz.isCorrect,
            answeredPrime: choice.isPrime
        )
        let elapsedTime = Date().timeIntervalSince(questionStartDate)
        answerRecords.append(record)
        scoreCalculator.submit(
            isCorrect: record.isAnswerCorrect,
            difficulty: difficulty,
            elapsedTime: elapsedTime
        )
        analytics.sendAnswer(
            AnswerAnalyticsEvent(
                difficulty: difficulty,
                range: range,
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
        SoundFeedback.play(result.sound)

        // 同じ結果が続いても触覚とアニメーションが再生されるよう、解答ごとに異なる ID を発行する
        feedbackSequence += 1
        let trigger = AnswerFeedbackTrigger(id: feedbackSequence, result: result)
        switch button {
        case .prime:
            primeButtonTrigger = trigger
        case .notPrime:
            notPrimeButtonTrigger = trigger
        }
    }
}

private func quizButton(choice: AnswerChoice, size: CGSize) -> some View {
    let color = choice.isPrime ? Color.quizCorrectButton : Color.quizIncorrectButton

    return ZStack {
        RoundedRectangle(cornerRadius: 25)
            .stroke(color, lineWidth: 5)
            .background(RoundedRectangle(cornerRadius: 25).fill(color.opacity(0.1)))
            .shadow(radius: 10)

        // 意味は文言で伝え、絵文字は一目で見分けるための補助として添える
        VStack(spacing: 8) {
            Text(choice.symbol)
                .font(.custom("ArialRoundedMTBold", size: 56))
                .minimumScaleFactor(0.5)

            Text(choice.title)
                // ArialRoundedMTBold には日本語の字形が無く細字で描かれるため、日本語も太字になるシステムフォントを使う
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
        }
        .padding(12)
    }
    .frame(width: size.width, height: size.height)
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
