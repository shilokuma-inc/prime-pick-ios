//
//  AdsStartupTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

@MainActor
final class AdsStartupTests: XCTestCase {

    /// 呼ばれた順を記録する
    private final class CallLog {
        var calls: [String] = []
    }

    private struct ConsentError: Error {}

    private final class FakeConsent: AdConsentGathering {
        let log: CallLog
        var canRequestAds: Bool
        var error: Error?

        init(log: CallLog, canRequestAds: Bool = true, error: Error? = nil) {
            self.log = log
            self.canRequestAds = canRequestAds
            self.error = error
        }

        func gatherConsent() async throws {
            log.calls.append("consent")
            if let error {
                throw error
            }
        }
    }

    private final class FakeTracking: TrackingAuthorizationRequesting {
        let log: CallLog
        init(log: CallLog) { self.log = log }

        func requestAuthorizationIfNeeded() async {
            log.calls.append("tracking")
        }
    }

    private final class FakeMobileAds: MobileAdsStarting {
        let log: CallLog
        init(log: CallLog) { self.log = log }

        func start() async {
            log.calls.append("start")
        }
    }

    private func makeStartup(
        log: CallLog,
        eligibility: AdEligibility = AdEligibility(isScreenshotDemo: false, isRunningTests: false, hasConfiguration: true),
        consent: FakeConsent? = nil
    ) -> AdsStartup {
        AdsStartup(
            eligibility: eligibility,
            consent: consent ?? FakeConsent(log: log),
            tracking: FakeTracking(log: log),
            mobileAds: FakeMobileAds(log: log)
        )
    }

    func testRunsConsentThenTrackingThenSDKStart() async {
        let log = CallLog()
        let startup = makeStartup(log: log)

        await startup.startIfNeeded()

        XCTAssertEqual(log.calls, ["consent", "tracking", "start"])
        XCTAssertTrue(startup.isReadyToLoadAds)
    }

    func testIsNotReadyBeforeStart() {
        XCTAssertFalse(makeStartup(log: CallLog()).isReadyToLoadAds)
    }

    /// 同意が得られていないあいだは ATT も SDK の初期化もしない
    func testStopsWhenAdsCannotBeRequested() async {
        let log = CallLog()
        let startup = makeStartup(log: log, consent: FakeConsent(log: log, canRequestAds: false))

        await startup.startIfNeeded()

        XCTAssertEqual(log.calls, ["consent"])
        XCTAssertFalse(startup.isReadyToLoadAds)
    }

    /// 同意情報の更新に失敗しても、前回までの同意で広告を出せるなら続ける
    func testContinuesWithPreviousConsentWhenGatheringFails() async {
        let log = CallLog()
        let startup = makeStartup(log: log, consent: FakeConsent(log: log, canRequestAds: true, error: ConsentError()))

        await startup.startIfNeeded()

        XCTAssertEqual(log.calls, ["consent", "tracking", "start"])
        XCTAssertTrue(startup.isReadyToLoadAds)
    }

    func testStopsWhenGatheringFailsWithoutConsent() async {
        let log = CallLog()
        let startup = makeStartup(log: log, consent: FakeConsent(log: log, canRequestAds: false, error: ConsentError()))

        await startup.startIfNeeded()

        XCTAssertEqual(log.calls, ["consent"])
        XCTAssertFalse(startup.isReadyToLoadAds)
    }

    /// 撮影モード・テスト実行中は同意フォーム・ATT・SDK のどれも動かさない
    func testDoesNothingWhenAdsAreDisabled() async {
        let disabled = [
            AdEligibility(isScreenshotDemo: true, isRunningTests: false, hasConfiguration: true),
            AdEligibility(isScreenshotDemo: false, isRunningTests: true, hasConfiguration: true),
            AdEligibility(isScreenshotDemo: false, isRunningTests: false, hasConfiguration: false)
        ]
        for eligibility in disabled {
            let log = CallLog()
            let startup = makeStartup(log: log, eligibility: eligibility)

            await startup.startIfNeeded()

            XCTAssertEqual(log.calls, [], "\(eligibility)")
            XCTAssertFalse(startup.isReadyToLoadAds)
        }
    }

    /// アクティブになるたびに呼ばれても、同意フォームと ATT は 1 回だけ
    func testRunsOnlyOnce() async {
        let log = CallLog()
        let startup = makeStartup(log: log)

        await startup.startIfNeeded()
        await startup.startIfNeeded()

        XCTAssertEqual(log.calls, ["consent", "tracking", "start"])
    }

    /// テストホストのアプリは、実際の SDK につないだものでも広告まわりを動かさない
    func testLiveStartupDoesNothingWhileRunningTests() async {
        let startup = AdsStartup.live()

        await startup.startIfNeeded()

        XCTAssertFalse(startup.isReadyToLoadAds)
    }

    func testTrackingUsageDescriptionIsInInfoPlist() {
        let description = Bundle.main.infoDictionary?["NSUserTrackingUsageDescription"] as? String
        XCTAssertFalse(description?.isEmpty ?? true)
    }
}
