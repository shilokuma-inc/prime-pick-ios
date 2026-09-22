//
//  GameMode.swift
//  PrimePickApp
//

import SwiftUI

/// クイズの進行ルール
enum GameMode: Hashable, Identifiable, CaseIterable {
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
