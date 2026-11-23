//
//  TitleLogoView.swift
//  PrimePickApp
//

import SwiftUI
import UIKit

/// ホームのタイトルのロゴ（エラトステネスのふるい。Issue #415 で 10 案から選んだ案 3）
///
/// 1 から順にマスを並べ、素数のマスにだけアプリ名の文字を載せる。合成数のマスは細くして斜線で消す。
/// 文字は言語ごとのアプリ名で（Issue #524）、行の分け方は `TitleLogoGlyphs.localizedLines` で決める。
/// ロゴの中身（文字・書体・飾り）はこの View の中だけで決める。呼び出し側は虹の激しさと大きさだけを渡す
struct TitleLogoView: View {
    /// 呼び出し側が渡す虹の激しさ
    var style: GamingTextStyle = .standard
    /// 背の低い画面で、ホームを 1 画面に収めるために小さくするか
    var isCompact = false
    /// ロゴに並べる行（既定は表示している言語のアプリ名）
    var lines = TitleLogoGlyphs.localizedLines

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let rows = TitleLogoGlyphs.sieveRows(lines: lines)
        let scale = TitleLogoLayout.scale(isRegularWidth: horizontalSizeClass == .regular, isCompact: isCompact)
            * TitleLogoLayout.fittingScale(for: rows)
        // 虹は文字にだけ重ね、マスなどの飾りは虹にしない。脈動・揺れは飾りごとかける
        TitleLogoArtwork(layer: .letters, rows: rows, scale: scale)
            .gamingText(style: style) {
                TitleLogoArtwork(layer: .decoration, rows: rows, scale: scale)
            }
            // 飾りの数字・記号は読ませず、アプリ名の 1 つの見出しとして読ませる
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: AppName.current))
            .accessibilityAddTraits(.isHeader)
    }
}

/// ロゴの大きさ
enum TitleLogoLayout {
    /// ロゴの文字の書体（iOS に標準で入っている Didot Bold）
    static let fontName = "Didot-Bold"
    /// 日本語の文字の書体（アプリの見出しと同じヒラギノ明朝 W6）。中国語・韓国語は `AppFont.cjkFont(language:japanese:)` が決める
    static let japaneseFontName = "HiraMinProN-W6"

    /// 大きさの倍率。iPhone の幅（iPhone SE の 375pt まで）に収まる大きさを 1 とし、iPad では大きくする。
    /// 背の低い画面では、ホームを 1 画面に収めるために小さくする
    ///
    /// ロゴは Dynamic Type で拡大しない（マスの並びの横幅が決まっていて、拡大すると画面からはみ出すため）
    static func scale(isRegularWidth: Bool, isCompact: Bool) -> CGFloat {
        if isRegularWidth { return isCompact ? 1.2 : 1.6 }
        return isCompact ? 0.65 : 1
    }

    /// 倍率 1 のときに収める横幅（iPhone SE の幅 375pt から左右の余白を引いた幅）
    static let maxWidth: CGFloat = 327

    /// 素数のマス・合成数のマスの幅と、マスの間隔（倍率 1 のとき）。描くとき（`TitleLogoArtwork`）もこの値を使う
    static let primeCellWidth: CGFloat = 40
    static let compositeCellWidth: CGFloat = 13
    static let cellSpacing: CGFloat = 2

    /// 倍率 1 のときの、いちばん長い行の横幅
    static func naturalWidth(of rows: [[TitleLogoGlyphs.SieveCell]]) -> CGFloat {
        rows.map { row in
            row.reduce(CGFloat(0)) { width, cell in
                width + (cell.letter == nil ? compositeCellWidth : primeCellWidth)
            } + cellSpacing * CGFloat(max(row.count - 1, 0))
        }.max() ?? 0
    }

    /// 長いアプリ名（後ろの行ほど素数の間が空き、マスが増える）を `maxWidth` に収めるための倍率。収まるなら 1
    static func fittingScale(for rows: [[TitleLogoGlyphs.SieveCell]]) -> CGFloat {
        let width = naturalWidth(of: rows)
        return width > maxWidth ? maxWidth / width : 1
    }
}

/// ロゴの組み立てに使う文字と数
enum TitleLogoGlyphs {
    /// 表示している言語のロゴの行。アプリ名（`InfoPlist.xcstrings` の `CFBundleDisplayName`）を、
    /// 言語ごとに読みやすい位置で行に分けたもの（`Localizable.xcstrings` の `TitleLogoLines`。改行で区切る）
    ///
    /// 欧文は大文字にして書く。空白はマスにしない（語の区切りは行を分けて表す）
    static var localizedLines: [String] {
        lines(from: String(localized: "TitleLogoLines", defaultValue: "PRIME\nOR\nNOT?",
                           comment: "ホームのロゴ（ふるい）に並べるアプリ名。改行で行を分ける。欧文は大文字。CFBundleDisplayName と同じ文字にする"))
    }

    /// 改行で区切った文字列を行にする（空の行は捨てる）
    static func lines(from text: String) -> [String] {
        text.split(whereSeparator: \.isNewline).map(String.init).filter { !$0.isEmpty }
    }

    /// マスに載せる文字（空白を除く）
    static func glyphs(of line: String) -> [Character] {
        line.filter { !$0.isWhitespace }.map { $0 }
    }

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

    /// 行ごとのふるいのマス。数は 1 から行をまたいで続け、各行は最後の文字を載せた素数で終える
    ///
    /// 例: 「PRIME」「PICK」なら 1 段目は 1〜11（2, 3, 5, 7, 11）、2 段目は 12〜23（13, 17, 19, 23）
    static func sieveRows(lines: [String]) -> [[SieveCell]] {
        var start = 1
        return lines.compactMap { line in
            let letters = glyphs(of: line)
            guard !letters.isEmpty else { return nil }
            var end = start
            var primes = 0
            while true {
                if isPrime(end) {
                    primes += 1
                    if primes == letters.count { break }
                }
                end += 1
            }
            defer { start = end + 1 }
            return sieveRow(start...end, letters: letters)
        }
    }
}

/// ロゴを描く層。文字の層だけを虹にし、飾りの層は虹の後ろに敷く
enum TitleLogoLayer {
    case letters
    case decoration
}

/// ロゴの 1 つの層。どちらの層も同じ配置で描き、その層に無いものは透明にする（2 つの層がずれないように）
struct TitleLogoArtwork: View {
    let layer: TitleLogoLayer
    var rows = TitleLogoGlyphs.sieveRows(lines: TitleLogoGlyphs.localizedLines)
    var scale: CGFloat = 1

    private var isDecoration: Bool { layer == .decoration }
    private var ink: Color { Color(uiColor: .secondaryLabel) }

    var body: some View {
        VStack(spacing: s(6)) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: s(TitleLogoLayout.cellSpacing)) {
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

    /// 文字の書体。欧文は Didot Bold で、日本語・中国語・韓国語の文字だけその言語の書体を組み合わせる
    private func letterFont(_ size: CGFloat) -> Font {
        Font(AppFont.cascadedUIFont(
            name: TitleLogoLayout.fontName,
            japanese: AppFont.cjkFont(language: AppFont.displayLanguage, japanese: TitleLogoLayout.japaneseFontName),
            size: .fixed(s(size))
        ))
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
                .font(letterFont(34))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: s(3))
                .opacity(isDecoration ? 0 : 1)
        }
        .frame(width: s(TitleLogoLayout.primeCellWidth), height: s(50))
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
                path.addLine(to: CGPoint(x: s(TitleLogoLayout.compositeCellWidth), y: 0))
            }
            .stroke(ink.opacity(0.6), lineWidth: s(1))
        }
        .frame(width: s(TitleLogoLayout.compositeCellWidth), height: s(50))
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
