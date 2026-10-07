//
//  DailyChallengeStoreTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class DailyChallengeStoreTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var store: UserDefaultsDailyChallengeStore!

    override func setUp() {
        super.setUp()
        // 実機の記録を壊さないよう、テストごとに使い捨ての領域を使う
        suiteName = "DailyChallengeStoreTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        store = UserDefaultsDailyChallengeStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - 記録

    func testStartedRecordIsIncompleteWithAllUnanswered() {
        let record = DailyChallengeRecord.started(
            dayKey: "2026-10-01",
            generatorVersion: 1,
            questionCount: 10,
            startedAt: Date(timeIntervalSince1970: 1_790_000_000)
        )
        XCTAssertFalse(record.isCompleted)
        XCTAssertEqual(record.results, Array(repeating: .unanswered, count: 10))
        XCTAssertEqual(record.answeredCount, 0)
        XCTAssertEqual(record.correctCount, 0)
        XCTAssertEqual(record.totalAnswerSeconds, 0)
    }

    func testCountsDistinguishUnanswered() {
        var record = makeRecord(dayKey: "2026-10-01")
        record.results = [.correct, .incorrect, .correct] + Array(repeating: .unanswered, count: 7)
        XCTAssertEqual(record.answeredCount, 3)
        XCTAssertEqual(record.correctCount, 2)
    }

    // MARK: - 保存

    func testNoRecordBeforeStarting() {
        XCTAssertNil(store.record(dayKey: "2026-10-01"))
        XCTAssertEqual(store.allRecords(), [])
    }

    func testSavedRecordRoundTrips() {
        var record = makeRecord(dayKey: "2026-10-01")
        record.results = [.correct, .incorrect] + Array(repeating: .correct, count: 8)
        record.completedAt = Date(timeIntervalSince1970: 1_790_000_065)
        record.totalAnswerSeconds = 42.5
        store.save(record)

        // 別のインスタンスからも読めること（＝ UserDefaults に保存されていること）
        let reloaded = UserDefaultsDailyChallengeStore(userDefaults: userDefaults)
        XCTAssertEqual(reloaded.record(dayKey: "2026-10-01"), record)
    }

    /// 始めた時点の記録を、解き終えた記録で置き換える
    func testSavingSameDayReplacesRecord() {
        let started = makeRecord(dayKey: "2026-10-01")
        store.save(started)
        var completed = started
        completed.completedAt = Date(timeIntervalSince1970: 1_790_000_100)
        store.save(completed)

        XCTAssertEqual(store.record(dayKey: "2026-10-01"), completed)
        XCTAssertEqual(store.allRecords().count, 1)
    }

    func testAllRecordsAreSortedByDayKey() {
        for dayKey in ["2026-10-03", "2026-09-30", "2026-10-01"] {
            store.save(makeRecord(dayKey: dayKey))
        }
        XCTAssertEqual(store.allRecords().map(\.dayKey), ["2026-09-30", "2026-10-01", "2026-10-03"])
    }

    /// 別の日の保存が同時に走っても、どの日の記録も消えない
    func testConcurrentSavesKeepAllRecords() {
        let dayKeys = (1...28).map { String(format: "2026-02-%02d", $0) }
        DispatchQueue.concurrentPerform(iterations: dayKeys.count) { index in
            UserDefaultsDailyChallengeStore(userDefaults: userDefaults).save(makeRecord(dayKey: dayKeys[index]))
        }
        XCTAssertEqual(store.allRecords().map(\.dayKey), dayKeys)
    }

    /// 保存データが壊れていても落ちず、記録なしとして扱う
    func testCorruptedDataIsTreatedAsEmpty() {
        userDefaults.set(Data("not json".utf8), forKey: UserDefaultsDailyChallengeStore.recordsKey)
        XCTAssertNil(store.record(dayKey: "2026-10-01"))
        XCTAssertEqual(store.allRecords(), [])
    }

    func testRecordsKeyIsVersioned() {
        XCTAssertEqual(UserDefaultsDailyChallengeStore.recordsKey, "dailyChallenge.records.v1")
    }

    private func makeRecord(dayKey: String) -> DailyChallengeRecord {
        .started(
            dayKey: dayKey,
            generatorVersion: 1,
            questionCount: 10,
            startedAt: Date(timeIntervalSince1970: 1_790_000_000)
        )
    }
}
