//
//  QuizReviewList.swift
//  PrimePickApp
//

import SwiftUI

/// 間違えた問題の復習一覧。素因数分解を添えて並べる
///
/// 練習・タイムアタックの結果（`QuizResultView`）とデイリーの結果（`DailyChallengeResultView`）で共通に使う。
struct QuizReviewList: View {
    /// 解答した問題の記録。このうち間違えた問題だけを並べる
    let answerRecords: [QuizAnswerRecord]
    /// 最後まで解いたか。途中でやめたデイリーでは、誤答が無くても「全問正解」とは出さない
    var isComplete: Bool = true

    /// 復習一覧に出すのは間違えた問題だけ
    private var missedRecords: [QuizAnswerRecord] {
        answerRecords.filter { !$0.isAnswerCorrect }
    }

    /// 問題数が増えても収まるようにスクロールさせるか。
    /// 外側でスクロールする場所（結果画面のカードの中）に置くときは false にして、入れ子のスクロールを避ける
    var scrolls: Bool = true

    var body: some View {
        if missedRecords.isEmpty {
            Text(isComplete ? "Perfect! All questions correct!" : "No missed questions so far")
                .appFont(.heading(.headline, weight: .semibold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .padding(.vertical, 8)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Missed Questions")
                    .appFont(.heading(.headline, weight: .semibold))

                if scrolls {
                    // 問題数が増えても収まるようにスクロールさせる
                    ScrollView {
                        reviewRows
                    }
                } else {
                    reviewRows
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 間違えた問題の行
    private var reviewRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(missedRecords) { record in
                reviewRow(record)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reviewRow(_ record: QuizAnswerRecord) -> some View {
        HStack(spacing: 8) {
            Text(verbatim: "❌")

            NumberExplanation(number: record.number).text
                .font(.body)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer(minLength: 0)
        }
    }
}
