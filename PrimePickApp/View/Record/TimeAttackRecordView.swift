//
//  TimeAttackRecordView.swift
//  PrimePickApp
//

import SwiftUI

/// タイムアタックの記録画面（Discussion #223 Q4）
///
/// 制限時間と難易度を切り替えて、その区分の TOP 10 を出す。記録は端末の中だけにある。
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

    private func reload() {
        summary = TimeAttackRecordSummary(records: recordStore.records(gameMode: gameMode, difficulty: difficulty))
        bestScore = bestScoreStore.bestScore(gameMode: gameMode, difficulty: difficulty)
    }
}

/// TOP 10 の 1 行。順位・スコア・日時と、正解数・最大コンボを出す
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

            VStack(alignment: .leading, spacing: 2) {
                Text("\(record.score) pts")
                    .font(.headline)
                    .monospacedDigit()

                Text("Correct \(record.correctCount) / Answered \(record.answeredCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(record.playedAt, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Max Combo \(record.maxCombo)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    TimeAttackRecordView()
}
