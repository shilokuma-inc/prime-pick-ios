//
//  DailyChallengeShareCardTests.swift
//  PrimePickAppTests
//

import XCTest
import QuizCore
@testable import PrimePickApp

final class DailyChallengeShareCardTests: XCTestCase {

    private let today = DailyChallengeDay(year: 2026, month: 10, day: 18)
    private let startedAt = Date(timeIntervalSince1970: 1_790_000_000)

    /// 書き出した画像は正方形（1080x1080 px）
    @MainActor
    func testRenderedImageIsSquare() throws {
        let content = try XCTUnwrap(makeContent())
        let image = try XCTUnwrap(DailyChallengeShareCardView.renderImage(content: content))

        XCTAssertEqual(image.size.width, image.size.height)
        let cgImage = try XCTUnwrap(image.cgImage)
        XCTAssertEqual(cgImage.width, cgImage.height)
        XCTAssertEqual(cgImage.width, 1080)
    }

    // MARK: - ヘルパー

    /// 8/10 正解・2 日連続の結果
    private func makeContent() -> DailyChallengeShareContent? {
        var record = completedRecord(dayKey: today.dayKey)
        record.results = [.correct, .incorrect, .correct, .correct, .incorrect] + Array(repeating: .correct, count: 5)
        record.totalAnswerSeconds = 42.46
        let yesterday = completedRecord(dayKey: today.adding(days: -1).dayKey)
        return DailyChallengeShareContent(result: DailyChallengeResult(record: record, records: [yesterday, record], today: today))
    }

    private func completedRecord(dayKey: String) -> DailyChallengeRecord {
        var record = DailyChallengeRecord.started(dayKey: dayKey, generatorVersion: 1, questionCount: 10, startedAt: startedAt)
        record.results = Array(repeating: .correct, count: 10)
        record.completedAt = startedAt.addingTimeInterval(60)
        return record
    }
}
