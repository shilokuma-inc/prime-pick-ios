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
}
