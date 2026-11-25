//
//  TimeAttackRecordsViewTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class TimeAttackRecordsViewTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var store: TimeAttackRecordStore!
    private var history: TimeAttackPlayHistoryStore!

    override func setUp() {
        super.setUp()
        // 実機の記録を壊さないよう、テストごとに使い捨ての領域を使う
        suiteName = "TimeAttackRecordsViewTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        store = TimeAttackRecordStore(userDefaults: userDefaults, now: { Date(timeIntervalSince1970: 1_790_000_000) })
        history = TimeAttackPlayHistoryStore(userDefaults: userDefaults, now: { Date(timeIntervalSince1970: 1_790_000_000) })
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    /// 記録が無くても 15 / 30 / 60 秒の 3 枠を並べる（記録の無い枠は「—」で示す）
    func testSectionsListAllDurationsEvenWithoutRecords() {
        let sections = TimeAttackRecordsView.sections(store: store, history: history, difficulty: .easy)

        XCTAssertEqual(sections.map(\.duration), [.fifteenSeconds, .thirtySeconds, .sixtySeconds])
        XCTAssertTrue(sections.allSatisfy { $0.records.isEmpty })
    }

    /// 選んだ難易度の記録だけを、制限時間ごとにスコアの高い順で並べる
    func testSectionsShowRecordsOfSelectedDifficulty() {
        store.record(score: 500, gameMode: .timeAttack(.thirtySeconds), difficulty: .hard)
        store.record(score: 900, gameMode: .timeAttack(.thirtySeconds), difficulty: .hard)
        store.record(score: 1_200, gameMode: .timeAttack(.sixtySeconds), difficulty: .easy)

        let hard = TimeAttackRecordsView.sections(store: store, history: history, difficulty: .hard)
        XCTAssertEqual(hard[0].records, [])
        XCTAssertEqual(hard[1].records.map(\.score), [900, 500])
        XCTAssertEqual(hard[2].records, [])

        let easy = TimeAttackRecordsView.sections(store: store, history: history, difficulty: .easy)
        XCTAssertEqual(easy[2].records.map(\.score), [1_200])
    }

    // MARK: - スコアの推移（#550）

    /// 推移には選んだ難易度・制限時間の直近 20 回を、古い順に出す
    func testTrendShowsLatestPlaysOfEachSection() {
        for score in 1...25 {
            history.record(score: score * 10, gameMode: .timeAttack(.thirtySeconds), difficulty: .normal)
        }
        history.record(score: 999, gameMode: .timeAttack(.thirtySeconds), difficulty: .easy)

        let normal = TimeAttackRecordsView.sections(store: store, history: history, difficulty: .normal)

        XCTAssertEqual(normal[1].trendScores, Array(6...25).map { $0 * 10 })
        XCTAssertEqual(normal[1].trendScores.count, TimeAttackRecordsView.trendPlayCount)
        XCTAssertEqual(normal[0].trendScores, [])
    }

    /// 2 回以上遊んだ枠だけ折れ線を出す
    func testTrendNeedsAtLeastTwoPlays() {
        let mode = GameMode.timeAttack(.fifteenSeconds)
        history.record(score: 300, gameMode: mode, difficulty: .easy)
        XCTAssertFalse(TimeAttackRecordsView.sections(store: store, history: history, difficulty: .easy)[0].showsTrend)

        history.record(score: 200, gameMode: mode, difficulty: .easy)
        XCTAssertTrue(TimeAttackRecordsView.sections(store: store, history: history, difficulty: .easy)[0].showsTrend)
    }

    /// 折れ線が出ない枠のうち、遊んだことのある枠（1.5.0 より前の記録だけの枠も含む）には案内を出す。一度も遊んでいない枠は「—」だけ
    func testTrendHintOnlyForSectionsAlreadyPlayed() {
        store.record(score: 1_000, gameMode: .timeAttack(.sixtySeconds), difficulty: .hard)  // 1.5.0 より前の記録（履歴なし）
        history.record(score: 400, gameMode: .timeAttack(.thirtySeconds), difficulty: .hard)  // 1 回だけ遊んだ

        let hard = TimeAttackRecordsView.sections(store: store, history: history, difficulty: .hard)

        XCTAssertFalse(hard[0].showsTrendHint, "一度も遊んでいない")
        XCTAssertTrue(hard[1].showsTrendHint)
        XCTAssertTrue(hard[2].showsTrendHint)
    }

    /// 折れ線の点は古い順に 1 から数え、いちばん新しいプレイだけを大きくする
    func testTrendPointsMarkOnlyTheLatestPlay() {
        let points = ScoreTrendChart.points(of: [120, 80, 150])

        XCTAssertEqual(points.map(\.play), [1, 2, 3])
        XCTAssertEqual(points.map(\.isLatest), [false, false, true])
    }
}
