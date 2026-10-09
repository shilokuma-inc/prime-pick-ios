//
//  SettingViewTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class SettingViewTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var bestScoreStore: BestScoreStore!

    override func setUp() {
        super.setUp()
        // 実機の自己ベストを壊さないよう、テストごとに使い捨ての領域を使う
        suiteName = "SettingViewTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        bestScoreStore = BestScoreStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - 記録のリセット（Discussion #223）

    func testResetDeletesPlayRecordsAndBestScores() throws {
        let recordStore = SwiftDataTimeAttackRecordStore.inMemory()
        recordStore.save(TimeAttackPlayRecord(
            playedAt: Date(timeIntervalSince1970: 100), duration: .thirtySeconds, difficulty: .normal,
            score: 500, correctCount: 5, answeredCount: 6, maxCombo: 3
        ))
        bestScoreStore.record(score: 500, gameMode: .timeAttack(.thirtySeconds), difficulty: .normal)

        try SettingView.resetRecords(recordStore: recordStore, bestScoreStore: bestScoreStore)

        XCTAssertEqual(recordStore.allRecords(), [])
        XCTAssertNil(bestScoreStore.bestScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .normal))
    }

    /// 1 プレイの記録を消せなかったときは、自己ベストも消さずに失敗を伝える
    func testResetKeepsBestScoresWhenDeletingPlayRecordsFails() {
        bestScoreStore.record(score: 500, gameMode: .timeAttack(.thirtySeconds), difficulty: .normal)

        XCTAssertThrowsError(try SettingView.resetRecords(recordStore: FailingRecordStore(), bestScoreStore: bestScoreStore))

        XCTAssertEqual(bestScoreStore.bestScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .normal), 500)
    }
}

/// 削除に失敗する保存先
private struct FailingRecordStore: TimeAttackRecordStore {
    struct DeleteError: Error {}

    func records(gameMode: GameMode, difficulty: Difficulty) -> [TimeAttackPlayRecord] { [] }
    func allRecords() -> [TimeAttackPlayRecord] { [] }
    func save(_ record: TimeAttackPlayRecord) {}
    func deleteAll() throws {
        throw DeleteError()
    }
}
