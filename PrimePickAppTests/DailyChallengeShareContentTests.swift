//
//  DailyChallengeShareContentTests.swift
//  PrimePickAppTests
//

import UIKit
import XCTest
import QuizCore
@testable import PrimePickApp

final class DailyChallengeShareContentTests: XCTestCase {

    /// 公開日（2026-10-07）から数えて #12 の日
    private let today = DailyChallengeDay(year: 2026, month: 10, day: 18)
    private let startedAt = Date(timeIntervalSince1970: 1_790_000_000)

    // MARK: - 文

    func testTextContainsDayNumberDatePatternScoreTimeAndStreak() throws {
        let content = try XCTUnwrap(makeContent())
        let text = content.text

        XCTAssertTrue(text.contains("#12"), text)
        XCTAssertTrue(text.contains("2026-10-18"), text)
        XCTAssertTrue(text.contains("🟩🟥🟩🟩🟥🟩🟩🟩🟩🟩"), text)
        XCTAssertTrue(text.contains("8/10"), text)
        XCTAssertTrue(text.contains("42.5"), text)
        XCTAssertTrue(text.contains("🔥 2"), text)
        XCTAssertTrue(text.contains("Prime Pick"), text)
    }

    func testValues() throws {
        let content = try XCTUnwrap(makeContent())
        XCTAssertEqual(content.dayNumber, 12)
        XCTAssertEqual(content.dateText, "2026-10-18")
        XCTAssertEqual(content.resultPattern, "🟩🟥🟩🟩🟥🟩🟩🟩🟩🟩")
        XCTAssertEqual(content.correctCount, 8)
        XCTAssertEqual(content.questionCount, 10)
        XCTAssertEqual(content.totalSecondsText, "42.5")
        XCTAssertEqual(content.streak, 2)
    }

    /// 文に出る数字は、通し番号・日付・正解数・問題数・時間・連続日数だけ。問題の数字は入らない
    func testTextDoesNotContainQuizNumbers() throws {
        let content = try XCTUnwrap(makeContent())
        let digitRuns = content.text
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .filter { !$0.isEmpty }
        let expected = ["12", "2026", "10", "18", "8", "10", "42", "5", "2"]
        XCTAssertEqual(digitRuns.sorted(), expected.sorted(), content.text)

        let quizNumbers = DailyChallengeGenerator.v1.makeQuizData(dayKey: today.dayKey).map { "\($0.number)" }
        for number in quizNumbers where !expected.contains(number) {
            XCTAssertFalse(digitRuns.contains(number), number)
        }
    }

    /// リンクは文に入れず、別の URL として返す
    func testURLIsCampaignLinkSeparateFromText() throws {
        let content = try XCTUnwrap(makeContent())
        XCTAssertEqual(
            content.url.absoluteString,
            "https://apps.apple.com/app/apple-store/id6502471694?pt=121319537&ct=daily_share&mt=8"
        )
        let queryItems = URLComponents(url: content.url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(queryItems.first { $0.name == "ct" }?.value, "daily_share")
        XCTAssertFalse(content.text.contains("http"), content.text)
    }

    // MARK: - 共有シートの項目

    /// 文・リンク・画像を別々の項目として渡す
    func testActivityItemsAreTextURLAndImageSeparately() throws {
        let content = try XCTUnwrap(makeContent())
        let image = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { _ in }
        let items = content.activityItems(image: image)

        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0] as? String, content.text)
        XCTAssertEqual(items[1] as? URL, DailyChallengeShareContent.appStoreURL)
        XCTAssertTrue((items[2] as? UIImage) === image)
    }

    /// 画像を作れなかったときも、文とリンクは渡す
    func testActivityItemsWithoutImageAreTextAndURL() throws {
        let content = try XCTUnwrap(makeContent())
        let items = content.activityItems(image: nil)

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0] as? String, content.text)
        XCTAssertEqual(items[1] as? URL, DailyChallengeShareContent.appStoreURL)
    }

    // MARK: - 計測

    func testTapEvent() throws {
        let content = try XCTUnwrap(makeContent())
        XCTAssertEqual(content.tapEvent, .shareTap(dayNumber: 12, correctCount: 8, streak: 2))
        XCTAssertEqual(content.tapEvent.name, "daily_share_tap")
    }

    /// 送り終えたときだけ、共有先付きの完了のイベントを返す
    func testCompleteEventWhenCompleted() throws {
        let content = try XCTUnwrap(makeContent())
        let event = content.completeEvent(activityType: .message, completed: true)
        XCTAssertEqual(event, .shareComplete(dayNumber: 12, activityType: UIActivity.ActivityType.message.rawValue))
        XCTAssertEqual(event?.name, "daily_share_complete")
    }

    /// 共有シートを閉じただけのときは、完了のイベントを送らない
    func testNoCompleteEventWhenDismissed() throws {
        let content = try XCTUnwrap(makeContent())
        XCTAssertNil(content.completeEvent(activityType: nil, completed: false))
        XCTAssertNil(content.completeEvent(activityType: .message, completed: false))
    }

    /// 送り終えたが共有先が分からないときは "unknown" を送る
    func testCompleteEventWithUnknownActivityType() throws {
        let content = try XCTUnwrap(makeContent())
        XCTAssertEqual(
            content.completeEvent(activityType: nil, completed: true),
            .shareComplete(dayNumber: 12, activityType: "unknown")
        )
    }

    // MARK: - 未完了

    func testIncompleteRecordHasNoShareContent() {
        var record = DailyChallengeRecord.started(dayKey: today.dayKey, generatorVersion: 1, questionCount: 10, startedAt: startedAt)
        record.results = [.correct, .incorrect] + Array(repeating: .unanswered, count: 8)
        let result = DailyChallengeResult(record: record, records: [record], today: today)
        XCTAssertNil(DailyChallengeShareContent(result: result))
    }

    // MARK: - ヘルパー

    /// 8/10 正解・42.46 秒・2 日連続の結果
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
