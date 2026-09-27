//
//  GameMode.swift
//  PrimePickApp
//

import SwiftUI

/// クイズの進行ルール
enum GameMode: Hashable, Identifiable, CaseIterable {
    /// タイムアタックの誤答で減らす残り時間（秒）。制限時間の長さによらず固定
    static let timeAttackMissTimePenaltySeconds = 2

    /// タイムアタックの誤答後に入力を受け付けない時間（秒）
    static let timeAttackMissInputLockDuration: TimeInterval = 0.5

    /// 10 問固定・時間無制限
    case practice
    /// 制限時間内に何問正解できるかを競うモード
    case timeAttack(TimeAttackDuration)

    /// モード選択に並べる選択肢。タイムアタックは制限時間ごとに 1 つ並ぶ
    static var allCases: [GameMode] {
        [.practice] + TimeAttackDuration.allCases.map(GameMode.timeAttack)
    }

    var id: String {
        switch self {
        case .practice:
            return "practice"
        case .timeAttack(let duration):
            return "timeAttack_\(duration.seconds)"
        }
    }

    /// タイムアタックかどうか
    var isTimeAttack: Bool {
        switch self {
        case .practice:
            return false
        case .timeAttack:
            return true
        }
    }

    /// 解答直後にミニ解説を表示するか
    ///
    /// タイムアタックではテンポを崩さないよう表示せず、練習モードだけで表示する（Discussion #138 / PR #152 で確認済み）。
    var showsAnswerExplanation: Bool {
        !isTimeAttack
    }

    /// スコアの計算ルール。誤答の減点と速度ボーナスの条件はタイムアタックだけに適用する
    var scoringRule: ScoringRule {
        isTimeAttack ? .timeAttack : .practice
    }

    /// 誤答で減らす残り時間（秒）。練習モードは制限時間が無いので 0
    var missTimePenaltySeconds: Int {
        isTimeAttack ? Self.timeAttackMissTimePenaltySeconds : 0
    }

    /// 誤答後に入力を受け付けない時間（秒）。練習モードはロックしないので 0
    var missInputLockDuration: TimeInterval {
        isTimeAttack ? Self.timeAttackMissInputLockDuration : 0
    }

    /// 誤答のペナルティを反映した残り時間。0 以下になる場合は 0（即タイムアップ）を返す
    func remainingSecondsAfterMiss(from remainingSeconds: Int) -> Int {
        max(0, remainingSeconds - missTimePenaltySeconds)
    }

    /// 画面に表示するモード名
    var localizedTitle: LocalizedStringKey {
        switch self {
        case .practice:
            return "Practice"
        case .timeAttack(let duration):
            return duration.localizedTitle
        }
    }

    /// 制限時間（秒）。練習モードは制限なしのため nil を返す
    var timeLimitSeconds: Int? {
        switch self {
        case .practice:
            return nil
        case .timeAttack(let duration):
            return duration.seconds
        }
    }
}

/// タイムアタックの制限時間
enum TimeAttackDuration: Int, CaseIterable, Identifiable {
    case fifteenSeconds = 15
    case thirtySeconds = 30
    case sixtySeconds = 60

    var id: Int { rawValue }

    /// 制限時間（秒）
    var seconds: Int { rawValue }

    /// 画面に表示する制限時間名
    var localizedTitle: LocalizedStringKey {
        "\(seconds) seconds"
    }
}
