//
//  DailyChallengeAnalyticsEventTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class DailyChallengeAnalyticsEventTests: XCTestCase {

    // MARK: - イベントの形

    func testStartEvent() {
        let event = DailyChallengeAnalyticsEvent.start(dayNumber: 12, streakBefore: 4)
        XCTAssertEqual(event.name, "daily_challenge_start")
        XCTAssertEqual(event.parameters.count, 2)
        XCTAssertEqual(event.parameters["day_number"] as? Int, 12)
        XCTAssertEqual(event.parameters["streak_before"] as? Int, 4)
    }

    func testCompleteEvent() {
        let event = DailyChallengeAnalyticsEvent.complete(dayNumber: 12, correctCount: 8, totalSeconds: 42.5, streak: 5)
        XCTAssertEqual(event.name, "daily_challenge_complete")
        XCTAssertEqual(event.parameters.count, 4)
        XCTAssertEqual(event.parameters["day_number"] as? Int, 12)
        XCTAssertEqual(event.parameters["correct_count"] as? Int, 8)
        XCTAssertEqual(event.parameters["total_seconds"] as? TimeInterval, 42.5)
        XCTAssertEqual(event.parameters["streak"] as? Int, 5)
    }

    func testAbandonEvent() {
        let event = DailyChallengeAnalyticsEvent.abandon(dayNumber: 12, questionNumber: 4)
        XCTAssertEqual(event.name, "daily_challenge_abandon")
        XCTAssertEqual(event.parameters.count, 2)
        XCTAssertEqual(event.parameters["day_number"] as? Int, 12)
        XCTAssertEqual(event.parameters["question_number"] as? Int, 4)
    }

    func testQuizStartEvent() {
        let event = QuizStartAnalyticsEvent(
            gameMode: .timeAttack(.sixtySeconds),
            difficulty: .normal,
            range: .threeDigits,
            questionCount: .ten,
            source: .dailyResult
        )
        XCTAssertEqual(QuizStartAnalyticsEvent.name, "quiz_start")
        XCTAssertEqual(event.parameters.count, 5)
        XCTAssertEqual(event.parameters["game_mode"] as? String, "timeAttack_60")
        XCTAssertEqual(event.parameters["difficulty"] as? String, "Normal")
        XCTAssertEqual(event.parameters["quiz_range"] as? String, "100-999")
        XCTAssertEqual(event.parameters["question_count"] as? Int, 10)
        XCTAssertEqual(event.parameters["source"] as? String, "daily_result")
    }

    /// デイリーは `daily_challenge_start` で測るので `quiz_start` は送らない
    func testQuizStartIsNotSentForDailyChallenge() {
        XCTAssertNil(QuizView.quizStartEvent(gameMode: .dailyChallenge, difficulty: .easy, range: .oneOrTwoDigits, questionCount: .ten, source: .title))
        XCTAssertEqual(
            QuizView.quizStartEvent(gameMode: .practice, difficulty: .easy, range: .oneOrTwoDigits, questionCount: .ten, source: .title)?.source,
            .title
        )
    }

    /// タイトルの難易度ボタンからは `title`、デイリーの結果画面からは `daily_result`
    func testSourceOfSettings() {
        XCTAssertEqual(QuizSetting(difficulty: .easy, gameMode: .practice, range: nil, questionCount: .ten).source, .title)
        XCTAssertEqual(
            DailyChallengeResult.timeAttackSetting(selectedGameMode: .practice, selectedRange: nil, selectedQuestionCount: .ten).source,
            .dailyResult
        )
    }

    // MARK: - 送るタイミング

    func testFinisherSendsCompleteWithStreakAfterFinishing() {
        let (store, cleanup) = makeStore()
        defer { cleanup() }
        let day = DailyChallengeDay(year: 2026, month: 10, day: 15)
        var yesterday = DailyChallengeRecord.started(dayKey: day.adding(days: -1).dayKey, generatorVersion: 1, questionCount: 10, startedAt: Date())
        yesterday.completedAt = Date()
        store.save(yesterday)

        var events: [DailyChallengeAnalyticsEvent] = []
        let finisher = DailyChallengePlayFinisher(
            startedRecord: .started(dayKey: day.dayKey, generatorVersion: 1, questionCount: 10, startedAt: Date()),
            store: store,
            sendAnalytics: { events.append($0) }
        )
        _ = finisher.finish(outcome(answers: [true, true, false, true, true, true, true, true, true, false], elapsedSeconds: 2))

        XCTAssertEqual(events, [.complete(dayNumber: day.dayNumber, correctCount: 8, totalSeconds: 20, streak: 2)])
    }

    /// やめたときに表示していた問題（解答済み + 1）を送る
    func testFinisherSendsAbandonWithShownQuestion() {
        let (store, cleanup) = makeStore()
        defer { cleanup() }
        let day = DailyChallengeDay(year: 2026, month: 10, day: 15)
        var events: [DailyChallengeAnalyticsEvent] = []
        let finisher = DailyChallengePlayFinisher(
            startedRecord: .started(dayKey: day.dayKey, generatorVersion: 1, questionCount: 10, startedAt: Date()),
            store: store,
            sendAnalytics: { events.append($0) }
        )
        finisher.abandon(outcome(answers: [true, false, true], elapsedSeconds: 1))
        finisher.abandon(outcome(answers: [], elapsedSeconds: 1))

        XCTAssertEqual(events, [
            .abandon(dayNumber: day.dayNumber, questionNumber: 4),
            .abandon(dayNumber: day.dayNumber, questionNumber: 1)
        ])
    }

    /// 3 問目に答えてミニ解説を出している間（画面はまだ 3 問目）にやめたら、3 問目として送る
    func testAbandonDuringExplanationSendsShownQuestion() {
        let (store, cleanup) = makeStore()
        defer { cleanup() }
        let day = DailyChallengeDay(year: 2026, month: 10, day: 15)
        var events: [DailyChallengeAnalyticsEvent] = []
        let finisher = DailyChallengePlayFinisher(
            startedRecord: .started(dayKey: day.dayKey, generatorVersion: 1, questionCount: 10, startedAt: Date()),
            store: store,
            sendAnalytics: { events.append($0) }
        )
        var answered = outcome(answers: [true, false, true], elapsedSeconds: 1)
        answered.shownQuestionNumber = 3
        finisher.abandon(answered)

        XCTAssertEqual(events, [.abandon(dayNumber: day.dayNumber, questionNumber: 3)])
    }

    // MARK: - ヘルパー

    private func makeStore() -> (UserDefaultsDailyChallengeStore, () -> Void) {
        let suiteName = "DailyChallengeAnalyticsEventTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        return (UserDefaultsDailyChallengeStore(userDefaults: userDefaults), { userDefaults.removePersistentDomain(forName: suiteName) })
    }

    private func outcome(answers: [Bool], elapsedSeconds: TimeInterval) -> QuizPlayOutcome {
        QuizPlayOutcome(
            gameMode: .dailyChallenge,
            difficulty: .easy,
            score: 0,
            correctCount: answers.filter { $0 }.count,
            answerRecords: answers.enumerated().map { index, correct in
                QuizAnswerRecord(id: index + 1, number: 7, isPrime: true, answeredPrime: correct, elapsedSeconds: elapsedSeconds)
            }
        )
    }
}
