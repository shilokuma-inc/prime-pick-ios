//
//  DailyChallengeResult.swift
//  PrimePickApp
//

import Foundation

/// デイリーの結果画面に出す値（Discussion #181 本文 2-4）
///
/// 記録と出題から組み立てる。出題は `dayKey` と版から作り直せるので、挑戦済みの日に開き直しても同じ復習一覧を出せる。
struct DailyChallengeResult {
    let record: DailyChallengeRecord
    let quizData: [QuizEntity]
    let streak: DailyChallengeStreak

    /// 1 日分の記録から結果を組み立てる。出題は記録に残した版の生成器で作り直す
    init(record: DailyChallengeRecord, records: [DailyChallengeRecord], today: DailyChallengeDay) {
        let generator = DailyChallengeGenerator(rawValue: record.generatorVersion) ?? .v1
        self.init(
            record: record,
            quizData: generator.makeQuizData(dayKey: record.dayKey),
            streak: DailyChallengeStreak(records: records, today: today)
        )
    }

    init(record: DailyChallengeRecord, quizData: [QuizEntity], streak: DailyChallengeStreak) {
        self.record = record
        self.quizData = quizData
        self.streak = streak
    }

    /// 通し番号（`#12`）。記録の `dayKey` が読めなければ nil
    var dayNumber: Int? {
        DailyChallengeDay(dayKey: record.dayKey)?.dayNumber
    }

    /// 解答した問題の記録。復習一覧に渡す。未解答の問題は含めない
    var answerRecords: [QuizAnswerRecord] {
        zip(record.results, quizData).compactMap { result, quiz in
            switch result {
            case .correct:
                return QuizAnswerRecord(id: quiz.quizId, number: quiz.number, isPrime: quiz.isCorrect, answeredPrime: quiz.isCorrect)
            case .incorrect:
                return QuizAnswerRecord(id: quiz.quizId, number: quiz.number, isPrime: quiz.isCorrect, answeredPrime: !quiz.isCorrect)
            case .unanswered:
                return nil
            }
        }
    }

    /// 10 問の正誤の並び。正解 🟩・不正解 🟥・未解答 ⬜
    var resultPattern: String {
        record.results.map(Self.symbol(for:)).joined()
    }

    /// 正誤の並びの読み上げ（「1 問目 正解、2 問目 不正解、…」）。並びの順を保つ
    static func accessibilityDescription(of results: [DailyChallengeAnswerResult]) -> String {
        results.enumerated().map { index, result in
            let number = index + 1
            switch result {
            case .correct:
                return String(localized: "Question \(number): Correct")
            case .incorrect:
                return String(localized: "Question \(number): Incorrect")
            case .unanswered:
                return String(localized: "Question \(number): Unanswered")
            }
        }
        .joined(separator: ", ")
    }

    static func symbol(for result: DailyChallengeAnswerResult) -> String {
        switch result {
        case .correct:
            return "🟩"
        case .incorrect:
            return "🟥"
        case .unanswered:
            return "⬜"
        }
    }

    /// 合計解答時間の表示（小数第 1 位まで。例: `42.5`）。言語によらず同じ表記にする
    static func totalSecondsText(_ seconds: TimeInterval) -> String {
        String(format: "%.1f", max(0, seconds))
    }

    /// 次のデイリーまでの残り秒数。`today` の翌日 0 時（`timeZone` の地域）までを数える
    static func secondsUntilNextChallenge(now: Date, timeZone: TimeZone) -> Int {
        let today = DailyChallengeDay(date: now, timeZone: timeZone)
        guard let next = today.adding(days: 1).startDate(in: timeZone) else { return 0 }
        return max(0, Int(next.timeIntervalSince(now).rounded(.up)))
    }

    /// 残り秒数の表示（`05:12:33`）
    static func countdownText(seconds: Int) -> String {
        let clamped = max(0, seconds)
        return String(format: "%02d:%02d:%02d", clamped / 3600, clamped % 3600 / 60, clamped % 60)
    }

    /// 「タイムアタックで遊ぶ」で始めるタイムアタックの設定
    ///
    /// タイトル画面で選んでいる制限時間・レンジ・問題数を引き継ぐ。モードが練習なら 60 秒にする。
    /// 難易度はデイリーの中心の段階（3 桁）と同じ Normal にする。
    static func timeAttackSetting(
        selectedGameMode: GameMode,
        selectedRange: QuizRange?,
        selectedQuestionCount: QuizQuestionCount
    ) -> QuizSetting {
        QuizSetting(
            difficulty: .normal,
            gameMode: selectedGameMode.isTimeAttack ? selectedGameMode : .timeAttack(.sixtySeconds),
            range: selectedRange,
            questionCount: selectedQuestionCount
        )
    }
}
