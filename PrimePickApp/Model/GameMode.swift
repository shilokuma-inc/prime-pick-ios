//
//  GameMode.swift
//  PrimePickApp
//

import SwiftUI

/// クイズの進行ルール
enum GameMode: String, CaseIterable, Identifiable {
    /// 10 問固定・時間無制限
    case practice = "Practice"
    /// 制限時間内に何問正解できるかを競うモード
    case timeAttack = "Time Attack"

    /// タイムアタックの制限時間（秒）
    static let timeAttackSeconds: Int = 60

    var id: String { rawValue }

    /// 画面に表示するモード名
    var localizedTitle: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }

    /// 制限時間（秒）。練習モードは制限なしのため nil を返す
    var timeLimitSeconds: Int? {
        switch self {
        case .practice:
            return nil
        case .timeAttack:
            return Self.timeAttackSeconds
        }
    }
}
