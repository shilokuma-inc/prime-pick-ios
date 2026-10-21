//
//  TitleLogoView.swift
//  PrimePickApp
//

import SwiftUI
import UIKit

/// ホームのタイトル「Prime Pick」のロゴ（エラトステネスのふるい。Issue #415 で 10 案から選んだ案 3）
///
/// 1〜23 のマスを並べ、素数のマスにだけ文字を載せる。合成数のマスは細くして斜線で消す。
/// ロゴの中身（文字・書体・飾り）はこの View の中だけで決める。呼び出し側は虹の激しさと大きさだけを渡す
struct TitleLogoView: View {
    /// 呼び出し側が渡す虹の激しさ
    var style: GamingTextStyle = .standard
    /// 背の低い画面で、ホームを 1 画面に収めるために小さくするか
    var isCompact = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let scale = TitleLogoLayout.scale(isRegularWidth: horizontalSizeClass == .regular, isCompact: isCompact)
        // 虹は文字にだけ重ね、マスなどの飾りは虹にしない。脈動・揺れは飾りごとかける
        TitleLogoArtwork(layer: .letters, scale: scale)
            .gamingText(style: style) {
                TitleLogoArtwork(layer: .decoration, scale: scale)
            }
            // 飾りの数字・記号は読ませず、「Prime Pick」の 1 つの見出しとして読ませる
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: "Prime Pick"))
            .accessibilityAddTraits(.isHeader)
    }
}

/// ロゴの大きさ
enum TitleLogoLayout {
    /// ロゴの文字の書体（iOS に標準で入っている Didot Bold）
    static let fontName = "Didot-Bold"

    /// 大きさの倍率。iPhone の幅（iPhone SE の 375pt まで）に収まる大きさを 1 とし、iPad では大きくする。
    /// 背の低い画面では、ホームを 1 画面に収めるために小さくする
    ///
    /// ロゴは Dynamic Type で拡大しない（マスの並びの横幅が決まっていて、拡大すると画面からはみ出すため）
    static func scale(isRegularWidth: Bool, isCompact: Bool) -> CGFloat {
        if isRegularWidth { return isCompact ? 1.2 : 1.6 }
        return isCompact ? 0.65 : 1
    }
}

/// ロゴの組み立てに使う文字と数
enum TitleLogoGlyphs {
    /// 1 段目の文字
    static let firstWord = Array("PRIME")
    /// 2 段目の文字
    static let secondWord = Array("PICK")

    /// `n` が素数か
    static func isPrime(_ n: Int) -> Bool {
        guard n >= 2 else { return false }
        var divisor = 2
        while divisor * divisor <= n {
            if n % divisor == 0 { return false }
            divisor += 1
        }
        return true
    }

    /// ふるいのマス。素数のマスにだけ文字を載せる
    struct SieveCell: Equatable {
        let number: Int
        let letter: Character?
    }

    /// `numbers` を並べたふるいの 1 段。素数のマスに `letters` を順に載せる（素数の数と文字の数は同じにする）
    static func sieveRow(_ numbers: ClosedRange<Int>, letters: [Character]) -> [SieveCell] {
        var remaining = letters[...]
        return numbers.map { number in
            guard isPrime(number), let letter = remaining.popFirst() else {
                return SieveCell(number: number, letter: nil)
            }
            return SieveCell(number: number, letter: letter)
        }
    }

    /// 1 段目は 1〜11（素数は 2, 3, 5, 7, 11 の 5 個）、2 段目は 12〜23（13, 17, 19, 23 の 4 個）
    static let sieveRows = [sieveRow(1...11, letters: firstWord), sieveRow(12...23, letters: secondWord)]
}

/// ロゴを描く層。文字の層だけを虹にし、飾りの層は虹の後ろに敷く
enum TitleLogoLayer {
    case letters
    case decoration
}

/// ロゴの 1 つの層。どちらの層も同じ配置で描き、その層に無いものは透明にする（2 つの層がずれないように）
struct TitleLogoArtwork: View {
    let layer: TitleLogoLayer
    var scale: CGFloat = 1

    private var isDecoration: Bool { layer == .decoration }
    private var ink: Color { Color(uiColor: .secondaryLabel) }

    var body: some View {
        VStack(spacing: s(6)) {
            ForEach(Array(TitleLogoGlyphs.sieveRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: s(2)) {
                    ForEach(row, id: \.number) { cell in
                        if let character = cell.letter {
                            primeCell(number: cell.number, letter: character)
                        } else {
                            compositeCell(number: cell.number)
                        }
                    }
                }
            }
        }
    }

    private func s(_ value: CGFloat) -> CGFloat { value * scale }

    private func font(_ size: CGFloat) -> Font {
        .custom(TitleLogoLayout.fontName, fixedSize: s(size))
    }

    /// 素数のマス。左上に素数を書き、文字を載せる
    private func primeCell(number: Int, letter: Character) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: s(3))
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(RoundedRectangle(cornerRadius: s(3)).stroke(Color.primary.opacity(0.7), lineWidth: s(1.5)))
                .opacity(isDecoration ? 1 : 0)
            Text(verbatim: "\(number)")
                .font(font(9))
                .foregroundStyle(ink)
                .padding(s(2))
                .opacity(isDecoration ? 1 : 0)
            Text(verbatim: String(letter))
                .font(font(34))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: s(3))
                .opacity(isDecoration ? 0 : 1)
        }
        .frame(width: s(40), height: s(50))
    }

    /// 合成数（と 1）のマス。細くして斜線で消す
    private func compositeCell(number: Int) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.primary.opacity(0.06))
            Text(verbatim: "\(number)")
                .font(font(8))
                .foregroundStyle(ink.opacity(0.7))
                .minimumScaleFactor(0.5)
            Path { path in
                path.move(to: CGPoint(x: 0, y: s(50)))
                path.addLine(to: CGPoint(x: s(13), y: 0))
            }
            .stroke(ink.opacity(0.6), lineWidth: s(1))
        }
        .frame(width: s(13), height: s(50))
        .opacity(isDecoration ? 1 : 0)
    }
}

#Preview {
    TitleLogoView()
}

#Preview("小さく") {
    TitleLogoView(isCompact: true)
}

#Preview("Expert の確認のカード") {
    TitleLogoView(style: Difficulty.expert.confirmationTitleStyle(reduceMotion: false))
}
