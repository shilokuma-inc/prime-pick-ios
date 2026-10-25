//
//  DailyChallengeStore.swift
//  PrimePickApp
//

import Foundation
import QuizCore

/// デイリーチャレンジの記録の保存先
///
/// 画面やプレイの終わりの処理はこの protocol を通して記録に触る。保存方式（いまは UserDefaults）を差し替えても呼び出し側は変わらない。
protocol DailyChallengeStore {
    /// その日の記録。まだ始めていなければ nil
    func record(dayKey: String) -> DailyChallengeRecord?
    /// すべての記録（`dayKey` の昇順）。ストリークの計算に使う
    func allRecords() -> [DailyChallengeRecord]
    /// 記録を保存する。同じ `dayKey` の記録があれば置き換える
    func save(_ record: DailyChallengeRecord)
}

/// UserDefaults に保存する `DailyChallengeStore`
///
/// タイムアタックの記録（`TimeAttackRecordStore`）と同じく UserDefaults を使い、テストでは使い捨ての領域を注入する。
/// 保存は QuizKit の `DayKeyedRecordStore`（`dayKey` をキーにした辞書を 1 つの JSON として 1 キーに保存する）に任せる。
struct UserDefaultsDailyChallengeStore: DailyChallengeStore {
    /// 保存に使うキー。形式を変えるときは別のキーにして、古いキーから移す
    static let recordsKey = "dailyChallenge.records.v1"

    private let store: DayKeyedRecordStore<DailyChallengeRecord>

    init(userDefaults: UserDefaults = .standard) {
        store = DayKeyedRecordStore(recordsKey: Self.recordsKey, userDefaults: userDefaults)
    }

    func record(dayKey: String) -> DailyChallengeRecord? {
        store.record(dayKey: dayKey)
    }

    func allRecords() -> [DailyChallengeRecord] {
        store.allRecords()
    }

    func save(_ record: DailyChallengeRecord) {
        store.save(record, dayKey: record.dayKey)
    }
}
