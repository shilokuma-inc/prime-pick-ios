//
//  DailyChallengeShareCardView.swift
//  PrimePickApp
//

import SwiftUI
import UIKit

/// デイリーの結果のシェアで渡す正方形の画像カード
///
/// 共有シートには文・リンクと別の項目として渡す（リンクは焼き込まない）。
/// アプリの外観設定（ダーク / ライト）によらず同じ見た目になるよう、色は固定する。
struct DailyChallengeShareCardView: View {
    let content: DailyChallengeShareContent

    /// カードの一辺（pt）。`imageScale` 倍して書き出す
    static let side: CGFloat = 360
    /// 書き出す画像の一辺（px）
    static let imagePixelSide: CGFloat = 1080
    static var imageScale: CGFloat { imagePixelSide / side }

    private static let backgroundTop = Color(red: 0.08, green: 0.10, blue: 0.22)
    private static let backgroundBottom = Color(red: 0.19, green: 0.13, blue: 0.36)
    private static let foreground = Color.white
    private static let secondaryForeground = Color.white.opacity(0.72)
    /// マス目を置く 1 行のマスの数
    private static let tilesPerRow = 5

    var body: some View {
        VStack(spacing: 14) {
            Text(verbatim: AppName.current)
                .appFont(.heading(size: 30, weight: .bold))
                .foregroundStyle(Self.foreground)

            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Text("Daily Challenge")
                    Text(verbatim: "#\(content.dayNumber)")
                }
                .appFont(.heading(size: 20, weight: .semibold))
                .foregroundStyle(Self.foreground)

                Text(verbatim: content.dateText)
                    .appFont(.number(size: 16))
                    .foregroundStyle(Self.secondaryForeground)
            }

            pattern

            VStack(spacing: 6) {
                Text(verbatim: content.scoreLine)
                    .appFont(.heading(size: 22, weight: .bold))
                    .foregroundStyle(Self.foreground)
                Text(verbatim: content.streakLine)
                    .appFont(.heading(size: 20, weight: .semibold))
                    .foregroundStyle(Self.foreground)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .multilineTextAlignment(.center)
        .padding(24)
        .frame(width: Self.side, height: Self.side)
        .background(
            LinearGradient(colors: [Self.backgroundTop, Self.backgroundBottom], startPoint: .top, endPoint: .bottom)
        )
    }

    /// 🟩🟥 のマス目。5 マスずつ 2 行に並べる
    private var pattern: some View {
        VStack(spacing: 4) {
            ForEach(Array(patternRows.enumerated()), id: \.offset) { _, row in
                Text(verbatim: row)
                    .font(.system(size: 34))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    private var patternRows: [String] {
        let tiles = Array(content.resultPattern)
        return stride(from: 0, to: tiles.count, by: Self.tilesPerRow).map {
            String(tiles[$0..<min($0 + Self.tilesPerRow, tiles.count)])
        }
    }

    /// カードを正方形（`imagePixelSide` px 四方）の画像に書き出す
    @MainActor
    static func renderImage(content: DailyChallengeShareContent) -> UIImage? {
        let card = DailyChallengeShareCardView(content: content)
            // 外観設定や文字の大きさの設定で見た目が変わらないよう固定する
            .environment(\.colorScheme, .dark)
            .environment(\.dynamicTypeSize, .large)
        let renderer = ImageRenderer(content: card)
        renderer.proposedSize = ProposedViewSize(width: side, height: side)
        renderer.scale = imageScale
        return renderer.uiImage
    }
}
