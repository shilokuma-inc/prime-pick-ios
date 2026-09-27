//
//  ScorePopupView.swift
//  PrimePickApp
//

import SwiftUI

/// 解答直後に一瞬だけ出す、スコアや残り時間の増減
///
/// 続けて解答したとき、前のポップアップを消すタイマーが新しいものを消さないよう、解答ごとに異なる `id` を持たせる。
struct ScorePopup: Identifiable, Equatable {
    enum Kind: Equatable {
        /// 獲得点。速度ボーナスが付いたときは `isFast` が true
        case gain(points: Int, isFast: Bool)
        /// 誤答で実際に減った点（正の値）
        case penalty(points: Int)
        /// 誤答で実際に減った残り時間（秒、正の値）
        case timePenalty(seconds: Int)
    }

    /// 表示しておく秒数
    static let displayDuration: TimeInterval = 0.9

    let id: Int
    let kind: Kind

    /// 1 問分の増減からスコアのポップアップを作る。増減が無い（スコア 0 での誤答など）ときは nil
    static func score(id: Int, submission: ScoreBreakdown) -> ScorePopup? {
        if submission.penalty > 0 {
            return ScorePopup(id: id, kind: .penalty(points: submission.penalty))
        }
        guard submission.total > 0 else { return nil }
        return ScorePopup(id: id, kind: .gain(points: submission.total, isFast: submission.speedBonus > 0))
    }

    /// 減らした秒数から時間ペナルティのポップアップを作る。減っていなければ nil
    static func time(id: Int, deductedSeconds: Int) -> ScorePopup? {
        guard deductedSeconds > 0 else { return nil }
        return ScorePopup(id: id, kind: .timePenalty(seconds: deductedSeconds))
    }

    /// 表示する数字。マイナスは数字の幅に揃うよう、ハイフンではなく U+2212 を使う
    var text: String {
        switch kind {
        case .gain(let points, _):
            return "+\(points)"
        case .penalty(let points):
            return "\u{2212}\(points)"
        case .timePenalty(let seconds):
            return "\u{2212}\(seconds)s"
        }
    }

    /// 速度ボーナスが付いたか
    var isFast: Bool {
        if case .gain(_, let isFast) = kind { return isFast }
        return false
    }

    /// 減る方向の表示か。赤で出す
    var isNegative: Bool {
        switch kind {
        case .gain:
            return false
        case .penalty, .timePenalty:
            return true
        }
    }
}

/// `ScorePopup` を浮かび上がらせながら消す
///
/// 「視差効果を減らす」が有効なときは動かさず、その場でフェードアウトだけする。
/// 読み上げは段階到達とリザルトだけに絞る方針のため、VoiceOver からは隠す。
struct ScorePopupView: View {
    let popup: ScorePopup
    var fontSize: CGFloat = 28

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false
    @State private var isFading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if popup.isFast {
                // ゲーム用語として言語によらず同じ表記にする
                Text(verbatim: "FAST!")
                    .font(.custom("ArialRoundedMTBold", size: fontSize * 0.55))
                    .foregroundStyle(Color.orange)
            }

            Text(verbatim: popup.text)
                .font(.custom("ArialRoundedMTBold", size: fontSize))
                .foregroundStyle(popup.isNegative ? Color.red : Color.orange)
        }
        .lineLimit(1)
        .fixedSize()
        .offset(y: isFloating && !reduceMotion ? -fontSize * 0.8 : 0)
        .opacity(isFading ? 0 : 1)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: ScorePopup.displayDuration)) {
                isFloating = true
            }
            // 前半ははっきり見せ、後半で消す
            withAnimation(.easeIn(duration: ScorePopup.displayDuration / 2).delay(ScorePopup.displayDuration / 2)) {
                isFading = true
            }
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        ScorePopupView(popup: ScorePopup(id: 1, kind: .gain(points: 245, isFast: true)))
        ScorePopupView(popup: ScorePopup(id: 2, kind: .penalty(points: 300)))
        ScorePopupView(popup: ScorePopup(id: 3, kind: .timePenalty(seconds: 2)))
    }
}
