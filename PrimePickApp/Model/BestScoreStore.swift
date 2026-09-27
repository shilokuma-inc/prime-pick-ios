//
//  BestScoreStore.swift
//  PrimePickApp
//

import Foundation

/// タイムアタックの自己ベストを保存する
///
/// モード × 難易度ごとに最高スコアを持つ。タイムアタックは制限時間（15 / 30 / 60 秒）ごとに別のモードとして扱う。
/// 練習モードは問題数が可変でスコアを比べられないため保存しない。
struct BestScoreStore {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// 保存済みの自己ベスト。まだ記録が無い、または保存対象外のモードなら nil
    func bestScore(gameMode: GameMode, difficulty: Difficulty) -> Int? {
        guard let key = Self.key(gameMode: gameMode, difficulty: difficulty),
              userDefaults.object(forKey: key) != nil
        else { return nil }
        return userDefaults.integer(forKey: key)
    }

    /// スコアを記録し、自己ベストを更新したかを返す
    ///
    /// 初回は 1 点以上なら更新とみなす（0 点を「NEW RECORD!」として祝わないため）。
    /// 同点は更新としない。
    @discardableResult
    func record(score: Int, gameMode: GameMode, difficulty: Difficulty) -> Bool {
        guard let key = Self.key(gameMode: gameMode, difficulty: difficulty) else { return false }
        let previousBest = bestScore(gameMode: gameMode, difficulty: difficulty) ?? 0
        guard score > previousBest else { return false }
        userDefaults.set(score, forKey: key)
        return true
    }

    /// 保存に使うキー。保存対象外のモードは nil
    static func key(gameMode: GameMode, difficulty: Difficulty) -> String? {
        guard gameMode.isTimeAttack else { return nil }
        return "bestScore.\(gameMode.id).\(difficulty.rawValue)"
    }
}
