//
//  TimeAttackRecordStoreTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class TimeAttackRecordStoreTests: XCTestCase {

    private var store: SwiftDataTimeAttackRecordStore!

    override func setUp() {
        super.setUp()
        // 実機の記録を壊さないよう、テストごとにメモリ上のコンテナを使う
        store = .inMemory()
    }

    // MARK: - 保存

    func testNoRecordsBeforeSaving() {
        XCTAssertEqual(store.allRecords(), [])
        XCTAssertEqual(store.records(gameMode: .timeAttack(.thirtySeconds), difficulty: .normal), [])
    }

    func testSavedRecordRoundTrips() {
        let record = makeRecord(duration: .sixtySeconds, difficulty: .hard, score: 3_200, playedAt: 100)
        store.save(record)
        XCTAssertEqual(store.allRecords(), [record])
    }

    func testSavedRecordsAreVisibleFromAnotherStoreOnSameContainer() {
        let record = makeRecord(score: 500, playedAt: 100)
        store.save(record)
        let other = SwiftDataTimeAttackRecordStore(modelContainer: store.modelContainer)
        XCTAssertEqual(other.allRecords(), [record])
    }

    // MARK: - 取得

    func testRecordsAreSortedOldestFirst() {
        let later = makeRecord(score: 100, playedAt: 300)
        let earlier = makeRecord(score: 200, playedAt: 100)
        let middle = makeRecord(score: 300, playedAt: 200)
        [later, earlier, middle].forEach(store.save)
        XCTAssertEqual(store.allRecords(), [earlier, middle, later])
    }

    func testRecordsAreFilteredByDurationAndDifficulty() {
        let target = makeRecord(duration: .thirtySeconds, difficulty: .normal, score: 100, playedAt: 100)
        let otherDuration = makeRecord(duration: .fifteenSeconds, difficulty: .normal, score: 200, playedAt: 200)
        let otherDifficulty = makeRecord(duration: .thirtySeconds, difficulty: .hard, score: 300, playedAt: 300)
        [target, otherDuration, otherDifficulty].forEach(store.save)

        XCTAssertEqual(store.records(gameMode: .timeAttack(.thirtySeconds), difficulty: .normal), [target])
        XCTAssertEqual(store.records(gameMode: .timeAttack(.fifteenSeconds), difficulty: .normal), [otherDuration])
        XCTAssertEqual(store.records(gameMode: .timeAttack(.thirtySeconds), difficulty: .hard), [otherDifficulty])
    }

    func testNonTimeAttackModeHasNoRecords() {
        store.save(makeRecord(playedAt: 100))
        XCTAssertEqual(store.records(gameMode: .practice, difficulty: .normal), [])
        XCTAssertEqual(store.records(gameMode: .dailyChallenge, difficulty: .normal), [])
    }

    // MARK: - 削除

    func testDeleteAllRemovesEveryRecord() {
        store.save(makeRecord(duration: .fifteenSeconds, playedAt: 100))
        store.save(makeRecord(duration: .sixtySeconds, difficulty: .easy, playedAt: 200))
        store.deleteAll()
        XCTAssertEqual(store.allRecords(), [])
    }

    func testCanSaveAfterDeleteAll() {
        store.save(makeRecord(score: 100, playedAt: 100))
        store.deleteAll()
        let record = makeRecord(score: 200, playedAt: 200)
        store.save(record)
        XCTAssertEqual(store.allRecords(), [record])
    }

    // MARK: - 記録の値

    func testGameModeUsesDuration() {
        let record = makeRecord(duration: .fifteenSeconds, playedAt: 100)
        XCTAssertEqual(record.gameMode, .timeAttack(.fifteenSeconds))
        XCTAssertEqual(record.gameMode.id, "timeAttack_15")
    }

    func testAccuracyIsCorrectOverAnswered() {
        let record = TimeAttackPlayRecord(
            playedAt: Date(timeIntervalSince1970: 100), duration: .thirtySeconds, difficulty: .normal,
            score: 0, correctCount: 3, answeredCount: 4, maxCombo: 2
        )
        XCTAssertEqual(record.accuracy, 0.75)
    }

    func testAccuracyIsNilWithoutAnswers() {
        let record = TimeAttackPlayRecord(
            playedAt: Date(timeIntervalSince1970: 100), duration: .thirtySeconds, difficulty: .normal,
            score: 0, correctCount: 0, answeredCount: 0, maxCombo: 0
        )
        XCTAssertNil(record.accuracy)
    }

    func testStoredRecordWithUnknownValuesIsSkipped() {
        let stored = StoredTimeAttackPlay(makeRecord(playedAt: 100))
        stored.timeLimitSeconds = 45
        XCTAssertNil(stored.record)
        stored.timeLimitSeconds = 30
        stored.difficulty = "Insane"
        XCTAssertNil(stored.record)
    }

    // MARK: - Helpers

    private func makeRecord(
        duration: TimeAttackDuration = .thirtySeconds,
        difficulty: Difficulty = .normal,
        score: Int = 1_000,
        playedAt: TimeInterval
    ) -> TimeAttackPlayRecord {
        TimeAttackPlayRecord(
            playedAt: Date(timeIntervalSince1970: playedAt),
            duration: duration,
            difficulty: difficulty,
            score: score,
            correctCount: 8,
            answeredCount: 10,
            maxCombo: 5
        )
    }
}
