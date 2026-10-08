//
//  TimeAttackRecordView.swift
//  PrimePickApp
//

import Charts
import SwiftUI

/// タイムアタックの記録画面（Discussion #223 Q4）
///
/// 制限時間と難易度を切り替えて、その区分のスコアの推移と TOP 10 を出す。記録は端末の中だけにある。
/// 履歴を始める前のプレイは TOP 10 に出てこないため、`BestScoreStore` の自己ベストを上部に別に出す。
struct TimeAttackRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timeAttackRecordStore) private var recordStore
    @State private var duration: TimeAttackDuration = .thirtySeconds
    @State private var difficulty: Difficulty = .normal
    @State private var summary = TimeAttackRecordSummary(records: [])
    @State private var bestScore: Int?
    var bestScoreStore = BestScoreStore()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    categoryPickers
                }

                Section {
                    bestScoreRow
                }

                Section("Score Trend") {
                    trendChart
                }

                Section("Top \(TimeAttackRecordSummary.topLimit)") {
                    if summary.top.isEmpty {
                        emptyRow
                    } else {
                        ForEach(Array(summary.top.enumerated()), id: \.offset) { index, record in
                            TimeAttackRecordRow(rank: index + 1, record: record)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Records")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear(perform: reload)
            .onChange(of: duration) { reload() }
            .onChange(of: difficulty) { reload() }
        }
    }

    private var gameMode: GameMode {
        .timeAttack(duration)
    }

    private var categoryPickers: some View {
        VStack(spacing: 12) {
            Picker("Time Limit", selection: $duration) {
                ForEach(TimeAttackDuration.allCases) { duration in
                    Text(duration.localizedTitle).tag(duration)
                }
            }
            .pickerStyle(.segmented)

            Picker("Difficulty", selection: $difficulty) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Text(difficulty.localizedTitle).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 4)
    }

    /// 自己ベスト。履歴を始める前のプレイも含む値なので、TOP 10 の 1 位より高いことがある
    private var bestScoreRow: some View {
        LabeledContent("Personal Best") {
            if let bestScore {
                Text("\(bestScore) pts")
                    .monospacedDigit()
            } else {
                Text(verbatim: "—")
            }
        }
        .font(.headline)
    }

    /// 直近のスコアを古い順に結んだ折れ線（Discussion #223 Q4）
    ///
    /// 横軸はプレイの順番（1 回目・2 回目…）。日時にすると、まとめて遊んだ日と間が空いた日で点の間隔がばらつくため。
    /// 線にならない 1 件以下のときはグラフを出さず、案内だけにする。
    @ViewBuilder
    private var trendChart: some View {
        if summary.trend.count < 2 {
            Text("Play this category at least twice to see your score trend.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.vertical, 12)
        } else {
            Chart(Array(summary.trend.enumerated()), id: \.offset) { index, record in
                LineMark(
                    x: .value("Play", index + 1),
                    y: .value("Score", record.score)
                )
                PointMark(
                    x: .value("Play", index + 1),
                    y: .value("Score", record.score)
                )
            }
            .chartXScale(domain: 1...summary.trend.count)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: min(summary.trend.count, 5))) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let play = value.as(Int.self) {
                            Text(verbatim: "\(play)")
                        }
                    }
                }
            }
            .foregroundStyle(Color.orange)
            .frame(height: 180)
            .padding(.vertical, 8)
            .accessibilityLabel(Text("Score trend of the last \(summary.trend.count) plays"))
        }
    }

    private var emptyRow: some View {
        VStack(spacing: 4) {
            Text("No records yet")
                .font(.headline)
            Text("Play Time Attack with this time limit and difficulty to see your records here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    /// 選んでいる区分の記録と自己ベストを読み直す
    private func reload() {
        summary = TimeAttackRecordSummary(records: recordStore.records(gameMode: gameMode, difficulty: difficulty))
        bestScore = bestScoreStore.bestScore(gameMode: gameMode, difficulty: difficulty)
    }
}

/// TOP 10 の 1 行。順位・スコア・日時と、正解数・最大コンボを出す
///
/// 横に収まらない（画面が狭い・文字が大きい）ときは、詳細を縦に並べて省略させない。
private struct TimeAttackRecordRow: View {
    let rank: Int
    let record: TimeAttackPlayRecord

    var body: some View {
        HStack(spacing: 12) {
            Text(verbatim: "\(rank)")
                .font(.title3.bold())
                .monospacedDigit()
                .frame(minWidth: 28)
                .foregroundStyle(rank == 1 ? Color.orange : Color.primary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        scoreText
                        correctText
                    }
                    .fixedSize()

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: 2) {
                        playedAtText
                        maxComboText
                    }
                    .fixedSize()
                }

                VStack(alignment: .leading, spacing: 2) {
                    scoreText
                    correctText
                    maxComboText
                    playedAtText
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var scoreText: some View {
        Text("\(record.score) pts")
            .font(.headline)
            .monospacedDigit()
    }

    private var correctText: some View {
        Text("Correct \(record.correctCount) / Answered \(record.answeredCount)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var playedAtText: some View {
        Text(record.playedAt, format: .dateTime.year().month().day().hour().minute())
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var maxComboText: some View {
        Text("Max Combo \(record.maxCombo)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    TimeAttackRecordView()
}
