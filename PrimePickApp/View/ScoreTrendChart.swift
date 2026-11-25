//
//  ScoreTrendChart.swift
//  PrimePickApp
//

import Charts
import SwiftUI

/// 記録画面の制限時間ごとのセクションに出す、直近のプレイのスコアの推移（#550）
///
/// 古いプレイを左、新しいプレイを右にして折れ線で結び、自己ベストを横の点線で重ねる。
/// 点線は灰色にする。折れ線は難易度の色（かんたんは緑）なので、緑にすると見分けにくい。
/// VoiceOver では折れ線を 1 点ずつ読ませず、回数と最新・最高・最低のスコアをまとめて読む。
struct ScoreTrendChart: View {
    /// 古い順のスコア。2 回以上あるときだけ使う
    let scores: [Int]
    /// 自己ベスト（上位 10 件の 1 位）。履歴を始める前のプレイの記録も含む
    let bestScore: Int?
    /// 折れ線の色（難易度の色）
    let tint: Color

    /// グラフの高さ
    static let height: CGFloat = 120

    /// 折れ線の 1 点
    struct Point: Identifiable, Equatable {
        /// 何回目か（古い順に 1 から）
        let play: Int
        let score: Int
        /// いちばん新しいプレイか。点を大きくする
        let isLatest: Bool

        var id: Int { play }
    }

    /// 古い順のスコアを折れ線の点にする
    static func points(of scores: [Int]) -> [Point] {
        scores.enumerated().map { index, score in
            Point(play: index + 1, score: score, isLatest: index == scores.count - 1)
        }
    }

    var body: some View {
        Chart {
            ForEach(Self.points(of: scores)) { point in
                line(point)
                dot(point)
            }

            if let bestScore {
                bestRule(bestScore)
            }
        }
        .chartXAxis(.hidden)
        .chartXScale(domain: 1...max(scores.count, 2))
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3))
        }
        .frame(height: Self.height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Score trend of the last \(scores.count) plays"))
        .accessibilityValue(Self.accessibilitySummary(scores))
    }

    private func line(_ point: Point) -> some ChartContent {
        LineMark(
            x: .value(Self.playLabel, point.play),
            y: .value(Self.scoreLabel, point.score)
        )
        .foregroundStyle(tint)
        .interpolationMethod(.monotone)
    }

    private func dot(_ point: Point) -> some ChartContent {
        PointMark(
            x: .value(Self.playLabel, point.play),
            y: .value(Self.scoreLabel, point.score)
        )
        .foregroundStyle(tint)
        .symbolSize(point.isLatest ? Self.latestSymbolSize : Self.symbolSize)
    }

    /// 自己ベストの横の点線
    private func bestRule(_ score: Int) -> some ChartContent {
        RuleMark(y: .value(Self.scoreLabel, score))
            .foregroundStyle(Color.secondary)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .annotation(position: .top, alignment: .leading, spacing: 2) {
                Text("Best")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.secondary)
            }
    }

    /// 点の大きさ（いちばん新しいプレイだけ大きくする）
    private static let symbolSize: CGFloat = 20
    private static let latestSymbolSize: CGFloat = 60

    /// 読み上げる要約（最新・最高・最低）。空なら何も読まない
    static func accessibilitySummary(_ scores: [Int]) -> Text {
        guard let latest = scores.last, let highest = scores.max(), let lowest = scores.min() else {
            return Text(verbatim: "")
        }
        return Text("Latest \(latest), highest \(highest), lowest \(lowest)")
    }

    // 軸の名前は画面に出さず（軸を隠している）、読み上げは要約に置き換えているので訳さない
    private static let playLabel = "Play"
    private static let scoreLabel = "Score"
}

#Preview {
    List {
        Section("30 seconds") {
            ScoreTrendChart(scores: [820, 1_100, 960, 1_420, 1_310, 1_780, 1_650], bestScore: 2_000, tint: .green)
        }
    }
}
