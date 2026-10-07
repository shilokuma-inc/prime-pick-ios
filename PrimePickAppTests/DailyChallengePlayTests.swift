//
//  DailyChallengePlayTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class DailyChallengePlayTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var store: UserDefaultsDailyChallengeStore!

    private let today = DailyChallengeDay(year: 2026, month: 10, day: 1)
    private let startedAt = Date(timeIntervalSince1970: 1_790_000_000)

    override func setUp() {
        super.setUp()
        suiteName = "DailyChallengePlayTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        store = UserDefaultsDailyChallengeStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - 1 日 1 回

    /// 開いた瞬間に始めた記録を保存し、その日の 10 問を出す
    func testFirstVisitSavesStartedRecordAndPlays() {
        let phase = DailyChallengeView.phase(for: today, now: startedAt, store: store, generator: .v1)
        guard case .playing(let quizData, let startedRecord) = phase else {
            return XCTFail("最初は遊べる")
        }
        XCTAssertEqual(quizData.map(\.number), DailyChallengeGenerator.v1.makeQuizData(dayKey: "2026-10-01").map(\.number))
        XCTAssertEqual(startedRecord.dayKey, "2026-10-01")
        XCTAssertEqual(startedRecord.generatorVersion, 1)
        XCTAssertEqual(startedRecord.startedAt, startedAt)
        XCTAssertEqual(store.record(dayKey: "2026-10-01"), startedRecord)
        XCTAssertFalse(startedRecord.isCompleted)
    }

    /// 始めた日は（解き終えていなくても）もう遊べず、記録の要約だけを出す
    func testSecondVisitShowsRecordOnly() {
        _ = DailyChallengeView.phase(for: today, now: startedAt, store: store, generator: .v1)
        let phase = DailyChallengeView.phase(for: today, now: startedAt.addingTimeInterval(60), store: store, generator: .v1)
        guard case .alreadyPlayed(let record) = phase else {
            return XCTFail("2 回目は遊べない")
        }
        XCTAssertEqual(record.startedAt, startedAt)
    }

    func testNextDayIsPlayableAgain() {
        _ = DailyChallengeView.phase(for: today, now: startedAt, store: store, generator: .v1)
        let phase = DailyChallengeView.phase(for: today.adding(days: 1), now: startedAt, store: store, generator: .v1)
        guard case .playing = phase else {
            return XCTFail("翌日は遊べる")
        }
    }

    // MARK: - 記録

    /// 1 問解くごとに途中経過を保存する。強制終了されても「未完了 3 / 10」を出せる
    func testProgressIsSavedAfterEachAnswer() {
        let finisher = DailyChallengePlayFinisher(startedRecord: startedRecord(), store: store)
        finisher.recordProgress(outcome(answers: [true, false, true]))

        let saved = store.record(dayKey: "2026-10-01")
        XCTAssertEqual(saved?.answeredCount, 3)
        XCTAssertEqual(saved?.correctCount, 2)
        XCTAssertEqual(saved?.results.suffix(7), Array(repeating: .unanswered, count: 7)[...])
        XCTAssertEqual(saved?.isCompleted, false)
    }

    /// 解き終えたら完了時刻と合計解答時間を保存する。NEW RECORD! は出さない
    func testFinishSavesCompletedRecord() {
        let completedAt = startedAt.addingTimeInterval(80)
        let finisher = DailyChallengePlayFinisher(startedRecord: startedRecord(), store: store, now: { completedAt })
        let answers = [true, true, false, true, true, true, false, true, true, true]
        XCTAssertFalse(finisher.finish(outcome(answers: answers, elapsedSeconds: 1.5)))

        let saved = store.record(dayKey: "2026-10-01")
        XCTAssertEqual(saved?.completedAt, completedAt)
        XCTAssertEqual(saved?.correctCount, 8)
        XCTAssertEqual(saved?.answeredCount, 10)
        XCTAssertEqual(saved?.totalAnswerSeconds ?? 0, 15, accuracy: 0.0001)
    }

    /// 23:59 に始めて 0:01 に解き終えても、始めた日の記録になる
    func testFinishAfterMidnightKeepsStartedDay() {
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        let calendar = DailyChallengeDay.calendar(timeZone: tokyo)
        let startedAt = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 23, minute: 59))!
        let completedAt = startedAt.addingTimeInterval(120)
        // 前提: 解き終えた時刻はもう翌日
        XCTAssertEqual(DailyChallengeDay(date: completedAt, timeZone: tokyo).dayKey, "2026-10-02")

        guard case .playing(_, let started) = DailyChallengeView.phase(
            for: DailyChallengeDay(date: startedAt, timeZone: tokyo),
            now: startedAt,
            store: store,
            generator: .v1
        ) else {
            return XCTFail("最初は遊べる")
        }
        let finisher = DailyChallengePlayFinisher(startedRecord: started, store: store, now: { completedAt })
        _ = finisher.finish(outcome(answers: Array(repeating: true, count: 10)))

        XCTAssertEqual(store.allRecords().map(\.dayKey), ["2026-10-01"])
        XCTAssertEqual(store.record(dayKey: "2026-10-01")?.completedAt, completedAt)
    }

    func testApplyingAnswerRecordsSumsElapsedSeconds() {
        let record = startedRecord().applying(answerRecords: [
            answer(id: 1, correct: true, elapsedSeconds: 2.0),
            answer(id: 2, correct: false, elapsedSeconds: 3.5)
        ])
        XCTAssertEqual(record.results.prefix(2), [.correct, .incorrect])
        XCTAssertEqual(record.totalAnswerSeconds, 5.5, accuracy: 0.0001)
    }

    // MARK: - モード

    func testDailyChallengeModeRules() {
        let mode = GameMode.dailyChallenge
        XCTAssertFalse(mode.isTimeAttack)
        XCTAssertNil(mode.timeLimitSeconds)
        XCTAssertTrue(mode.showsAnswerExplanation)
        XCTAssertFalse(mode.showsCombo)
        XCTAssertEqual(mode.missInputLockDuration, 0)
        XCTAssertEqual(mode.missTimePenaltySeconds, 0)
        // モード選択には出さず、自己ベストも保存しない
        XCTAssertFalse(GameMode.allCases.contains(.dailyChallenge))
        XCTAssertNil(BestScoreStore.key(gameMode: mode, difficulty: .easy))
        XCTAssertTrue(GameMode.practice.showsCombo)
    }

    // MARK: - ヘルパー

    private func startedRecord() -> DailyChallengeRecord {
        .started(dayKey: today.dayKey, generatorVersion: 1, questionCount: 10, startedAt: startedAt)
    }

    private func outcome(answers: [Bool], elapsedSeconds: TimeInterval = 1) -> QuizPlayOutcome {
        QuizPlayOutcome(
            gameMode: .dailyChallenge,
            difficulty: .easy,
            score: 0,
            correctCount: answers.filter { $0 }.count,
            answerRecords: answers.enumerated().map { index, correct in
                answer(id: index + 1, correct: correct, elapsedSeconds: elapsedSeconds)
            }
        )
    }

    private func answer(id: Int, correct: Bool, elapsedSeconds: TimeInterval) -> QuizAnswerRecord {
        // 7 は素数。正解なら素数と答え、不正解なら素数でないと答えたことにする
        QuizAnswerRecord(id: id, number: 7, isPrime: true, answeredPrime: correct, elapsedSeconds: elapsedSeconds)
    }
}
