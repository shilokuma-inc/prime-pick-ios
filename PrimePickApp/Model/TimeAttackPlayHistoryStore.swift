//
//  TimeAttackPlayHistoryStore.swift
//  PrimePickApp
//

import Foundation

/// タイムアタックの 1 プレイごとの履歴の保存先（#549）
///
/// 制限時間 × 難易度の枠ごとに、直近 `maxEntryCount` 回のスコアを、遊んだ日時つきで古い順に持つ。
/// 結果画面の「前回との差」と、記録画面の推移グラフ（#550）に使う。
/// 上位 10 件（`TimeAttackRecordStore`）とは別に持ち、上位に入らないプレイや 0 点のプレイも残す。
/// 1.5.0 で保存を始めたので、それより前のプレイは無い。
struct TimeAttackPlayHistoryStore {
    /// 枠ごとに残す回数。推移グラフに出す回数（#550）より多めに残す
    static let maxEntryCount = 50

    /// 1 プレイ分の履歴
    ///
    /// 項目を足すときは Optional にする。古いバージョンが保存した履歴もそのまま読めるようにするため。
    struct Entry: Codable, Equatable {
        let score: Int
        /// 遊び終えた日時
        let playedAt: Date
    }

    private let userDefaults: UserDefaults
    private let now: () -> Date

    init(userDefaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.userDefaults = userDefaults
        self.now = now
    }

    /// 枠の履歴（古い順）。保存対象外のモードや、読めない（壊れている）ときは空
    func entries(gameMode: GameMode, difficulty: Difficulty) -> [Entry] {
        guard let key = Self.key(gameMode: gameMode, difficulty: difficulty),
              let data = userDefaults.data(forKey: key),
              let entries = try? Self.decoder.decode([Entry].self, from: data)
        else {
            return []
        }
        return entries
    }

    /// 同じ枠の、いちばん新しいプレイのスコア。まだ遊んでいなければ nil
    func lastScore(gameMode: GameMode, difficulty: Difficulty) -> Int? {
        entries(gameMode: gameMode, difficulty: difficulty).last?.score
    }

    /// スコアを現在時刻で残す。古いものから消し、`maxEntryCount` 回を超えないようにする
    func record(score: Int, gameMode: GameMode, difficulty: Difficulty) {
        guard let key = Self.key(gameMode: gameMode, difficulty: difficulty) else { return }
        var entries = entries(gameMode: gameMode, difficulty: difficulty)
        entries.append(Entry(score: score, playedAt: now()))
        entries = Array(entries.suffix(Self.maxEntryCount))
        if let data = try? Self.encoder.encode(entries) {
            userDefaults.set(data, forKey: key)
        }
    }

    /// 保存に使うキー。タイムアタック以外は nil
    ///
    /// 上位 10 件（`timeAttackRecords.v1.*`）とは別のキーにする。形式を変えるときは版を上げる。
    static func key(gameMode: GameMode, difficulty: Difficulty) -> String? {
        guard gameMode.isTimeAttack else { return nil }
        return "timeAttackHistory.v1.\(gameMode.id).\(difficulty.rawValue)"
    }

    /// 日時は上位 10 件（QuizKit の `LocalLeaderboard`）とそろえて UNIX 時間（秒）で保存する
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
