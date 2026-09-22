//
//  HapticFeedback.swift
//  PrimePickApp
//

import UIKit

/// 触覚フィードバックの薄いラッパー
///
/// SwiftUI の `sensoryFeedback` は iOS 17 以降の API で、本アプリの Deployment Target (iOS 16.0)
/// では利用できない。そのため全バージョンで動作する UIKit の FeedbackGenerator をここで包み、
/// View 側からは `HapticFeedback.Pattern` だけを意識すればよい形にしている。
@MainActor
final class HapticFeedback {
    static let shared = HapticFeedback()

    /// 呼び出し側が UIKit の型を直接扱わずに済むようにするためのパターン定義
    enum Pattern {
        /// 正解など、肯定的な結果を伝える
        case success
        /// 不正解など、否定的な結果を伝える
        case error
        /// 結果を伴わない単純な打鍵感
        case impact
    }

    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)

    private init() {}

    /// まもなく再生される可能性があることをシステムに伝え、初回の再生遅延を減らす
    func prepare() {
        notificationGenerator.prepare()
        impactGenerator.prepare()
    }

    func play(_ pattern: Pattern) {
        switch pattern {
        case .success:
            notificationGenerator.notificationOccurred(.success)
        case .error:
            notificationGenerator.notificationOccurred(.error)
        case .impact:
            impactGenerator.impactOccurred()
        }
        // 連打されても次の再生が遅れないよう、再生のたびに準備し直す
        prepare()
    }
}
