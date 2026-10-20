//
//  TitleLogoCandidates.swift
//  PrimePickApp
//

import SwiftUI
import UIKit

// タイトルのロゴの案（Issue #415 / Discussion #409）。案を選んでもらうための一時的なコードで、回答の後に採用した案だけを残す

/// ロゴの組み立てに使う文字と数
enum TitleLogoGlyphs {
    /// 1 段目の文字
    static let firstWord = Array("PRIME")
    /// 2 段目の文字
    static let secondWord = Array("PICK")
    /// 1 列に並べるときの文字（9 字）
    static var letters: [Character] { firstWord + secondWord }

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

    /// 小さい方から `count` 個の素数
    static func primes(count: Int) -> [Int] {
        var result: [Int] = []
        var n = 2
        while result.count < count {
            if isPrime(n) { result.append(n) }
            n += 1
        }
        return result
    }

    /// 1 字ずつ添える素数（2, 3, 5, …, 23。9 字と同じ数）
    static let letterPrimes = primes(count: 9)

    // MARK: スクラブル

    /// スクラブルの点数。同じ文字には同じ素数を当てる
    static let scrabbleValues: [Character: Int] = ["P": 2, "R": 3, "I": 5, "M": 7, "E": 11, "C": 13, "K": 17]

    // MARK: エラトステネスのふるい

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

    // MARK: 周期表

    /// 周期表のマス（記号と、原子番号の位置に置く素数）
    struct ElementTile: Equatable {
        let symbol: String
        let number: Int
    }

    /// Pr（59）と I（53）は本物の元素と原子番号。ほかは架空で、原子番号の位置に素数を置く
    static let elementRows = [
        [ElementTile(symbol: "Pr", number: 59), ElementTile(symbol: "I", number: 53), ElementTile(symbol: "Me", number: 101)],
        [ElementTile(symbol: "Pi", number: 31), ElementTile(symbol: "Ck", number: 89)],
    ]

    // MARK: ドットマトリクス

    /// 5×7 のドットの字形。上の段から、`1` が光るドット
    static let dotMatrix: [Character: [String]] = [
        "P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
        "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
        "I": ["01110", "00100", "00100", "00100", "00100", "00100", "01110"],
        "M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
        "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
        "C": ["01110", "10001", "10000", "10000", "10000", "10001", "01110"],
        "K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
    ]

    /// 文字を 1 列分のドットをあけて並べた、ドットの行（7 行）
    static func dotRows(for word: [Character]) -> [[Bool]] {
        (0..<7).map { row in
            var line: [Bool] = []
            for (index, letter) in word.enumerated() {
                if index > 0 { line.append(false) }
                line += (dotMatrix[letter]?[row] ?? "00000").map { $0 == "1" }
            }
            return line
        }
    }

    // MARK: ウラムの螺旋

    /// ウラムの螺旋で `1...(side * side)` を置くマス（列, 行）。1 を中央に置き、右・上・左・下の順に巻く
    static func ulamSpiral(side: Int) -> [Int: (column: Int, row: Int)] {
        var positions: [Int: (column: Int, row: Int)] = [:]
        var column = side / 2
        var row = side / 2
        var number = 1
        positions[number] = (column, row)
        let directions = [(1, 0), (0, -1), (-1, 0), (0, 1)]
        var step = 1
        var directionIndex = 0
        while number < side * side {
            for _ in 0..<2 {
                let (dx, dy) = directions[directionIndex % 4]
                for _ in 0..<step where number < side * side {
                    column += dx
                    row += dy
                    number += 1
                    positions[number] = (column, row)
                }
                directionIndex += 1
            }
            step += 1
        }
        return positions
    }

    // MARK: カクロ

    /// カクロのヒント（その段のマスの素数の合計）。1 段目は 2+3+5+7+11、2 段目は 13+17+19+23
    static var kakuroClues: [Int] {
        [
            letterPrimes.prefix(firstWord.count).reduce(0, +),
            letterPrimes.suffix(secondWord.count).reduce(0, +),
        ]
    }
}

/// タイトルのロゴの案
enum TitleLogoCandidate: Int, CaseIterable, Identifiable {
    case sudoku = 1
    case scrabble
    case sieve
    case tiles2048
    case periodicTable
    case dotMatrix
    case graphNote
    case blocks
    case ulamSpiral
    case kakuro

    var id: Int { rawValue }

    /// 起動引数の名前。続けて案の番号（1〜10）を渡す
    static let launchArgument = "-title-logo-candidate"
    /// 10 案を並べた一覧を出す起動引数
    static let galleryLaunchArgument = "-title-logo-gallery"

    /// 起動引数から選ぶ案。番号が無い・範囲の外なら nil
    static func candidate(arguments: [String]) -> TitleLogoCandidate? {
        guard let index = arguments.firstIndex(of: launchArgument), arguments.indices.contains(index + 1) else {
            return nil
        }
        return Int(arguments[index + 1]).flatMap(TitleLogoCandidate.init(rawValue:))
    }

    #if DEBUG
    /// 起動引数で選んだ案（DEBUG ビルドだけ）
    static let active = candidate(arguments: ProcessInfo.processInfo.arguments)
    /// 10 案の一覧を出すか（DEBUG ビルドだけ）
    static let showsGallery = ProcessInfo.processInfo.arguments.contains(galleryLaunchArgument)
    #endif

    /// この案の書体。採用した案の書体をアプリ全体の見出し・ボタン・数字に使う（Discussion #409 Q4）
    var typeface: AppTypeface {
        switch self {
        case .sudoku:
            AppTypeface(heading: .namedWithJapanese("GillSans-Bold", japanese: "HiraginoSans-W6"), number: .named("GillSans-Bold"))
        case .scrabble:
            AppTypeface(heading: .namedWithJapanese("Futura-Bold", japanese: "HiraginoSans-W6"), number: .named("Futura-Bold"))
        case .sieve:
            AppTypeface(heading: .namedWithJapanese("Didot-Bold", japanese: "HiraMinProN-W6"), number: .named("Didot-Bold"))
        case .tiles2048:
            AppTypeface(heading: .namedWithJapanese("ArialRoundedMTBold", japanese: "HiraMaruProN-W4"), number: .named("ArialRoundedMTBold"))
        case .periodicTable:
            AppTypeface(heading: .namedWithJapanese("Avenir-Black", japanese: "HiraginoSans-W6"), number: .named("Avenir-Heavy"))
        case .dotMatrix:
            AppTypeface(heading: .namedWithJapanese("Menlo-Bold", japanese: "HiraginoSans-W6"), number: .named("Menlo-Bold"))
        case .graphNote:
            AppTypeface(heading: .namedWithJapanese("ChalkboardSE-Bold", japanese: "HiraMaruProN-W4"), number: .named("ChalkboardSE-Bold"))
        case .blocks:
            .standard
        case .ulamSpiral:
            AppTypeface(heading: .namedWithJapanese("Optima-ExtraBlack", japanese: "HiraginoSans-W7"), number: .named("Optima-Bold"))
        case .kakuro:
            AppTypeface(heading: .namedWithJapanese("AvenirNextCondensed-Heavy", japanese: "HiraginoSans-W7"), number: .named("AvenirNextCondensed-Bold"))
        }
    }

    /// ロゴの文字に使う書体（欧文の PostScript 名。nil ならシステムの丸ゴシック）
    var logoFontName: String? {
        switch typeface.heading {
        case .system: nil
        case let .named(name), let .namedWithJapanese(name, _): name
        }
    }
}

/// ロゴを描く層。文字の層だけを虹にし、飾りの層は虹の後ろに敷く
enum TitleLogoLayer {
    case letters
    case decoration
}

/// 案のロゴ。文字は虹（`gamingText(style:)`）、タイルなどの飾りは虹にしない（既定の解釈 3）
struct TitleLogoCandidateView: View {
    let candidate: TitleLogoCandidate
    var style: GamingTextStyle = .standard
    /// 大きさの倍率。iPhone の幅に収まる大きさを 1 とする
    var scale: CGFloat = 1

    var body: some View {
        TitleLogoArtwork(candidate: candidate, layer: .letters, scale: scale)
            .gamingText(style: style) {
                TitleLogoArtwork(candidate: candidate, layer: .decoration, scale: scale)
            }
            // 飾りの文字・数字は読ませず、「Prime Pick」の 1 つの見出しとして読ませる
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: "Prime Pick"))
            .accessibilityAddTraits(.isHeader)
    }
}

/// ロゴの 1 つの層。どちらの層も同じ配置で描き、その層に無いものは透明にする（2 つの層がずれないように）
private struct TitleLogoArtwork: View {
    let candidate: TitleLogoCandidate
    let layer: TitleLogoLayer
    let scale: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch candidate {
        case .sudoku: sudoku
        case .scrabble: scrabble
        case .sieve: sieve
        case .tiles2048: tiles2048
        case .periodicTable: periodicTable
        case .dotMatrix: dotMatrix
        case .graphNote: graphNote
        case .blocks: blocks
        case .ulamSpiral: ulamSpiral
        case .kakuro: kakuro
        }
    }

    // MARK: 部品

    private func s(_ value: CGFloat) -> CGFloat { value * scale }

    /// ロゴの文字の書体
    private func logoFont(_ size: CGFloat) -> Font {
        if let name = candidate.logoFontName {
            return .custom(name, fixedSize: s(size))
        }
        return .system(size: s(size), weight: .heavy, design: .rounded)
    }

    /// 飾りの数字の書体
    private func numberFont(_ size: CGFloat) -> Font {
        if let name = candidate.logoFontName {
            return .custom(name, fixedSize: s(size))
        }
        return .custom("ArialRoundedMTBold", fixedSize: s(size))
    }

    /// 文字の層だけに出す文字
    private func letter(_ text: String, size: CGFloat) -> some View {
        Text(verbatim: text)
            .font(logoFont(size))
            .opacity(layer == .letters ? 1 : 0)
    }

    private var isDecoration: Bool { layer == .decoration }

    /// タイルの面の色（ライトは白に近く、ダークは暗い灰色）
    private var tileFace: Color { Color(uiColor: .secondarySystemGroupedBackground) }
    private var tileEdge: Color { Color(uiColor: .systemGray3) }
    private var ink: Color { Color(uiColor: .secondaryLabel) }

    private func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(hex: colorScheme == .dark ? dark : light)
    }

    // MARK: 1. 数独

    /// 数独の 1 段（3 マス × 3 ボックス）に 1 字ずつ載せ、マスの隅に候補の数字のように素数を書く
    private var sudoku: some View {
        let letters = TitleLogoGlyphs.letters
        let primes = TitleLogoGlyphs.letterPrimes
        return HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { box in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { offset in
                        let index = box * 3 + offset
                        ZStack(alignment: .topLeading) {
                            Rectangle()
                                .fill(tileFace)
                                .overlay(Rectangle().stroke(tileEdge, lineWidth: s(0.75)))
                                .opacity(isDecoration ? 1 : 0)
                            Text(verbatim: "\(primes[index])")
                                .font(numberFont(9))
                                .foregroundStyle(ink)
                                .padding(s(2))
                                .opacity(isDecoration ? 1 : 0)
                            letter(String(letters[index]), size: 27)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .offset(y: s(2))
                        }
                        .frame(width: s(35), height: s(42))
                    }
                }
                .overlay(Rectangle().stroke(Color.primary.opacity(0.8), lineWidth: s(2)).opacity(isDecoration ? 1 : 0))
            }
        }
        .overlay(Rectangle().stroke(Color.primary.opacity(0.8), lineWidth: s(3)).opacity(isDecoration ? 1 : 0))
    }

    // MARK: 2. スクラブル

    /// 木の駒のような文字タイル。右下の点数は素数で、同じ文字は同じ点数
    private var scrabble: some View {
        VStack(spacing: s(6)) {
            ForEach([TitleLogoGlyphs.firstWord, TitleLogoGlyphs.secondWord], id: \.self) { word in
                HStack(spacing: s(5)) {
                    ForEach(Array(word.enumerated()), id: \.offset) { _, character in
                        ZStack(alignment: .bottomTrailing) {
                            RoundedRectangle(cornerRadius: s(6))
                                .fill(adaptive(light: 0xF2DDB0, dark: 0x5C4A2E))
                                .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: s(2.5))
                                .opacity(isDecoration ? 1 : 0)
                            Text(verbatim: "\(TitleLogoGlyphs.scrabbleValues[character] ?? 0)")
                                .font(numberFont(11))
                                .foregroundStyle(adaptive(light: 0x5C4A2E, dark: 0xF2DDB0))
                                .padding(.trailing, s(4))
                                .padding(.bottom, s(2))
                                .opacity(isDecoration ? 1 : 0)
                            letter(String(character), size: 32)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(width: s(50), height: s(52))
                    }
                }
            }
        }
    }

    // MARK: 3. エラトステネスのふるい

    /// 1〜23 のマスを並べ、素数のマスにだけ文字を載せる。合成数のマスは細くして斜線で消す
    private var sieve: some View {
        VStack(spacing: s(6)) {
            ForEach(Array(TitleLogoGlyphs.sieveRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: s(2)) {
                    ForEach(row, id: \.number) { cell in
                        if let character = cell.letter {
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: s(3))
                                    .fill(tileFace)
                                    .overlay(RoundedRectangle(cornerRadius: s(3)).stroke(Color.primary.opacity(0.7), lineWidth: s(1.5)))
                                    .opacity(isDecoration ? 1 : 0)
                                Text(verbatim: "\(cell.number)")
                                    .font(numberFont(9))
                                    .foregroundStyle(ink)
                                    .padding(s(2))
                                    .opacity(isDecoration ? 1 : 0)
                                letter(String(character), size: 34)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .offset(y: s(3))
                            }
                            .frame(width: s(40), height: s(50))
                        } else {
                            ZStack {
                                Rectangle()
                                    .fill(Color.primary.opacity(0.06))
                                Text(verbatim: "\(cell.number)")
                                    .font(numberFont(8))
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
                }
            }
        }
    }

    // MARK: 4. 2048

    /// 2048 のような盤と角丸のタイル。左上の値は素数で、値が大きいほどタイルの色が濃い
    private var tiles2048: some View {
        let primes = TitleLogoGlyphs.letterPrimes
        let lightColors: [UInt32] = [0xEEE4DA, 0xEDE0C8, 0xF2D9B1, 0xF5CFA0, 0xF6C48F, 0xF4B98A, 0xF2AE85, 0xEFA37F, 0xED9879]
        let darkColors: [UInt32] = [0x4A4038, 0x524536, 0x5A4A32, 0x62502F, 0x6A552C, 0x6E5030, 0x724B33, 0x764637, 0x7A413A]
        return VStack(spacing: s(6)) {
            ForEach(0..<2, id: \.self) { row in
                let word = row == 0 ? TitleLogoGlyphs.firstWord : TitleLogoGlyphs.secondWord
                HStack(spacing: s(6)) {
                    ForEach(Array(word.enumerated()), id: \.offset) { offset, character in
                        let index = row == 0 ? offset : TitleLogoGlyphs.firstWord.count + offset
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: s(8))
                                .fill(adaptive(light: lightColors[index], dark: darkColors[index]))
                                .opacity(isDecoration ? 1 : 0)
                            Text(verbatim: "\(primes[index])")
                                .font(numberFont(10))
                                .foregroundStyle(adaptive(light: 0x776E65, dark: 0xD8CFC4))
                                .padding(s(4))
                                .opacity(isDecoration ? 1 : 0)
                            letter(String(character), size: 32)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .offset(y: s(2))
                        }
                        .frame(width: s(50), height: s(50))
                    }
                }
            }
        }
        .padding(s(6))
        .background(
            RoundedRectangle(cornerRadius: s(12))
                .fill(adaptive(light: 0xBBADA0, dark: 0x3A332D))
                .opacity(isDecoration ? 1 : 0)
        )
    }

    // MARK: 5. 周期表

    /// 周期表のマス。左上の原子番号の位置に素数を置く（Pr = 59・I = 53 は本物、ほかは架空）
    private var periodicTable: some View {
        VStack(spacing: s(6)) {
            ForEach(Array(TitleLogoGlyphs.elementRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: s(6)) {
                    ForEach(row, id: \.symbol) { tile in
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: s(4))
                                .fill(tileFace)
                                .overlay(RoundedRectangle(cornerRadius: s(4)).stroke(Color.primary.opacity(0.7), lineWidth: s(1.5)))
                                .opacity(isDecoration ? 1 : 0)
                            Text(verbatim: "\(tile.number)")
                                .font(numberFont(11))
                                .foregroundStyle(ink)
                                .padding(s(4))
                                .opacity(isDecoration ? 1 : 0)
                            letter(tile.symbol, size: 32)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .offset(y: s(4))
                        }
                        .frame(width: s(64), height: s(60))
                    }
                }
            }
        }
    }

    // MARK: 6. ドットマトリクス

    /// 電光掲示板・電卓のようなドットの文字。光るドットだけを虹にし、下に素数を並べる
    private var dotMatrix: some View {
        let pitch = s(8)
        let dot = s(6.4)
        return VStack(spacing: s(6)) {
            ForEach(0..<2, id: \.self) { row in
                let word = row == 0 ? TitleLogoGlyphs.firstWord : TitleLogoGlyphs.secondWord
                let lines = TitleLogoGlyphs.dotRows(for: word)
                VStack(spacing: pitch - dot) {
                    ForEach(0..<lines.count, id: \.self) { y in
                        HStack(spacing: pitch - dot) {
                            ForEach(0..<lines[y].count, id: \.self) { x in
                                Circle()
                                    .fill(lines[y][x] && layer == .letters ? Color.white : Color.primary.opacity(0.08))
                                    .frame(width: dot, height: dot)
                                    .opacity(lines[y][x] ? (layer == .letters ? 1 : 0) : (isDecoration ? 1 : 0))
                            }
                        }
                    }
                }
            }
            Text(verbatim: TitleLogoGlyphs.letterPrimes.map(String.init).joined(separator: " "))
                .font(numberFont(12))
                .foregroundStyle(ink)
                .opacity(isDecoration ? 1 : 0)
        }
        .padding(s(10))
        .background(
            RoundedRectangle(cornerRadius: s(10))
                .fill(Color.primary.opacity(0.05))
                .opacity(isDecoration ? 1 : 0)
        )
    }

    // MARK: 7. 方眼ノート

    /// 方眼のノートに手書き風の文字。素数の集合 ℙ の式を書き添える
    private var graphNote: some View {
        let width = s(300)
        let height = s(120)
        let grid = s(10)
        return ZStack {
            ZStack {
                RoundedRectangle(cornerRadius: s(6))
                    .fill(tileFace)
                Path { path in
                    var x: CGFloat = 0
                    while x <= width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                        x += grid
                    }
                    var y: CGFloat = 0
                    while y <= height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                        y += grid
                    }
                }
                .stroke(Color.blue.opacity(0.18), lineWidth: s(0.5))
                .clipShape(RoundedRectangle(cornerRadius: s(6)))
                Text(verbatim: "p ∈ ℙ")
                    .font(numberFont(13))
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(s(8))
                Text(verbatim: "ℙ = {2, 3, 5, 7, 11, …}")
                    .font(numberFont(12))
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(s(8))
            }
            .opacity(isDecoration ? 1 : 0)
            letter("Prime Pick", size: 46)
                .fixedSize()
                .rotationEffect(.degrees(-4))
        }
        .frame(width: width, height: height)
    }

    // MARK: 8. 立体ブロック

    /// 厚みのある積み木（難易度ボタンの `GameButtonStyle` の厚みとそろえる）。右下に素数を刻む
    private var blocks: some View {
        let primes = TitleLogoGlyphs.letterPrimes
        let depth = s(5)
        return VStack(spacing: s(8)) {
            ForEach(0..<2, id: \.self) { row in
                let word = row == 0 ? TitleLogoGlyphs.firstWord : TitleLogoGlyphs.secondWord
                HStack(spacing: s(6)) {
                    ForEach(Array(word.enumerated()), id: \.offset) { offset, character in
                        let index = row == 0 ? offset : TitleLogoGlyphs.firstWord.count + offset
                        ZStack(alignment: .bottomTrailing) {
                            RoundedRectangle(cornerRadius: s(9))
                                .fill(Color(uiColor: .systemGray2))
                                .offset(y: depth)
                                .opacity(isDecoration ? 1 : 0)
                            RoundedRectangle(cornerRadius: s(9))
                                .fill(tileFace)
                                .overlay(RoundedRectangle(cornerRadius: s(9)).stroke(Color(uiColor: .systemGray2), lineWidth: s(1.5)))
                                .opacity(isDecoration ? 1 : 0)
                            Text(verbatim: "\(primes[index])")
                                .font(numberFont(10))
                                .foregroundStyle(ink)
                                .padding(.trailing, s(5))
                                .padding(.bottom, s(3))
                                .opacity(isDecoration ? 1 : 0)
                            letter(String(character), size: 32)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(width: s(50), height: s(50))
                    }
                }
            }
        }
        .padding(.bottom, depth)
    }

    // MARK: 9. ウラムの螺旋

    /// 1〜81 をウラムの螺旋に並べ、素数のマスだけを虹で光らせた紋章と、2 段の文字
    private var ulamSpiral: some View {
        let side = 9
        let pitch = s(10)
        let positions = TitleLogoGlyphs.ulamSpiral(side: side)
        var grid = Array(repeating: Array(repeating: 0, count: side), count: side)
        for (number, position) in positions {
            grid[position.row][position.column] = number
        }
        return HStack(spacing: s(14)) {
            VStack(spacing: pitch * 0.2) {
                ForEach(0..<side, id: \.self) { row in
                    HStack(spacing: pitch * 0.2) {
                        ForEach(0..<side, id: \.self) { column in
                            let isPrime = TitleLogoGlyphs.isPrime(grid[row][column])
                            RoundedRectangle(cornerRadius: s(1.5))
                                .fill(isPrime && layer == .letters ? Color.white : Color.primary.opacity(0.1))
                                .frame(width: pitch * 0.8, height: pitch * 0.8)
                                .opacity(isPrime ? (layer == .letters ? 1 : 0) : (isDecoration ? 1 : 0))
                        }
                    }
                }
            }
            .padding(s(6))
            .background(
                RoundedRectangle(cornerRadius: s(6))
                    .stroke(Color.primary.opacity(0.6), lineWidth: s(1.5))
                    .opacity(isDecoration ? 1 : 0)
            )
            VStack(alignment: .leading, spacing: -s(8)) {
                letter("Prime", size: 46)
                letter("Pick", size: 46)
            }
        }
    }

    // MARK: 10. カクロ

    /// カクロの盤。斜線のヒントのマスに、その段の素数の合計（28・72）を書く
    private var kakuro: some View {
        let primes = TitleLogoGlyphs.letterPrimes
        let clues = TitleLogoGlyphs.kakuroClues
        let cell = s(46)
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<2, id: \.self) { row in
                let word = row == 0 ? TitleLogoGlyphs.firstWord : TitleLogoGlyphs.secondWord
                HStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        Rectangle().fill(adaptive(light: 0x3A3A3C, dark: 0x5A5A5E))
                        Path { path in
                            path.move(to: .zero)
                            path.addLine(to: CGPoint(x: cell, y: cell))
                        }
                        .stroke(Color.white.opacity(0.8), lineWidth: s(1))
                        Text(verbatim: "\(clues[row])")
                            .font(numberFont(14))
                            .foregroundStyle(Color.white)
                            .padding(.top, s(4))
                            .padding(.trailing, s(5))
                    }
                    .frame(width: cell, height: cell)
                    .opacity(isDecoration ? 1 : 0)
                    ForEach(Array(word.enumerated()), id: \.offset) { offset, character in
                        let index = row == 0 ? offset : TitleLogoGlyphs.firstWord.count + offset
                        ZStack(alignment: .topLeading) {
                            Rectangle()
                                .fill(tileFace)
                                .opacity(isDecoration ? 1 : 0)
                            Text(verbatim: "\(primes[index])")
                                .font(numberFont(9))
                                .foregroundStyle(ink)
                                .padding(s(3))
                                .opacity(isDecoration ? 1 : 0)
                            letter(String(character), size: 34)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .offset(y: s(2))
                        }
                        .frame(width: cell, height: cell)
                        .overlay(Rectangle().stroke(Color.primary.opacity(0.7), lineWidth: s(1)).opacity(isDecoration ? 1 : 0))
                    }
                }
            }
        }
        .overlay(alignment: .topLeading) {
            // 盤の外枠（2 段目は 1 字少ないので、段ごとに囲む代わりに全体の左と上だけ太くする）
            Rectangle()
                .stroke(Color.primary.opacity(0.8), lineWidth: s(2))
                .frame(width: cell * CGFloat(TitleLogoGlyphs.firstWord.count + 1), height: cell)
                .opacity(isDecoration ? 1 : 0)
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

#if DEBUG
/// 10 案のロゴを並べた一覧（起動引数 `-title-logo-gallery`。DEBUG ビルドだけ）
struct TitleLogoGalleryView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 14) {
                ForEach(TitleLogoCandidate.allCases) { candidate in
                    VStack(spacing: 4) {
                        TitleLogoCandidateView(candidate: candidate, scale: 0.55)
                            .frame(height: 80)
                        Text(verbatim: "\(candidate.rawValue)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 16)
        }
        .background(Color(uiColor: .systemBackground))
    }
}

extension View {
    /// 起動引数 `-title-logo-gallery` があれば、10 案の一覧を全面に出す（DEBUG ビルドだけ）
    func titleLogoGalleryIfRequested() -> some View {
        overlay {
            if TitleLogoCandidate.showsGallery {
                TitleLogoGalleryView()
            }
        }
    }
}

#Preview("10 案") {
    TitleLogoGalleryView()
}

#Preview("Expert の確認のカード") {
    TitleLogoCandidateView(candidate: .sudoku, style: Difficulty.expert.confirmationTitleStyle(reduceMotion: false))
}
#endif
