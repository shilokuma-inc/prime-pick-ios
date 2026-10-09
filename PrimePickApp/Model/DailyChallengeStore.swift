//
//  DailyChallengeStore.swift
//  PrimePickApp
//

import Foundation

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
/// 記録は `dayKey` をキーにした辞書を 1 つの JSON として 1 キーに保存する（1 日 1 件・1 件数百バイトなので、数年分でも小さい）。
struct UserDefaultsDailyChallengeStore: DailyChallengeStore {
    /// 保存に使うキー。形式を変えるときは別のキーにして、古いキーから移す
    static let recordsKey = "dailyChallenge.records.v1"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func record(dayKey: String) -> DailyChallengeRecord? {
        loadRecords()[dayKey]
    }

    func allRecords() -> [DailyChallengeRecord] {
        loadRecords().values.sorted { $0.dayKey < $1.dayKey }
    }

    func save(_ record: DailyChallengeRecord) {
        // 全件を読んで 1 件差し替えて書き戻すため、別の日の保存と重なると先の保存を消してしまう。
        // 読み込みから書き込みまでを、すべてのインスタンスで共有するロックで 1 つの操作にする
        Self.saveLock.lock()
        defer { Self.saveLock.unlock() }
        var records = loadRecords()
        records[record.dayKey] = record
        guard let data = try? Self.encoder.encode(records) else { return }
        userDefaults.set(data, forKey: Self.recordsKey)
    }

    /// 保存済みの記録。読めない（壊れている）ときは空として扱い、起動やプレイを止めない
    private func loadRecords() -> [String: DailyChallengeRecord] {
        guard let data = userDefaults.data(forKey: Self.recordsKey),
              let records = try? Self.decoder.decode([String: DailyChallengeRecord].self, from: data)
        else { return [:] }
        return records
    }

    private static let saveLock = NSLock()

    /// 日時は UNIX 時間（秒）で保存する。`JSONEncoder` の既定（2001 年起点）より他の仕組みから読みやすい
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
}
