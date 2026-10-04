//
//  LicenseListTests.swift
//  PrimePickAppTests
//

import LicenseList
import XCTest

final class LicenseListTests: XCTestCase {

    /// Package.resolved が読めていれば、Firebase の推移的依存も含めてライセンス一覧に載る
    func testLibrariesIncludeResolvedPackages() {
        let names = Set(Library.libraries.map(\.name))
        let expected: Set<String> = [
            "LicenseList",
            "firebase-ios-sdk",
            "abseil-cpp-binary",
            "grpc-binary",
            "leveldb",
            "nanopb",
            "promises",
            "swift-protobuf",
            "GoogleUtilities"
        ]
        XCTAssertTrue(expected.isSubset(of: names), "不足: \(expected.subtracting(names))")
    }

    func testEveryLibraryHasLicenseBody() {
        for library in Library.libraries {
            XCTAssertFalse(library.licenseBody.isEmpty, "\(library.name) のライセンス本文が空")
        }
    }
}
