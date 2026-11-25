//
//  TimeAttackRecordsView.swift
//  PrimePickApp
//

import QuizCore
import SwiftUI

/// タイムアタックの記録画面（Discussion #270）
///
/// 難易度をセグメントで切り替え、制限時間ごとに上位 10 件をスコアと達成日つきで並べる。1 位が自己ベスト。
/// 各制限時間の頭には、直近のプレイのスコアの推移を折れ線で出す（#550）。
/// 記録は開いた時点の値を出す（シートで開き、開いている間にプレイは終わらないため）。
struct TimeAttackRecordsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var difficulty: Difficulty = .easy

    private let store: TimeAttackRecordStore
    private let history: TimeAttackPlayHistoryStore

    init(store: TimeAttackRecordStore = TimeAttackRecordStore(), history: TimeAttackPlayHistoryStore = TimeAttackPlayHistoryStore()) {
        self.store = store
        self.history = history
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                List {
                    Section {
                        Picker("Difficulty", selection: $difficulty) {
                            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                                Text(difficulty.localizedTitle)
                                    .tag(difficulty)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }

                    ForEach(Self.sections(store: store, history: history, difficulty: difficulty), id: \.duration) { section in
                        recordSection(section)
                    }

                    // 一覧のいちばん下に置く。読み込みを始める時点で枠を確保し、
                    // 読み込めなかったときは行ごと消す（高さも区切りも残らない）
                    AdNativeAdView(placement: .timeAttackRecords)
                }
                .scrollContentBackground(.hidden)
                .background(.clear)
            }
            .sendAnalyticsScreen(.timeAttackRecords)
            .navigationTitle("Records")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    /// 推移に出す回数（直近から数える）
    static let trendPlayCount = 20

    /// 制限時間ごとの記録（15 / 30 / 60 秒の順）
    struct RecordSection: Equatable {
        let duration: TimeAttackDuration
        /// スコアの高い順。先頭が自己ベスト
        let records: [ScoreRecord]
        /// 直近のプレイのスコア（古い順、最大 `trendPlayCount` 回）。1.5.0 より前のプレイは無い
        var trendScores: [Int] = []

        /// 推移の折れ線を出すか。2 回以上遊んでいないと線にならない
        var showsTrend: Bool {
            trendScores.count >= 2
        }

        /// 折れ線の代わりに「2 回以上遊ぶと出る」案内を出すか。まだ一度も遊んでいない枠は「—」だけにする
        var showsTrendHint: Bool {
            !showsTrend && !(records.isEmpty && trendScores.isEmpty)
        }
    }

    static func sections(
        store: TimeAttackRecordStore,
        history: TimeAttackPlayHistoryStore,
        difficulty: Difficulty
    ) -> [RecordSection] {
        TimeAttackDuration.allCases.map { duration in
            let gameMode = GameMode.timeAttack(duration)
            return RecordSection(
                duration: duration,
                records: store.records(gameMode: gameMode, difficulty: difficulty),
                trendScores: history.entries(gameMode: gameMode, difficulty: difficulty)
                    .suffix(trendPlayCount)
                    .map(\.score)
            )
        }
    }
}

private extension TimeAttackRecordsView {
    func recordSection(_ section: RecordSection) -> some View {
        Section {
            if section.showsTrend {
                ScoreTrendChart(
                    scores: section.trendScores,
                    bestScore: section.records.first?.score,
                    tint: difficulty.gradientColors.first ?? .accentColor
                )
                .padding(.vertical, 8)
            } else if section.showsTrendHint {
                Text("Play at least twice to see your score trend.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if section.records.isEmpty {
                Text(verbatim: "—")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(Text("No records yet"))
            } else {
                ForEach(Array(section.records.enumerated()), id: \.offset) { index, record in
                    recordRow(rank: index + 1, record: record)
                }
            }
        } header: {
            Text(section.duration.localizedTitle)
        }
    }

    func recordRow(rank: Int, record: ScoreRecord) -> some View {
        let isBest = rank == 1
        return HStack(spacing: 12) {
            Text(verbatim: "\(rank)")
                .appFont(.number(.headline))
                .monospacedDigit()
                .frame(minWidth: 24, alignment: .trailing)
                .foregroundStyle(isBest ? Color.appGreen : Color.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.score, format: .number)
                    .appFont(.number(isBest ? .title3 : .body))
                    .monospacedDigit()

                if isBest {
                    Label("Personal Best", systemImage: "trophy.fill")
                        .font(.caption.bold())
                        .foregroundStyle(Color.appGreen)
                }
            }

            Spacer()

            Text(record.achievedAt, format: .dateTime.year().month().day())
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let userDefaults = UserDefaults(suiteName: "TimeAttackRecordsViewPreview")!
    userDefaults.removePersistentDomain(forName: "TimeAttackRecordsViewPreview")
    var date = Date(timeIntervalSince1970: 1_790_000_000)
    let store = TimeAttackRecordStore(userDefaults: userDefaults, now: { date })
    for score in [1_250, 980, 2_480, 1_100, 760, 1_900, 640, 1_320, 2_050, 870, 500] {
        date = date.addingTimeInterval(86_400)
        store.record(score: score, gameMode: .timeAttack(.thirtySeconds), difficulty: .easy)
    }
    store.record(score: 3_200, gameMode: .timeAttack(.sixtySeconds), difficulty: .easy)
    return TimeAttackRecordsView(store: store)
}
