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

    /// スコアを記録し、自己ベストを更新したかと更新前の自己ベストを返す
    ///
    /// 初回は 1 点以上なら更新とみなす（0 点を「NEW RECORD!」として祝わないため）。
    /// 同点は更新としない。
    @discardableResult
    func record(score: Int, gameMode: GameMode, difficulty: Difficulty) -> BestScoreUpdate {
        guard let key = Self.key(gameMode: gameMode, difficulty: difficulty) else {
            return BestScoreUpdate(score: score, previousBest: nil, isNewRecord: false)
        }
        let previousBest = bestScore(gameMode: gameMode, difficulty: difficulty)
        guard score > previousBest ?? 0 else {
            return BestScoreUpdate(score: score, previousBest: previousBest, isNewRecord: false)
        }
        userDefaults.set(score, forKey: key)
        return BestScoreUpdate(score: score, previousBest: previousBest, isNewRecord: true)
    }

    /// すべての区分の自己ベストを消す
    ///
    /// 設定画面の「記録をリセット」で、1 プレイの記録と一緒に消す（Discussion #223）。
    /// 片方だけ残ると、リザルトの「ベストまであと N 点」と記録画面が食い違うため。キーの形式は変えない。
    func deleteAll() {
        for duration in TimeAttackDuration.allCases {
            for difficulty in Difficulty.allCases {
                guard let key = Self.key(gameMode: .timeAttack(duration), difficulty: difficulty) else { continue }
                userDefaults.removeObject(forKey: key)
            }
        }
    }

    /// 保存に使うキー。保存対象外のモードは nil
    static func key(gameMode: GameMode, difficulty: Difficulty) -> String? {
        guard gameMode.isTimeAttack else { return nil }
        return "bestScore.\(gameMode.id).\(difficulty.rawValue)"
    }
}

/// 1 プレイのスコアを自己ベストに記録した結果
struct BestScoreUpdate: Equatable {
    let score: Int
    /// 記録する前の自己ベスト。まだ記録が無かった、または保存対象外のモードなら nil
    let previousBest: Int?
    /// 自己ベストを更新したか（結果画面に NEW RECORD! を出すか）
    let isNewRecord: Bool

    /// 更新前の自己ベストとの比べ（Discussion #223 / 本文 A）。比べる自己ベストが無ければ nil
    ///
    /// 初回は NEW RECORD!（1 点以上のとき）だけを出し、差は出さない。
    var comparison: BestScoreComparison? {
        guard let previousBest else { return nil }
        if score > previousBest {
            return .updated(by: score - previousBest)
        } else if score == previousBest {
            return .tied
        } else {
            return .below(by: previousBest - score)
        }
    }
}

/// 自己ベストとの比べ。結果画面に「ベストまであと N 点」「ベストを N 点更新」として出す
enum BestScoreComparison: Equatable {
    /// 自己ベストを `by` 点上回った
    case updated(by: Int)
    /// 自己ベストと同点（更新にはしない）
    case tied
    /// 自己ベストに `by` 点届かなかった
    case below(by: Int)
}
