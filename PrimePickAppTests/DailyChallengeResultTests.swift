//
//  DailyChallengeResultTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class DailyChallengeResultTests: XCTestCase {

    private let today = DailyChallengeDay(year: 2026, month: 10, day: 1)
    private let startedAt = Date(timeIntervalSince1970: 1_790_000_000)

    // MARK: - 正誤の並びと復習

    func testResultPatternShowsEachQuestion() {
        let result = makeResult(results: [.correct, .incorrect] + Array(repeating: .correct, count: 5) + Array(repeating: .unanswered, count: 3))
        XCTAssertEqual(result.resultPattern, "🟩🟥🟩🟩🟩🟩🟩⬜⬜⬜")
    }

    /// VoiceOver では問題ごとの番号と結果を順に読み上げる
    func testAccessibilityDescriptionListsEachQuestionInOrder() {
        let description = DailyChallengeResult.accessibilityDescription(of: [.correct, .incorrect, .unanswered])
        let parts = description.components(separatedBy: ", ")
        // 文言は端末の言語で変わるため、件数・順序（番号）・結果ごとに別の文言であることを確かめる
        XCTAssertEqual(parts.count, 3)
        for (index, part) in parts.enumerated() {
            XCTAssertTrue(part.contains("\(index + 1)"), part)
        }
        let withoutNumbers = parts.map { $0.filter { !$0.isNumber } }
        XCTAssertEqual(Set(withoutNumbers).count, 3, "\(withoutNumbers)")
    }

    /// 復習一覧には解答した問題だけを渡し、間違えた問題は正解と逆の解答として組み立てる
    func testAnswerRecordsRebuildAnswersFromQuizData() {
        let result = makeResult(results: [.correct, .incorrect] + Array(repeating: .unanswered, count: 8))
        let quizData = DailyChallengeGenerator.v1.makeQuizData(dayKey: "2026-10-01")

        XCTAssertEqual(result.answerRecords.count, 2)
        XCTAssertEqual(result.answerRecords.map(\.number), Array(quizData.prefix(2).map(\.number)))
        XCTAssertTrue(result.answerRecords[0].isAnswerCorrect)
        XCTAssertFalse(result.answerRecords[1].isAnswerCorrect)
        XCTAssertEqual(result.answerRecords[1].isPrime, quizData[1].isCorrect)
    }

    /// 挑戦済みの日に開き直しても、記録に残した版の生成器で同じ出題を作り直す
    func testQuizDataIsRegeneratedFromRecord() {
        let result = makeResult(results: Array(repeating: .correct, count: 10))
        XCTAssertEqual(result.quizData.map(\.number), DailyChallengeGenerator.v1.makeQuizData(dayKey: "2026-10-01").map(\.number))
    }

    func testDayNumberAndStreak() {
        let record = completedRecord(dayKey: today.dayKey)
        let yesterday = completedRecord(dayKey: today.adding(days: -1).dayKey)
        let result = DailyChallengeResult(record: record, records: [yesterday, record], today: today)
        XCTAssertEqual(result.dayNumber, today.dayNumber)
        XCTAssertEqual(result.streak.current, 2)
        XCTAssertEqual(result.streak.longest, 2)
    }

    // MARK: - 時間

    func testTotalSecondsText() {
        XCTAssertEqual(DailyChallengeResult.totalSecondsText(42.46), "42.5")
        XCTAssertEqual(DailyChallengeResult.totalSecondsText(0), "0.0")
        XCTAssertEqual(DailyChallengeResult.totalSecondsText(-1), "0.0")
    }

    func testSecondsUntilNextChallengeCountsToLocalMidnight() {
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        let calendar = DailyChallengeDay.calendar(timeZone: tokyo)
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 23, minute: 59, second: 30))!
        XCTAssertEqual(DailyChallengeResult.secondsUntilNextChallenge(now: now, timeZone: tokyo), 30)

        let morning = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 0, minute: 0, second: 0))!
        XCTAssertEqual(DailyChallengeResult.secondsUntilNextChallenge(now: morning, timeZone: tokyo), 24 * 60 * 60)
    }

    func testCountdownText() {
        XCTAssertEqual(DailyChallengeResult.countdownText(seconds: 5 * 3600 + 12 * 60 + 33), "05:12:33")
        XCTAssertEqual(DailyChallengeResult.countdownText(seconds: 0), "00:00:00")
        XCTAssertEqual(DailyChallengeResult.countdownText(seconds: 24 * 3600), "24:00:00")
    }

    // MARK: - タイムアタックへの導線

    func testTimeAttackSettingKeepsSelectedTimeAttack() {
        let setting = DailyChallengeResult.timeAttackSetting(
            selectedGameMode: .timeAttack(.thirtySeconds),
            selectedQuestionCount: .twenty
        )
        XCTAssertEqual(
            setting,
            QuizSetting(difficulty: .normal, gameMode: .timeAttack(.thirtySeconds), questionCount: .twenty, source: .dailyResult)
        )
    }

    /// タイトルで練習を選んでいたら 60 秒のタイムアタックにする
    func testTimeAttackSettingFallsBackToSixtySecondsFromPractice() {
        let setting = DailyChallengeResult.timeAttackSetting(selectedGameMode: .practice, selectedQuestionCount: .default)
        XCTAssertEqual(setting.gameMode, .timeAttack(.sixtySeconds))
        XCTAssertEqual(setting.difficulty, .normal)
    }

    // MARK: - 結果画面への切り替え

    func testFinisherNotifiesFinishedRecord() {
        let suiteName = "DailyChallengeResultTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        var finished: DailyChallengeRecord?
        let started = DailyChallengeRecord.started(dayKey: today.dayKey, generatorVersion: 1, questionCount: 10, startedAt: startedAt)
        let finisher = DailyChallengePlayFinisher(
            startedRecord: started,
            store: UserDefaultsDailyChallengeStore(userDefaults: userDefaults),
            onFinish: { finished = $0 }
        )
        _ = finisher.finish(QuizPlayOutcome(gameMode: .dailyChallenge, difficulty: .easy, score: 0, correctCount: 0, answerRecords: []))
        XCTAssertEqual(finished?.dayKey, today.dayKey)
        XCTAssertEqual(finished?.isCompleted, true)
    }

    func testOnlyDailyChallengeUsesOwnResultScreen() {
        XCTAssertFalse(GameMode.dailyChallenge.showsQuizResult)
        XCTAssertTrue(GameMode.practice.showsQuizResult)
        XCTAssertTrue(GameMode.timeAttack(.sixtySeconds).showsQuizResult)
    }

    // MARK: - ヘルパー

    private func makeResult(results: [DailyChallengeAnswerResult]) -> DailyChallengeResult {
        var record = completedRecord(dayKey: today.dayKey)
        record.results = results
        return DailyChallengeResult(record: record, records: [record], today: today)
    }

    private func completedRecord(dayKey: String) -> DailyChallengeRecord {
        var record = DailyChallengeRecord.started(dayKey: dayKey, generatorVersion: 1, questionCount: 10, startedAt: startedAt)
        record.results = Array(repeating: .correct, count: 10)
        record.completedAt = startedAt.addingTimeInterval(60)
        return record
    }
}
