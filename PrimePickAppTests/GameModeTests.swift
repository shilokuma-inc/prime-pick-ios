//
//  GameModeTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class GameModeTests: XCTestCase {

    // MARK: - 制限時間

    func testPracticeHasNoTimeLimit() {
        XCTAssertNil(GameMode.practice.timeLimitSeconds)
        XCTAssertFalse(GameMode.practice.isTimeAttack)
    }

    func testTimeAttackReturnsSelectedDuration() {
        XCTAssertEqual(GameMode.timeAttack(.fifteenSeconds).timeLimitSeconds, 15)
        XCTAssertEqual(GameMode.timeAttack(.thirtySeconds).timeLimitSeconds, 30)
        XCTAssertEqual(GameMode.timeAttack(.sixtySeconds).timeLimitSeconds, 60)
    }

    func testTimeAttackIsTimeAttackForEveryDuration() {
        for duration in TimeAttackDuration.allCases {
            XCTAssertTrue(GameMode.timeAttack(duration).isTimeAttack)
        }
    }

    // MARK: - モード選択の並び

    func testAllCasesIsPracticeFollowedByDurationsInAscendingOrder() {
        XCTAssertEqual(
            GameMode.allCases,
            [
                .practice,
                .timeAttack(.fifteenSeconds),
                .timeAttack(.thirtySeconds),
                .timeAttack(.sixtySeconds)
            ]
        )
    }

    func testIdIsUniqueForEveryCase() {
        let ids = GameMode.allCases.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }
}
