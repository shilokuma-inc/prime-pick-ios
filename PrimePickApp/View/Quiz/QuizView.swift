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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var quizNumber: Int = 0
    @State var isPresentedResult: Bool = false
    @State private var scoreCalculator: ScoreCalculator
    @State private var answerRecords: [QuizAnswerRecord] = []
    @State private var quizData: [QuizEntity]
    @State private var remainingSeconds: Int
    @State private var timer: Timer?
    /// 現在の問題が表示された時刻。速度ボーナスの計測基準
    @State private var questionStartDate: Date = Date()
    /// 解答直後に表示しているミニ解説。表示していないときは nil
    @State private var answerExplanation: AnswerExplanationItem?
    /// 解答直後に出しているスコアの増減。表示していないときは nil
    @State private var scorePopup: ScorePopup?
    /// 誤答直後に出している時間ペナルティ。表示していないときは nil
    @State private var timePenaltyPopup: ScorePopup?
    /// コンボが切れた回数。変わるたびに画面を短く揺らす
    @State private var comboBreakCount: Int = 0
    /// 終わりの処理の結果。リザルトで NEW RECORD! と自己ベスト・前回との差を出すために使う
    @State private var finishResult = QuizPlayFinishResult()
    /// プレイの終わりの処理を済ませたか。1 プレイで 2 回記録しないために使う
    @State private var hasFinishedPlay = false
    /// 途中でやめる確認を出しているか
    @State private var isQuitConfirmationPresented = false

    let difficulty: Difficulty
    let gameMode: GameMode
    /// 1 プレイの間は同じ素数の出現確率を使い続けるため、`View` が作り直されても同じインスタンスを保持する
    @State private var manager: QuizDataManager
    let questionCount: QuizQuestionCount
    /// プレイの終わりの処理。既定は自己ベストの記録
    private let finisher: any QuizPlayFinishing
    /// どの画面から始めたか。`quiz_start` イベントの `source` に使う
    private let source: QuizStartSource
    /// `quiz_start` を送ったか。画面が出直しても 1 プレイで 1 回だけ送る
    @State private var hasSentQuizStart = false

    /// - Parameters:
    ///   - quizData: 外で作った出題（デイリーチャレンジなど）。`nil` か空なら `QuizDataManager` で作る
    ///   - finisher: プレイの終わりの処理。既定は自己ベストの記録
    init(
        difficulty: Difficulty,
        gameMode: GameMode = .practice,
        questionCount: QuizQuestionCount = .default,
        quizData providedQuizData: [QuizEntity]? = nil,
        finisher: any QuizPlayFinishing = BestScorePlayFinisher(),
        source: QuizStartSource = .title
    ) {
        self.difficulty = difficulty
        self.gameMode = gameMode
        self.questionCount = questionCount
        self.finisher = finisher
        self.source = source
        let manager = QuizDataManager()
        _manager = State(initialValue: manager)

        let setting = QuizSetting(difficulty: difficulty, gameMode: gameMode, questionCount: questionCount)
        // 出題を渡されたときは、設定が撮影モードの場面と一致しても渡された出題を使う
        if providedQuizData?.isEmpty ?? true, let demo = ScreenshotDemo.quiz, demo.setting == setting {
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
            initialValue: Self.initialQuizData(provided: providedQuizData) {
                manager.makeQuizData(
                    difficulty: difficulty,
                    range: difficulty.range,
                    questionCount: questionCount
                )
            }
        )
        _scoreCalculator = State(initialValue: ScoreCalculator(rule: gameMode.scoringRule))
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
                        difficulty: displayedDifficulty,
                        gameMode: gameMode,
                        remainingSeconds: remainingSeconds,
                        quizData: quizData,
                        // コンボを出さないモードでは、コンボ表示と MAX 段階の背景を出さないよう 0 として渡す
                        currentCombo: gameMode.showsCombo ? scoreCalculator.currentCombo : 0,
                        score: scoreCalculator.totalScore,
                        scorePopup: scorePopup,
                        timePenaltyPopup: timePenaltyPopup,
                        comboBreakCount: comboBreakCount
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
                        questionStartDate: questionStartDate,
                        advanceDelay: gameMode.showsAnswerExplanation ? Self.answerExplanationDuration : 0,
                        incorrectInputLockDuration: gameMode.missInputLockDuration,
                        scoreCalculator: $scoreCalculator,
                        quizIndex: $quizNumber,
                        isPresentedResult: $isPresentedResult,
                        answerRecords: $answerRecords
                    )
                    .frame(height: geometry.size.height * Self.quizButtonHeightRatio)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                if isPresentedResult && gameMode.showsQuizResult {
                    QuizResultView(
                        score: scoreCalculator.totalScore,
                        correctCount: scoreCalculator.correctCount,
                        maxCombo: scoreCalculator.maxCombo,
                        answerRecords: answerRecords,
                        gameMode: gameMode,
                        isNewRecord: finishResult.isNewRecord,
                        bestScoreComparison: finishResult.bestScoreComparison,
                        previousScoreDifference: finishResult.previousScoreDifference,
                        breakdown: scoreCalculator.breakdown
                    )
                }
            }
        }
        .sendAnalyticsScreen(.quiz)
        // デイリーの出題中は標準の戻るボタンを隠し、確認を挟む「やめる」に置き換える。
        // 戻るボタンを隠すとスワイプで戻る操作も効かなくなるので、確認を経ずに抜けられない
        .navigationBarBackButtonHidden(requiresQuitConfirmation)
        .toolbar {
            if requiresQuitConfirmation {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Quit") {
                        isQuitConfirmationPresented = true
                    }
                }
            }
        }
        .alert("Quit today's challenge?", isPresented: $isQuitConfirmationPresented) {
            Button("Quit", role: .destructive, action: quit)
            Button("Keep Playing", role: .cancel) {}
        } message: {
            Text("Unanswered questions will be left blank and your result will be final. You can't try today's challenge again.")
        }
        .onAppear {
            sendQuizStartIfNeeded()
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
        .onChange(of: scoreCalculator.currentCombo) { oldCombo, newCombo in
            handleComboChange(from: oldCombo, to: newCombo)
        }
        .onChange(of: answerRecords.count) { _, _ in
            finisher.recordProgress(currentOutcome)
            showAnswerExplanationIfNeeded()
            showScorePopupIfNeeded()
            applyMissTimePenaltyIfNeeded()
        }
        .onChange(of: isPresentedResult) { _, isPresented in
            // 10 問を解き終えた場合など、タイムアップ以外の終了でもタイマーを止める
            if isPresented {
                stopTimer()
                finishPlay()
            }
        }
    }
}

extension QuizView {
    /// プレイ開始の計測イベント。デイリーは別のイベントで測るので nil
    static func quizStartEvent(
        gameMode: GameMode,
        difficulty: Difficulty,
        range: QuizRange,
        questionCount: QuizQuestionCount,
        source: QuizStartSource
    ) -> QuizStartAnalyticsEvent? {
        guard gameMode != .dailyChallenge else { return nil }
        return QuizStartAnalyticsEvent(
            gameMode: gameMode,
            difficulty: difficulty,
            range: range,
            questionCount: questionCount,
            source: source
        )
    }

    /// やめた時点で全問に答えていれば、途中でやめたのではなく解き終えたものとして扱う
    static func quitCompletesPlay(answeredCount: Int, questionCount: Int) -> Bool {
        questionCount > 0 && answeredCount >= questionCount
    }

    /// 最初に出題する問題。渡された出題があればそれを使い、無ければ（空も含む）`makeQuizData` で作る
    ///
    /// 空の出題を受け取ると 1 問目の表示で範囲外アクセスになるため、空は渡されなかったものとして扱う。
    static func initialQuizData(
        provided: [QuizEntity]?,
        makeQuizData: () -> [QuizEntity]
    ) -> [QuizEntity] {
        if let provided, !provided.isEmpty {
            return provided
        }
        return makeQuizData()
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
            if gameMode.isInFinalCountdown(remainingSeconds: remainingSeconds) {
                SoundFeedback.play(.countdownTick)
            }
        } else {
            remainingSeconds = 0
            finishByTimeUp()
        }
    }

    /// プレイの終わりの処理を 1 回だけ行う
    ///
    /// 解き終えた・時間切れのどちらで終わっても、結果画面を出す時点でここを通る。
    /// 撮影モードの結果画面は最初から表示した状態で始まるため、ここを通らず記録もしない。
    func finishPlay() {
        guard !hasFinishedPlay else { return }
        hasFinishedPlay = true
        finishResult = finisher.finish(currentOutcome)
    }

    /// 練習・タイムアタックを始めたことを 1 回だけ送る。デイリーは `daily_challenge_start` で測るので送らない
    func sendQuizStartIfNeeded() {
        guard let event = Self.quizStartEvent(
            gameMode: gameMode,
            difficulty: difficulty,
            range: difficulty.range,
            questionCount: questionCount,
            source: source
        ), !hasSentQuizStart else { return }
        hasSentQuizStart = true
        FirebaseAnalytics().sendQuizStart(event)
    }

    /// 途中でやめるときに確認を挟むか。結果画面を出したあとは確認せずに戻れる
    var requiresQuitConfirmation: Bool {
        gameMode.confirmsBeforeQuitting && !isPresentedResult
    }

    /// 確認のうえで途中でやめる。解答済みまでで結果を確定して画面を閉じる
    func quit() {
        stopTimer()
        if Self.quitCompletesPlay(answeredCount: answerRecords.count, questionCount: quizData.count) {
            // 最後の問題に答えてミニ解説を出している間にやめた場合は、解き終えた扱いにする
            finishPlay()
        } else {
            finisher.abandon(currentOutcome)
        }
        dismiss()
    }

    /// ここまでの解答を反映したプレイの結果
    var currentOutcome: QuizPlayOutcome {
        QuizPlayOutcome(
            gameMode: gameMode,
            difficulty: difficulty,
            score: scoreCalculator.totalScore,
            correctCount: scoreCalculator.correctCount,
            answerRecords: answerRecords,
            maxCombo: scoreCalculator.maxCombo,
            shownQuestionNumber: quizNumber + 1
        )
    }

    /// 背景色などの見た目に使う難易度。表示中の問題の難易度に合わせる
    ///
    /// 練習・タイムアタックは全問がプレイの難易度と同じなので変わらない。
    /// デイリーは 2 桁 → 3 桁 → Hard と段階で難易度が変わるため、段階に合わせて背景色が変わる。
    var displayedDifficulty: Difficulty {
        quizData.indices.contains(quizNumber) ? quizData[quizNumber].difficulty : difficulty
    }

    /// 時間切れでリザルトを表示する
    func finishByTimeUp() {
        stopTimer()
        SoundFeedback.play(.timeUp)
        isPresentedResult = true
    }

    /// コンボ切れで画面を揺らして下降音を鳴らし、段階が上がったら到達音を鳴らして VoiceOver で読み上げる
    ///
    /// 毎問読み上げると邪魔になるため、読み上げは段階が上がったときだけにする。
    func handleComboChange(from oldCombo: Int, to newCombo: Int) {
        guard gameMode.showsCombo else { return }
        // コンボ表示が出ていた（2 以上）ときだけ「切れた」とみなす
        if newCombo == 0, oldCombo >= 2 {
            SoundFeedback.play(.comboBreak)
            if !reduceMotion {
                comboBreakCount += 1
            }
        }
        if ComboStage.didStageUp(from: oldCombo, to: newCombo) {
            let stage = ComboStage(combo: newCombo)
            SoundFeedback.play(.comboStageUp(stage))
            if let announcement = stage.announcement {
                AccessibilityNotification.Announcement(String(localized: announcement)).post()
            }
        }
    }

    /// タイムアタックの誤答で残り時間を減らす。残り時間が尽きたらその場でタイムアップにする
    func applyMissTimePenaltyIfNeeded() {
        guard gameMode.missTimePenaltySeconds > 0,
              !isPresentedResult,
              let record = answerRecords.last,
              !record.isAnswerCorrect
        else { return }

        let secondsBeforePenalty = remainingSeconds
        remainingSeconds = gameMode.remainingSecondsAfterMiss(from: remainingSeconds)
        showTimePenaltyPopup(deductedSeconds: secondsBeforePenalty - remainingSeconds)
        if remainingSeconds == 0 {
            finishByTimeUp()
        }
    }

    /// タイムアタックで、直前の解答によるスコアの増減をポップアップで出す
    ///
    /// 練習モードはプレイ中にスコアを表示しないため出さない。
    func showScorePopupIfNeeded() {
        guard gameMode.isTimeAttack,
              let submission = scoreCalculator.lastSubmission,
              let popup = ScorePopup.score(id: answerRecords.count, submission: submission)
        else { return }
        scorePopup = popup
        DispatchQueue.main.asyncAfter(deadline: .now() + ScorePopup.displayDuration) {
            // 続けて解答していた場合は、新しいポップアップを消さないよう何もしない
            guard scorePopup?.id == popup.id else { return }
            scorePopup = nil
        }
    }

    /// 誤答で減った残り時間をポップアップで出す
    func showTimePenaltyPopup(deductedSeconds: Int) {
        guard let popup = ScorePopup.time(id: answerRecords.count, deductedSeconds: deductedSeconds) else { return }
        timePenaltyPopup = popup
        DispatchQueue.main.asyncAfter(deadline: .now() + ScorePopup.displayDuration) {
            guard timePenaltyPopup?.id == popup.id else { return }
            timePenaltyPopup = nil
        }
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
                range: difficulty.range,
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
    QuizView(difficulty: .easy, questionCount: .default)
}
