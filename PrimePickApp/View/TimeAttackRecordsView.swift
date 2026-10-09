//
//  TimeAttackRecordsView.swift
//  PrimePickApp
//

import SwiftUI

/// タイムアタックの記録画面（Discussion #270）
///
/// 難易度をセグメントで切り替え、制限時間ごとに上位 10 件をスコアと達成日つきで並べる。1 位が自己ベスト。
/// 記録は開いた時点の値を出す（シートで開き、開いている間にプレイは終わらないため）。
struct TimeAttackRecordsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var difficulty: Difficulty = .easy

    private let store: TimeAttackRecordStore

    init(store: TimeAttackRecordStore = TimeAttackRecordStore()) {
        self.store = store
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

                    ForEach(Self.sections(store: store, difficulty: difficulty), id: \.duration) { section in
                        recordSection(section)
                    }
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

    /// 制限時間ごとの記録（15 / 30 / 60 秒の順）
    struct RecordSection: Equatable {
        let duration: TimeAttackDuration
        /// スコアの高い順。先頭が自己ベスト
        let records: [ScoreRecord]
    }

    static func sections(store: TimeAttackRecordStore, difficulty: Difficulty) -> [RecordSection] {
        TimeAttackDuration.allCases.map { duration in
            RecordSection(
                duration: duration,
                records: store.records(gameMode: .timeAttack(duration), difficulty: difficulty)
            )
        }
    }
}

private extension TimeAttackRecordsView {
    func recordSection(_ section: RecordSection) -> some View {
        Section {
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
                .font(.headline.monospacedDigit())
                .frame(minWidth: 24, alignment: .trailing)
                .foregroundStyle(isBest ? Color.appGreen : Color.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.score, format: .number)
                    .font(isBest ? .title3.bold().monospacedDigit() : .body.monospacedDigit())

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
