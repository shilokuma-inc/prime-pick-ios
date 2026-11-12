//
//  TimeAttackRecordStore.swift
//  PrimePickApp
//

import Foundation
import QuizCore

/// タイムアタックの記録の保存先
///
/// 制限時間 × 難易度の枠（15 / 30 / 60 秒 × 4 難易度 = 12 枠）ごとに、スコアの上位 `maxRecordCount` 件を達成日時つきで持つ。
/// 自己ベストはその 1 位。練習・デイリーはスコアを比べないため保存しない。
/// 保存と並べ替えは QuizKit の `LocalLeaderboard`（Discussion #270 Q1 の形式のまま）に任せ、ここでは枠のキーだけを決める。
struct TimeAttackRecordStore {
    /// 枠ごとに残す件数
    static let maxRecordCount = 10

    private let userDefaults: UserDefaults
    private let leaderboard: LocalLeaderboard

    init(userDefaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.userDefaults = userDefaults
        leaderboard = LocalLeaderboard(maxRecordCount: Self.maxRecordCount, userDefaults: userDefaults, now: now)
    }

    /// 枠の記録（スコアの高い順。同点は先に出した記録が上）。保存対象外のモードは空
    func records(gameMode: GameMode, difficulty: Difficulty) -> [ScoreRecord] {
        guard let key = Self.key(gameMode: gameMode, difficulty: difficulty) else { return [] }
        return leaderboard.records(forKey: key)
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
        guard let key = Self.key(gameMode: gameMode, difficulty: difficulty) else { return false }
        return leaderboard.record(score: score, forKey: key)
    }

    /// 日付の無い旧形式の自己ベスト（`bestScore.<GameMode.id>.<Difficulty.rawValue>`）を 12 枠すべて消す（Discussion #270 Q2）
    ///
    /// 旧形式は達成日時を持たないため移行せずに捨て、記録は取り直す。起動のたびに呼び、無いキーを消しても何も起きない。
    func removeLegacyBestScores() {
        for key in Self.legacyBestScoreKeys {
            userDefaults.removeObject(forKey: key)
        }
    }

    /// 日付の無い旧形式の自己ベストのキー（制限時間 × 難易度の 12 枠）
    static var legacyBestScoreKeys: [String] {
        TimeAttackDuration.allCases.flatMap { duration in
            Difficulty.allCases.map { difficulty in
                "bestScore.\(GameMode.timeAttack(duration).id).\(difficulty.rawValue)"
            }
        }
    }

    /// 保存に使うキー。保存対象外のモードは nil
    ///
    /// 日付の無い旧形式（`bestScore.<GameMode.id>.<Difficulty.rawValue>`）とは別のキーにする。形式を変えるときは版を上げる。
    static func key(gameMode: GameMode, difficulty: Difficulty) -> String? {
        guard gameMode.isTimeAttack else { return nil }
        return "timeAttackRecords.v1.\(gameMode.id).\(difficulty.rawValue)"
    }
}
