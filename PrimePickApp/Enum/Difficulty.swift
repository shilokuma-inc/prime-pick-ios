//
//  Difficulty.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/25.
//

import SwiftUI

enum Difficulty: String {
    case easy = "Easy"
    case normal = "Normal"
    case hard = "Hard"

    /// 画面に表示する難易度名
    var localizedTitle: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }
}
