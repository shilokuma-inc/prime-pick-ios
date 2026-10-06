//
//  QuizView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/15.
//

import SwiftUI

struct QuizView: View {
    /// タイムアタックで残りの問題がこの数以下になったら追加生成する
    private static let refillThreshold: Int = 3
    /// ミニ解説を表示しておく秒数
    private static let answerExplanationDuration: TimeInterval = 1.5

    // 画面の高さ（セーフエリア内）を縦に配る割合。3 つの合計が 1 になる（最下段に余りを置かない）。
    // 以前は出題領域 1/2 + 最下段の未使用 Spacer 1/12 だったが、#146 で設問文（44pt）を足したぶん
    // 数字カードの上下余白が消えたため、Spacer を 0 にして出題領域に回した（Discussion #216 の案 B）。
    // ボタンは領域の 3/4 の高さで中央に置かれるので、画面の下端からは 1/24（iPhone SE で約 25pt）空く

    /// 出題領域（`QuizContentView`）の割合
    private static let quizContentHeightRatio: CGFloat = 7 / 12
    /// ミニ解説の領域の割合（表示の有無で高さが変わらないよう固定）
    private static let answerExplanationHeightRatio: CGFloat = 1 / 12
    /// 解答ボタンの領域の割合
    private static let quizButtonHeightRatio: CGFloat = 1 / 3

    @Environment(\.dismiss) private var dismiss
    @State private var quizNumber: Int = 0
    @State var isPresentedResult: Bool = false
    @State private var scoreCalculator = ScoreCalculator()
    @State private var answerRecords: [QuizAnswerRecord] = []
    @State private var quizData: [QuizEntity]
    @State private var remainingSeconds: Int
    @State private var timer: Timer?
    /// 現在の問題が表示された時刻。速度ボーナスの計測基準
    @State private var questionStartDate: Date = Date()
    /// 解答直後に表示しているミニ解説。表示していないときは nil
    @State private var answerExplanation: AnswerExplanationItem?

    let difficulty: Difficulty
    let gameMode: GameMode
    let manager = QuizDataManager()
    let range: QuizRange
    let questionCount: QuizQuestionCount

    init(
        difficulty: Difficulty,
        gameMode: GameMode = .practice,
        range: QuizRange? = nil,
        questionCount: QuizQuestionCount = .default
    ) {
        let resolvedRange = range ?? difficulty.defaultRange
        self.difficulty = difficulty
        self.gameMode = gameMode
        self.range = resolvedRange
        self.questionCount = questionCount

        let setting = QuizSetting(difficulty: difficulty, gameMode: gameMode, range: range, questionCount: questionCount)
        if let demo = ScreenshotDemo.quiz, demo.setting == setting {
            // 撮影モード: 決まった出題と途中までの進行状態から始める
            _quizData = State(initialValue: demo.quizData)
            _quizNumber = State(initialValue: demo.quizNumber)
            _scoreCalculator = State(initialValue: demo.scoreCalculator)
            _answerRecords = State(initialValue: demo.answerRecords)
            _remainingSeconds = State(initialValue: demo.remainingSeconds)
            _isPresentedResult = State(initialValue: demo.isFinished)
            if gameMode.showsAnswerExplanation, !demo.isFinished, let explanation = demo.lastAnsweredExplanation {
                _answerExplanation = State(
                    initialValue: AnswerExplanationItem(id: demo.answeredCount, explanation: explanation)
                )
            }
            return
        }

        _quizData = State(
            initialValue: manager.makeQuizData(
                difficulty: difficulty,
                range: resolvedRange,
                questionCount: questionCount
            )
        )
        _remainingSeconds = State(initialValue: gameMode.timeLimitSeconds ?? 0)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: .zero) {
                    QuizContentView(
                        quizNumber: $quizNumber,
                        difficulty: difficulty,
                        gameMode: gameMode,
                        remainingSeconds: remainingSeconds,
                        quizData: quizData,
                        currentCombo: scoreCalculator.currentCombo
                    )
                    .frame(height: geometry.size.height * Self.quizContentHeightRatio)

                    // 表示の有無でボタンの位置が動かないよう、高さを固定した領域に出す
                    ZStack {
                        if let answerExplanation {
                            AnswerExplanationView(explanation: answerExplanation.explanation)
                                .id(answerExplanation.id)
                                .transition(.opacity)
                        }
                    }
                    .frame(height: geometry.size.height * Self.answerExplanationHeightRatio)
                    
                    QuizButtonView(
                        quizData: quizData,
                        difficulty: difficulty,
                        range: range,
                        questionStartDate: questionStartDate,
                        advanceDelay: gameMode.showsAnswerExplanation ? Self.answerExplanationDuration : 0,
                        scoreCalculator: $scoreCalculator,
                        quizIndex: $quizNumber,
                        isPresentedResult: $isPresentedResult,
                        answerRecords: $answerRecords
                    )
                    .frame(height: geometry.size.height * Self.quizButtonHeightRatio)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                if isPresentedResult {
                    QuizResultView(
                        score: scoreCalculator.totalScore,
                        correctCount: scoreCalculator.correctCount,
                        maxCombo: scoreCalculator.maxCombo,
                        answerRecords: answerRecords,
                        gameMode: gameMode
                    )
                }
            }
        }
        .sendAnalyticsScreen(.quiz)
        .onAppear {
            startTimerIfNeeded()
            // 1 問目が表示された時点を経過時間の基準にする
            questionStartDate = Date()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: quizNumber) { _, newValue in
            // 次の問題に切り替わった時点を経過時間の基準にする
            questionStartDate = Date()
            refillQuizDataIfNeeded(currentIndex: newValue)
        }
        .onChange(of: answerRecords.count) { _, _ in
            showAnswerExplanationIfNeeded()
        }
        .onChange(of: isPresentedResult) { _, isPresented in
            // 10 問を解き終えた場合など、タイムアップ以外の終了でもタイマーを止める
            if isPresented {
                stopTimer()
            }
        }
    }
}

private extension QuizView {
    /// タイムアタック時のみ 1 秒ごとのカウントダウンを開始する
    func startTimerIfNeeded() {
        guard gameMode.isTimeAttack, timer == nil, !isPresentedResult else { return }
        // 撮影モードでは残り時間を止めたまま撮る（動き続ける画面は撮影が落ち着かない）
        guard !ScreenshotDemo.isEnabled else { return }
        let scheduledTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            countDown()
        }
        // スクロールなどのトラッキング中でもカウントダウンを止めない
        RunLoop.main.add(scheduledTimer, forMode: .common)
        timer = scheduledTimer
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func countDown() {
        guard !isPresentedResult else { return }
        if remainingSeconds > 1 {
            remainingSeconds -= 1
        } else {
            remainingSeconds = 0
            finishByTimeUp()
        }
    }

    /// 時間切れでリザルトを表示する
    func finishByTimeUp() {
        stopTimer()
        isPresentedResult = true
    }

    /// 直前に解答した数のミニ解説を短時間だけ表示する
    func showAnswerExplanationIfNeeded() {
        guard gameMode.showsAnswerExplanation, let record = answerRecords.last else { return }

        let item = AnswerExplanationItem(id: answerRecords.count, explanation: NumberExplanation(number: record.number))
        withAnimation(.easeOut(duration: 0.15)) {
            answerExplanation = item
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.answerExplanationDuration) {
            // 続けて解答していた場合は、新しい解説を消さないよう何もしない
            guard answerExplanation?.id == item.id else { return }
            withAnimation(.easeIn(duration: 0.2)) {
                answerExplanation = nil
            }
        }
    }

    /// タイムアタックでは制限時間内に問題が尽きないよう、残りが少なくなったら追加生成する
    func refillQuizDataIfNeeded(currentIndex: Int) {
        guard gameMode.isTimeAttack else { return }
        guard currentIndex >= quizData.count - Self.refillThreshold else { return }
        quizData.append(
            contentsOf: manager.makeQuizData(
                difficulty: difficulty,
                range: range,
                questionCount: questionCount
            )
        )
    }
}

/// 表示中のミニ解説
///
/// 続けて解答したとき、前の解説を消すタイマーが新しい解説を消さないよう、解答ごとに異なる `id` を持たせる。
private struct AnswerExplanationItem: Equatable {
    let id: Int
    let explanation: NumberExplanation
}

#Preview {
    QuizView(difficulty: .easy, range: .oneOrTwoDigits, questionCount: .default)
}
