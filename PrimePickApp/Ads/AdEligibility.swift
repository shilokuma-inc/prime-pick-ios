//
//  AdEligibility.swift
//  PrimePickApp
//

import Foundation

/// 広告を出してよいかの判定。広告に加えて、同意フォーム・ATT ダイアログ・広告 SDK の初期化もこの判定に従う
///
/// 撮影モード（スクリーンショットのレイアウトを変えない）・テスト実行中（SDK を動かさない）・
/// AdMob の ID が無いときは出さない。同意（UMP の `canRequestAds`）による判定は別に行う
struct AdEligibility: Equatable {
    /// 撮影モード（`ScreenshotDemo.isEnabled`）で起動している
    let isScreenshotDemo: Bool
    /// XCTest のテストホストとして起動している
    let isRunningTests: Bool
    /// `Info.plist` に AdMob の ID がある
    let hasConfiguration: Bool
    /// 広告を出す置き場所
    let enabledPlacements: Set<AdPlacement>

    init(
        isScreenshotDemo: Bool,
        isRunningTests: Bool,
        hasConfiguration: Bool,
        enabledPlacements: Set<AdPlacement> = AdPlacement.enabled
    ) {
        self.isScreenshotDemo = isScreenshotDemo
        self.isRunningTests = isRunningTests
        self.hasConfiguration = hasConfiguration
        self.enabledPlacements = enabledPlacements
    }

    /// 広告まわり（同意フォーム・ATT・SDK の初期化・広告の読み込み）を動かしてよいか
    var isAdsEnabled: Bool {
        !isScreenshotDemo && !isRunningTests && hasConfiguration
    }

    /// その置き場所に広告（ネイティブ広告）の枠を出してよいか
    func canShowAds(at placement: AdPlacement) -> Bool {
        isAdsEnabled && enabledPlacements.contains(placement)
    }

    /// XCTest はテストホストの環境変数に `XCTestConfigurationFilePath` を入れる
    static func isRunningTests(environment: [String: String]) -> Bool {
        environment["XCTestConfigurationFilePath"] != nil
    }

    static let current = AdEligibility(
        isScreenshotDemo: ScreenshotDemo.isEnabled,
        isRunningTests: isRunningTests(environment: ProcessInfo.processInfo.environment),
        hasConfiguration: AdConfiguration.current != nil
    )
}
