//
//  AnswerFeedbackEffect.swift
//  PrimePickApp
//

import SwiftUI

/// 正誤に応じた演出（正解: スケール + グロー / 不正解: シェイク）を View に付与する
///
/// 演出は付与先の View の見た目だけを変化させるもので、クイズの進行とは独立している。
/// 連打された場合は最新の `trigger` の演出だけが残るよう、後片付けの処理を ID で判定している。
struct AnswerFeedbackEffect: ViewModifier {
    let trigger: AnswerFeedbackTrigger?

    @State private var scale: CGFloat = 1
    @State private var glowOpacity: Double = 0
    @State private var shakeOffset: CGFloat = 0
    @State private var latestTriggerID: Int = 0

    private let correctDuration: TimeInterval = 0.18
    private let shakeUnitDuration: TimeInterval = 0.05
    private let shakeRepeatCount = 6

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .offset(x: shakeOffset)
            .shadow(color: Color.quizCorrectButton.opacity(glowOpacity), radius: 24)
            .onChange(of: trigger) { _, newTrigger in
                guard let newTrigger else { return }
                latestTriggerID = newTrigger.id

                switch newTrigger.result {
                case .correct:
                    playCorrectEffect(id: newTrigger.id)
                case .incorrect:
                    playIncorrectEffect(id: newTrigger.id)
                }
            }
    }

    private func playCorrectEffect(id: Int) {
        resetShakeOffset()
        withAnimation(.spring(response: correctDuration, dampingFraction: 0.45)) {
            scale = 1.12
            glowOpacity = 0.9
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + correctDuration) {
            // 連打で新しい演出が始まっていた場合は、そちらを打ち消さないよう後片付けしない
            guard latestTriggerID == id else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                scale = 1
                glowOpacity = 0
            }
        }
    }

    private func playIncorrectEffect(id: Int) {
        withAnimation(.easeOut(duration: 0.15)) {
            scale = 1
            glowOpacity = 0
        }

        resetShakeOffset()
        shakeOffset = -10
        withAnimation(.linear(duration: shakeUnitDuration).repeatCount(shakeRepeatCount, autoreverses: true)) {
            shakeOffset = 10
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + shakeUnitDuration * Double(shakeRepeatCount)) {
            guard latestTriggerID == id else { return }
            resetShakeOffset()
        }
    }

    /// 繰り返しアニメーションの途中でも位置が残らないよう、アニメーション無しで元に戻す
    private func resetShakeOffset() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            shakeOffset = 0
        }
    }
}

extension View {
    func answerFeedbackEffect(trigger: AnswerFeedbackTrigger?) -> some View {
        modifier(AnswerFeedbackEffect(trigger: trigger))
    }
}
