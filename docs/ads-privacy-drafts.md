# 広告まわりのプライバシーの文案（プライバシーポリシーの追記案・「App のプライバシー」の回答案）

広告入りの 1.3.0（Google Mobile Ads のネイティブ広告・UMP の同意・ATT）を審査に出す前に、人間が反映するための**案**です。

- この文書はリリース前の確認に使う案です。**法的な確認は人間が行ってください。** そのまま公開してよいと判断したものではありません
- 反映するのは人間です（ループ・この PR では、プライバシーポリシーのページも App Store Connect も変えていません）
  - プライバシーポリシーのページ: `shilokuma-inc/iOS-Release-Sample` の `PrivacyPolicy/Prime-Pick/PrivacyPolicy.html`（公開先 <https://shilokuma-inc.github.io/iOS-Release-Sample/PrivacyPolicy/Prime-Pick/PrivacyPolicy.html>）
  - 「App のプライバシー」: App Store Connect のアプリのページ
- 公式の文書・SDK のプライバシーマニフェストで確かめた点には出典を付けました。確かめられなかった点・食い違う点は **「要確認」** と書いています
- 調べた日: 2026-10-21（このリポジトリの epic/admob-production-ids の時点。SDK の版は下の「前提」）

## 前提（このアプリが使う SDK）

`PrimePickApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` と、Release 構成でビルドした `.app` の `Frameworks/` で確かめました。

| SDK | 版 | アプリでの使い方 |
| --- | --- | --- |
| Google Mobile Ads（`swift-package-manager-google-mobile-ads`） | 13.11.0 | 4 か所のネイティブ広告（`PrimePickApp/Ads/`、`AdPlacement`） |
| Google User Messaging Platform（UMP） | 3.1.0 | 起動時の同意（EU・英国など）と、設定の「プライバシー設定」（`PrivacyOptions.swift`）。ATT ダイアログはアプリが `ATTrackingManager` で直接出す（`GoogleMobileAdsServices.swift`）。UMP の IDFA の説明メッセージを使うかは未定 |
| Firebase Analytics（`firebase-ios-sdk` の `FirebaseAnalytics`。`GoogleAppMeasurement` 11.15.0） | 11.15.0 | 画面の表示・出題の開始・解答・デイリーチャレンジのイベント（`PrimePickApp/Analytics/`） |

- ビルドした `.app`（Debug・Release とも同じ）の `Frameworks/` には `GoogleMobileAds`・`UserMessagingPlatform`・`FirebaseAnalytics`・`GoogleAppMeasurement`・`GoogleAppMeasurementIdentitySupport`・`GoogleAdsOnDeviceConversion` が入っている
- アプリ自身は位置情報・連絡先・写真などを読まない。保存は端末の `UserDefaults`（記録・設定）だけ（`PrimePickApp/PrivacyInfo.xcprivacy`）
- ATT ダイアログの文言（`NSUserTrackingUsageDescription`、PR #424）
  - ja: 許可すると、ほかのアプリやWebサイトでの利用状況をもとに、興味に合った広告が表示されやすくなります。許可しなくても広告は表示されます。
  - en: Allowing tracking helps us show ads that better match your interests, based on your activity in other apps and websites. You'll still see ads if you don't allow it.

---

## 1. プライバシーポリシーの追記案

### 今のページ（2026-10-21 に読んだもの）

- 英語だけのページ。見出しは `Information Collection and Use` / `Third Party Access` / `Opt-Out Rights` / `Data Retention Policy` / `Children` / `Security` / `Changes` / `Your Consent` / `Contact Us`
- 「This privacy policy is effective as of 2024-05-22」と書かれている（`Changes` の節）
- 広告・Google Mobile Ads・UMP・ATT・広告 ID（IDFA）についての記述は無い
- 連絡先は `Contact Us` の節のメールアドレス（この文書には書き写さない）

追記案は、今のページと同じく英語で、同じ書き方（`the Application` / `the Service Provider` と呼ぶ）にしています。
下の差分は読みやすさのため Markdown で書いています。元のページは HTML なので、反映するときは箇条書きを `<li>…</li>`、節の見出しを `<strong>…</strong>`、段落を `<p>…</p>` に置き換えてください（今のページの書き方に合わせる）。

### 追記の場所と文案

**(1) `Information Collection and Use` の箇条書きの後に足す**

```diff
 * The time spent on the Application
 * The operating system you use on your mobile device
+* Identifiers for advertising, such as your device's advertising identifier (IDFA, only if you allow tracking) and other device or app identifiers
+* Information about the ads you see and how you interact with them
+* Crash logs and performance data, used to diagnose problems
```

**(2) `Third Party Access` の後に、新しい節 `Advertising` を足す**

```diff
+**Advertising**
+
+The Application displays ads provided by Google AdMob (Google Mobile Ads SDK). To show ads and measure their performance, Google may collect and use information such as your device's advertising identifier or other identifiers, your IP address (which may be used to estimate your approximate location), and information about the ads you see and your interactions with them.
+
+For information about how Google uses this information, see "How Google uses information from sites or apps that use our services": https://policies.google.com/technologies/partner-sites
+
+App Tracking Transparency: The Application asks for your permission before accessing your device's advertising identifier (IDFA). If you don't allow tracking, the Google Mobile Ads SDK does not send the IDFA in ad requests, and you will still see ads. You can change this choice at any time in your device's Settings > Privacy & Security > Tracking.
+
+Consent in the EEA, the UK and Switzerland: In some regions, the Application uses Google's User Messaging Platform to ask for your consent to the use of your data for ads. You can review or change your choice at any time from "Privacy Settings" on the Application's settings screen.
+
+The Application also uses Google Analytics for Firebase to understand how the Application is used (for example, screens viewed and quizzes played).
```

**(3) `Opt-Out Rights` の末尾に足す**

```diff
 You can stop all collection of information by the Application easily by uninstalling it. ...
+You can also stop the Application from accessing your device's advertising identifier by turning off tracking for the Application in your device's Settings > Privacy & Security > Tracking, and, where available, change your ad consent choices from "Privacy Settings" on the Application's settings screen.
```

**(4) `Changes` の日付を、改訂した日に直す**

```diff
-This privacy policy is effective as of 2024-05-22
+This privacy policy is effective as of <改訂した日（YYYY-MM-DD）>
```

### 文案の根拠

| 文案の内容 | 根拠 |
| --- | --- |
| 広告 ID・その他の識別子・IP アドレス（おおよその位置の推定）・見た広告と操作・クラッシュとパフォーマンスのデータを Google Mobile Ads が集める | Google Mobile Ads SDK の App Store のデータ開示 <https://developers.google.com/admob/ios/privacy/data-disclosure>（IP address は「may be used to estimate the general location of a device」、Device ID は「advertising identifier, or app- or developer-bounded identifier」） |
| Google のポリシーへのリンク | Google パブリッシャー ポリシーの「Privacy disclosures」<https://support.google.com/publisherpolicies/answer/10502938>。プライバシーポリシーでデータの収集・共有・利用（cookies・IP アドレス・その他の識別子を含む）を開示することが求められ、「How Google uses data when you use our partners' sites or apps」へのリンクを目立つように置くことは option（任意）とされている。リンク先 <https://policies.google.com/technologies/partner-sites>（英語のページ名「How Google uses information from sites or apps that use our services」） |
| ATT で拒否しても広告は出て、IDFA は送られない | AdMob の IDFA の説明メッセージのページ <https://developers.google.com/admob/ios/privacy/idfa>（「If a user denies ATT, continue to request ads ... The Google Mobile Ads SDK doesn't send IDFA in the ad request.」） |
| トラッキングの設定の場所 | Apple「If an app asks to track your activity」<https://support.apple.com/en-us/102420>（Settings > Privacy & Security > Tracking。日本語版 <https://support.apple.com/ja-jp/102420> では「設定」>「プライバシーとセキュリティ」>「トラッキング」） |
| 設定の「Privacy Settings」（日本語の表示は「プライバシー設定」）で同意をやり直せる | このリポジトリの `PrimePickApp/View/Setting/SettingView.swift`・`PrimePickApp/Ads/PrivacyOptions.swift`（UMP がプライバシー オプションを必要とする利用者にだけ出す） |

### 要確認（人間が決めること・確かめること）

- **同意が求められる地域の書き方**（「the EEA, the UK and Switzerland」）: UMP のどのメッセージをどの地域に出すかは AdMob の管理画面の設定による（GDPR メッセージはまだ作成・公開していない）。公開した設定に合わせて直す。**要確認**
- **今のページの非表示の記述**: `Information Collection and Use` の「The Application collects your device's location ...」（位置情報を集めて Geolocation Services などに使う）の段落は、HTML の `<div style="display: none;">` の中にあり、ページには表示されていない（表示されているのは「The Application does not gather precise information about the location of your mobile device.」だけ）。生成ツールの雛形がソースに残っていると思われる。改訂のついでに消すかは人間が決める。**要確認**
- **今のページの雛形の記述**: 「The Service Provider may use the information you provided to contact you ... marketing promotions」「may require you to provide us with certain personally identifiable information」は、アプリが連絡先などを集めないこと（下の回答案で Contact Info を「集めない」としている）と合わない。直すかは人間が決める。**要確認**
- **Firebase Analytics の書き方**: 文案は「使い方を知るため」だけを書いている。Google Analytics はマスクした IP アドレスからおおよその位置を出し、`.app` に IDFA を扱う部品（`GoogleAppMeasurementIdentitySupport`）が入っている（下の「App のプライバシー」の要確認）。識別子・おおよその位置もポリシーに書くか、Firebase のプライバシーの案内へのリンクを付けるかは**要確認**
- **Analytics と同意**: Firebase Analytics は UMP の同意に関係なく送っている（Consent Mode の設定は無い）。文案の同意の段落は「広告のための同意」に限っているので約束とは食い違わないが、EU の同意のポリシー（Google パブリッシャー ポリシーが従うよう求める EU user consent policy）の下で Analytics をどう扱うかは**要確認**
- `Third Party Access` の「Only aggregated, anonymized data is periodically transmitted to external services」は、広告 SDK が識別子を Google に送ることと合わない。`Advertising` の節を足すときに合わせて直すかを決める。**要確認**
- `Children`: 子ども向けの扱い（Google Mobile Ads の子ども向けのタグ）は付けていない（PR #355 の時点の判断）。年齢区分と合わせて確かめる。**要確認**
- ページを日本語でも用意するか（今は英語だけ）。**要確認**

---

## 2. App Store Connect の「App のプライバシー」の回答案

Apple は、アプリに入れたサードパーティの SDK（広告ネットワーク・解析ツールなど）が集めるデータも開示するよう求めています（Apple「App privacy details on the App Store」<https://developer.apple.com/app-store/app-privacy-details/>）。
入力の手順は Apple のヘルプ <https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/> を参照してください（画面の名前はこの文書では確かめていません。**要確認**）。

### 根拠にしたもの

- **Google Mobile Ads・UMP**: SDK に入っているプライバシーマニフェスト（`GoogleMobileAds.framework/PrivacyInfo.xcprivacy`・`UserMessagingPlatform.framework/PrivacyInfo.xcprivacy`。上の版のもの）。Google は「マニフェストを確かめ、アプリのデータの開示を最新に保つのは開発者の責任」としている（<https://developers.google.com/admob/ios/privacy/data-disclosure>）
- **Firebase Analytics**: Google Analytics の「Prepare for Apple's App Store data-disclosure requirements」<https://support.google.com/analytics/answer/10285841>。この記事には「The latest version of the Google Analytics for Firebase SDK ... does not include a privacy manifest」とあり、ビルドした `.app` の `GoogleAppMeasurement` にもマニフェストは無かった。Apple の分類での表も無い
- Firebase の SDK（FirebaseCore・FirebaseInstallations など）のマニフェスト: FirebaseInstallations が Other Diagnostic Data（紐付けなし・トラッキングなし・Analytics）を宣言（SDK のマニフェスト `firebase-ios-sdk/FirebaseInstallations/Source/Library/Resources/PrivacyInfo.xcprivacy`。Firebase の案内 <https://firebase.google.com/docs/ios/app-store-data-collection> は、マニフェストが既定で集めるものを開示していること、実際の使い方に合わせて正しく答えるのは開発者の責任であることを書いている）

### SDK ごとの宣言（マニフェストの値）

ビルドした `.app` に入っている SDK のマニフェストだけを載せています（依存のパッケージにあっても `.app` に入らないもの、例えば GoogleDataTransport は載せていません）。

| SDK | データの種類 | 目的 | ユーザーへの紐付け | トラッキング |
| --- | --- | --- | --- | --- |
| Google Mobile Ads | Identifiers > Device ID | Third-Party Advertising / Developer's Advertising or Marketing / Analytics | あり | **あり** |
| Google Mobile Ads | Location > Coarse Location | Third-Party Advertising / Developer's Advertising or Marketing / Analytics | あり | なし |
| Google Mobile Ads | Usage Data > Product Interaction | Third-Party Advertising / Developer's Advertising or Marketing / Analytics | あり | なし |
| Google Mobile Ads | Usage Data > Advertising Data | Third-Party Advertising / Developer's Advertising or Marketing / Analytics | あり | なし |
| Google Mobile Ads | Diagnostics > Crash Data | Analytics | なし | なし |
| Google Mobile Ads | Diagnostics > Performance Data | Third-Party Advertising / Developer's Advertising or Marketing / Analytics | なし | なし |
| Google Mobile Ads | Diagnostics > Other Diagnostic Data | Third-Party Advertising / Developer's Advertising or Marketing / Analytics | なし | なし |
| UMP | Location > Coarse Location | App Functionality | なし | なし |
| UMP | Usage Data > Product Interaction | App Functionality | なし | なし |
| UMP | Diagnostics > Performance Data | App Functionality | なし | なし |
| FirebaseInstallations | Diagnostics > Other Diagnostic Data | Analytics | なし | なし |
| Firebase Analytics | （マニフェスト無し。下の「要確認」） | | | |

### 回答案（データの種類ごとにまとめたもの）

App Store Connect では、データの種類ごとに「目的」「ユーザーに紐付けるか」「トラッキングに使うか」を答えます。上の表の SDK の宣言をデータの種類ごとにまとめ、1 つでも「あり」なら「あり」にしました。

| データの種類 | 集める | 目的 | ユーザーへの紐付け | トラッキング |
| --- | --- | --- | --- | --- |
| Identifiers > Device ID | はい | Third-Party Advertising / Developer's Advertising or Marketing / Analytics | はい | **はい** |
| Location > Coarse Location | はい | Third-Party Advertising / Developer's Advertising or Marketing / Analytics / App Functionality | はい | いいえ |
| Usage Data > Product Interaction | はい | Third-Party Advertising / Developer's Advertising or Marketing / Analytics / App Functionality | はい | いいえ |
| Usage Data > Advertising Data | はい | Third-Party Advertising / Developer's Advertising or Marketing / Analytics | はい | いいえ |
| Diagnostics > Crash Data | はい | Analytics | いいえ | いいえ |
| Diagnostics > Performance Data | はい | Third-Party Advertising / Developer's Advertising or Marketing / Analytics / App Functionality | いいえ | いいえ |
| Diagnostics > Other Diagnostic Data | はい | Third-Party Advertising / Developer's Advertising or Marketing / Analytics | いいえ | いいえ |

上の表に無いもの（Contact Info・Health & Fitness・Financial Info・Precise Location・Sensitive Info・Contacts・User Content・Browsing History・Search History・User ID・Purchases など）は、アプリも SDK のマニフェストも集めると宣言していないので「集めない」の案です。

- 「トラッキング」の定義: アプリで集めたデータを、ほかの会社のアプリ・Web サイトなどのデータと、ターゲティング広告や広告の測定のために結び付けること、またはデータブローカーと共有すること（Apple「User privacy and data use」<https://developer.apple.com/app-store/user-privacy-and-data-use/>）。Device ID を「トラッキングに使う」と答えるので、ATT の許可を求める今の実装と、アプリのマニフェスト `PrimePickApp/PrivacyInfo.xcprivacy` の `NSPrivacyTracking` = true（SDK のマニフェストにはこのキーは無い）と合う

### 要確認（人間が決めること・確かめること）

- **Firebase Analytics の分**: マニフェストが無く、Google Analytics の記事にも Apple の分類での表が無い。記事で確かめられたのは次のとおりで、どの種類に当てはめるかは**要確認**
  - app instance id をアプリのインスタンスごとに割り当てる（既定では user ID・広告 ID と結び付けない）→ Identifiers > Device ID か（**要確認**）
  - 画面の表示・セッションなどのイベント → Usage Data > Product Interaction（Analytics）か（**要確認**）
  - Location Services は使わず、マスクした IP アドレスからおおよその位置を出す → Location > Coarse Location（Analytics）か（**要確認**）
  - 記事は「AdSupport.framework をリンクする」「Google Signals」などを追加の開示が要る機能に挙げている。ビルドした `.app` には `GoogleAppMeasurementIdentitySupport` が入っているので、Analytics が IDFA を扱う可能性がある（**要確認**。Firebase の「Configure Analytics data collection and usage」<https://firebase.google.com/docs/analytics/configure-data-collection?platform=ios> の「Disable IDFA collection」に、AdSupport を含めない方法として `FirebaseAnalyticsCore` を使う手順がある）。Google Signals を有効にしているかは Firebase / Google Analytics の管理画面で確かめる
- **Developer's Advertising or Marketing**: Google Mobile Ads のマニフェストが宣言している目的。アプリ自身は自社の広告・マーケティングをしていないが、SDK の宣言に合わせて含めた。外すかは**要確認**
- **Performance Data の紐付け**: Google の文書は「User-associated performance data」と書いているが、SDK のマニフェストは紐付けなし（`NSPrivacyCollectedDataTypeLinked` = false）。食い違うので**要確認**
- `GoogleAdsOnDeviceConversion` が `.app` に入っている（Firebase Analytics の依存）。マニフェストは見つからなかった。**要確認**
- SDK を更新したら、マニフェストを読み直して回答を見直す（Google はマニフェストの確認を開発者の責任としている）
