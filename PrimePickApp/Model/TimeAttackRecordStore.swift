//
//  TimeAttackRecordStore.swift
//  PrimePickApp
//

import Foundation

/// タイムアタック 1 プレイ分の記録（Discussion #270 Q1）
///
/// 将来項目を足すときは Optional にする。`Codable` の自動生成は、JSON に無い Optional の項目を nil として読むため、
/// 古いバージョンが保存した記録もそのまま読める。
struct ScoreRecord: Codable, Equatable {
    let score: Int
    /// 達成日時。表示は日付だけにするが、保存は `Date` のまま持つ
    let achievedAt: Date
}

/// タイムアタックの記録の保存先
///
/// 制限時間 × 難易度の枠（15 / 30 / 60 秒 × 4 難易度 = 12 枠）ごとに、スコアの上位 `maxRecordCount` 件を達成日時つきで持つ。
/// 自己ベストはその 1 位。練習・デイリーはスコアを比べないため保存しない。
struct TimeAttackRecordStore {
    /// 枠ごとに残す件数
    static let maxRecordCount = 10

    private let userDefaults: UserDefaults
    private let now: () -> Date

    init(userDefaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.userDefaults = userDefaults
        self.now = now
    }

    /// 枠の記録（スコアの高い順。同点は先に出した記録が上）。保存対象外のモードは空
    func records(gameMode: GameMode, difficulty: Difficulty) -> [ScoreRecord] {
        guard let key = Self.key(gameMode: gameMode, difficulty: difficulty) else { return [] }
        return loadRecords(forKey: key)
    }

    /// 自己ベスト（1 位のスコア）。まだ記録が無い、または保存対象外のモードなら nil
    func bestScore(gameMode: GameMode, difficulty: Difficulty) -> Int? {
        records(gameMode: gameMode, difficulty: difficulty).first?.score
    }

    /// スコアを現在時刻で記録し、自己ベストを更新したかを返す
    ///
    /// 0 点は記録しない（0 点を「NEW RECORD!」として祝わないため。初回は 1 点以上なら更新になる）。
    /// 同点は自己ベストの更新としない。上位 `maxRecordCount` 件に入らないスコアは残らない。
    @discardableResult
    func record(score: Int, gameMode: GameMode, difficulty: Difficulty) -> Bool {
        guard score > 0, let key = Self.key(gameMode: gameMode, difficulty: difficulty) else { return false }
        // 読み込みから書き込みまでを 1 つの操作にし、同じ枠への保存が重なっても先の記録を消さない
        Self.saveLock.lock()
        defer { Self.saveLock.unlock() }
        var records = loadRecords(forKey: key)
        let previousBest = records.first?.score ?? 0
        // 同点の記録の後ろに入れる（先に出した記録を上にする）
        let index = records.firstIndex { $0.score < score } ?? records.endIndex
        records.insert(ScoreRecord(score: score, achievedAt: now()), at: index)
        records = Array(records.prefix(Self.maxRecordCount))
        if let data = try? Self.encoder.encode(records) {
            userDefaults.set(data, forKey: key)
        }
        return score > previousBest
    }

    /// 保存に使うキー。保存対象外のモードは nil
    ///
    /// 日付の無い旧形式（`bestScore.<GameMode.id>.<Difficulty.rawValue>`）とは別のキーにする。形式を変えるときは版を上げる。
    static func key(gameMode: GameMode, difficulty: Difficulty) -> String? {
        guard gameMode.isTimeAttack else { return nil }
        return "timeAttackRecords.v1.\(gameMode.id).\(difficulty.rawValue)"
    }

    /// 保存済みの記録。読めない（壊れている）ときは空として扱い、プレイを止めない
    private func loadRecords(forKey key: String) -> [ScoreRecord] {
        guard let data = userDefaults.data(forKey: key),
              let records = try? Self.decoder.decode([ScoreRecord].self, from: data)
        else { return [] }
        return records
    }

    private static let saveLock = NSLock()

    /// 日時は UNIX 時間（秒）で保存する（`UserDefaultsDailyChallengeStore` と揃える）
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
