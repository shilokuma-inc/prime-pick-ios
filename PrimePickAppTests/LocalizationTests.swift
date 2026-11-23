//
//  LocalizationTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

/// 言語の選ばれ方と、地域で言い方が違う訳（#532）
final class LocalizationTests: XCTestCase {

    private func localization(for preferences: [String]) -> String? {
        Bundle.preferredLocalizations(from: Bundle.main.localizations, forPreferences: preferences).first
    }

    private func string(_ key: String, in localization: String) throws -> String {
        let path = try XCTUnwrap(Bundle.main.path(forResource: localization, ofType: "lproj"), localization)
        return try XCTUnwrap(Bundle(path: path), localization).localizedString(forKey: key, value: nil, table: nil)
    }

    /// スペインの端末はスペイン向けの訳（es-ES）、メキシコ・中南米・米国のスペイン語は es を使う
    func testSpanishRegionsPickTheirLocalization() {
        XCTAssertEqual(localization(for: ["es-ES"]), "es-ES")
        XCTAssertEqual(localization(for: ["es-MX"]), "es")
        XCTAssertEqual(localization(for: ["es-419"]), "es")
        XCTAssertEqual(localization(for: ["es-US"]), "es")
    }

    /// スペインの iOS は「Ajustes」、メキシコなどの iOS は「Configuración」
    func testSpainSpanishUsesSpainTerms() throws {
        XCTAssertEqual(try string("Settings", in: "es-ES"), "Ajustes")
        XCTAssertEqual(try string("Settings", in: "es"), "Configuración")
        XCTAssertEqual(try string("Privacy Settings", in: "es-ES"), "Ajustes de privacidad")
    }

    /// 訳の無い言語の端末は英語にする（開発言語）
    func testUnsupportedLanguageFallsBackToEnglish() {
        XCTAssertEqual(localization(for: ["ru-RU"]), "en")
    }

    /// 画面の文字列（`Localizable.xcstrings`）は、英語にあるものがどの言語にもある（#535）
    ///
    /// 訳の無い文字列は、その言語の端末で黙って英語のまま出る。機能を足すときに訳し漏れても気づけるよう、
    /// 書き出された `Localizable.strings`（単数・複数で形が変わるものは `Localizable.stringsdict`）のキーを比べる
    func testEveryLanguageHasEveryString() throws {
        let english = try stringKeys(in: "en")
        XCTAssertFalse(english.isEmpty)
        for localization in Bundle.main.localizations where localization != "Base" && localization != "en" {
            let missing = english.subtracting(try stringKeys(in: localization)).sorted()
            XCTAssertEqual(missing, [], "\(localization) に訳がありません")
        }
    }

    private func stringKeys(in localization: String) throws -> Set<String> {
        let path = try XCTUnwrap(Bundle.main.path(forResource: localization, ofType: "lproj"), localization)
        let bundle = try XCTUnwrap(Bundle(path: path), localization)
        return ["strings", "stringsdict"].reduce(into: Set<String>()) { keys, type in
            guard let file = bundle.path(forResource: "Localizable", ofType: type),
                  let table = NSDictionary(contentsOfFile: file) as? [String: Any] else { return }
            keys.formUnion(table.keys)
        }
    }
}
