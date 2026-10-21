# 広告のリリース前に人間がする作業

広告入りの最初のリリース（1.3.0 の想定）を審査に出す前に、コードの外で人間がする作業の一覧です。
元になったのは #369 と Discussion #421 の「手作業が必要なもの」で、epic/admob-production-ids（#422〜#432）の時点の状態を書いています。

- 「済み」「まだ」は、担当者が 2026-10-21 に答えた状況です。済ませたらこのファイルのチェックを付けてください
- 外部の画面の名前・手順は公式のヘルプで確かめたもので、出典の URL を添えています（ヘルプは英語版で確かめました。日本語の画面では表記が違うことがあります）
- プライバシーポリシーの追記案と「App のプライバシー」の回答案は [ads-privacy-drafts.md](ads-privacy-drafts.md) にあります

## まとめ

| 作業 | どこで | 状態 |
| --- | --- | --- |
| 本番 ID の差し替え | リポジトリ（xcconfig） | 済み（#426） |
| テストデバイスの登録 | AdMob | 済み |
| お支払い情報の登録 | AdMob | 済み |
| app-ads.txt の公開 | `https://shilokuma.jp/app-ads.txt` | 済み |
| マーケティング URL を `https://shilokuma.jp` にする | リポジトリ（#429）→ App Store Connect | リポジトリは済み・App Store Connect への反映は**まだ** |
| app-ads.txt タブで「確認済み」になる | AdMob | **まだ**（マーケティング URL の反映・配信の後） |
| GDPR（欧州の規制）のメッセージの作成・公開 | AdMob | **まだ** |
| IDFA の説明メッセージを使うかの判断 | AdMob | **まだ**（任意） |
| プライバシーポリシーの改訂 | `shilokuma-inc/iOS-Release-Sample` | **まだ**（**審査に出す前に**） |
| 「App のプライバシー」の更新 | App Store Connect | **まだ**（**審査に出す前に**） |
| 実機確認 | TestFlight（Release） | **まだ**（#427・#356・#362） |

---

## 1. AdMob の ID（リポジトリ）

- [x] 本番の App ID と、置き場所ごとの 4 つの広告ユニット ID を Release に入れた（#426）

ID は build setting から `PrimePickApp/Info.plist` に差し込んでいます。**値を直すのは次の 2 つの xcconfig だけです**（`Info.plist` には `$(ADMOB_…)` の参照しか書いていません）。

| ファイル | 構成 | 値 |
| --- | --- | --- |
| `PrimePickApp/AdMob-Debug.xcconfig` | Debug（`xcodebuild test`・Xcode からの起動・CI の Build） | Google のテスト用 ID |
| `PrimePickApp/AdMob-Release.xcconfig` | Release（Archive・TestFlight・App Store） | 本番 ID |

| build setting | `Info.plist` のキー | 置き場所（`AdPlacement`） | Release の値 |
| --- | --- | --- | --- |
| `ADMOB_APP_ID` | `GADApplicationIdentifier` | - | `ca-app-pub-7683522872696760~4361548226` |
| `ADMOB_NATIVE_AD_UNIT_ID_QUIZ_RESULT` | `AdMobNativeAdUnitIDQuizResult` | 練習・タイムアタックの結果（`quizResult`） | `ca-app-pub-7683522872696760/3775260254` |
| `ADMOB_NATIVE_AD_UNIT_ID_DAILY_CHALLENGE_RESULT` | `AdMobNativeAdUnitIDDailyChallengeResult` | デイリーチャレンジの結果（`dailyChallengeResult`） | `ca-app-pub-7683522872696760/4356432923` |
| `ADMOB_NATIVE_AD_UNIT_ID_TIME_ATTACK_RECORDS` | `AdMobNativeAdUnitIDTimeAttackRecords` | タイムアタックの記録（`timeAttackRecords`） | `ca-app-pub-7683522872696760/6495511106` |
| `ADMOB_NATIVE_AD_UNIT_ID_SETTING` | `AdMobNativeAdUnitIDSetting` | 設定（`setting`） | `ca-app-pub-7683522872696760/5151921105` |

### ID を変えるとき・置き場所を足すとき

1. 2 つの xcconfig の値を直す（置き場所を足すときは、`AdPlacement` のケース・`AdConfiguration.nativeAdUnitIDKey(for:)`・`Info.plist` のキーと、2 つの xcconfig の build setting を足す）
2. Debug を確かめる: `xcodebuild test`（`AdConfigurationTests` が、テスト用 ID であること・`$(…)` のまま残っていないこと・全部の置き場所に ID があることを確かめる）
3. Release を確かめる: Release 構成でビルドして、`.app` の `Info.plist` の値を見る。**ビルドしたアプリは起動しない**（本番の広告を読み込むと、AdMob の無効なトラフィックになりうる）
   ```bash
   xcodebuild build -project PrimePickApp.xcodeproj -scheme PrimePickApp -configuration Release \
     -destination 'generic/platform=iOS Simulator' -derivedDataPath <リポジトリの外> CODE_SIGNING_ALLOWED=NO
   plutil -p <derivedDataPath>/Build/Products/Release-iphonesimulator/PrimePickApp.app/Info.plist | grep -E 'GADApplicationIdentifier|AdMob'
   ```
   表の値が置き場所どおりに入り、空や `$(…)` のままの値が無いことを確かめる（`GADApplicationIdentifier` が空・不正だと Google Mobile Ads SDK は起動時に落ちる）
4. `develop` に入ると `Upload` ワークフロー（Release）で TestFlight に上がる（`.github/workflows/upload.yml`）。統合ブランチ（`epic/**`）では `archive-working.yml` が Release の Archive を確かめる

- App Store のスクリーンショット（`Tools/capture_screenshots.sh`・`Screenshots/App Store`）は既定で Release を Simulator で起動するが、撮影モードでは `AdEligibility` が広告 SDK を動かさないので本番の広告は読み込まない

## 2. AdMob の管理画面

### GDPR（欧州の規制）のメッセージ — まだ

- [ ] **Privacy & messaging** → **European regulations** のカードの **Create**（2 回目以降は **Manage** → **Create message**）→ **Select apps** で Prime Pick を選んで **Confirm** → 言語・ユーザーの選択肢・対象の地域（Targeting）・メッセージ名・プライバシーポリシーの URL を入れて **Publish**
  - 出典: Create a European regulations message for apps <https://support.google.com/admob/answer/10113207>
  - 対象の地域は「Countries subject to GDPR (EEA, UK, and Switzerland)」か「Everywhere」から選ぶ（同じ出典）。プライバシーポリシーの追記案の地域の書き方（[ads-privacy-drafts.md](ads-privacy-drafts.md) の要確認）を、選んだ地域に合わせる
  - プライバシーポリシーの URL は、設定画面から開くページ `https://shilokuma-inc.github.io/iOS-Release-Sample/PrivacyPolicy/Prime-Pick/PrivacyPolicy.html`（`PrimePickApp/View/Setting/PrivacyPolicyView.swift`）
  - 公開しないと、EU・英国などの利用者に UMP の同意フォームが出ない（Discussion #421）

### IDFA の説明メッセージ — まだ（任意）

- [ ] 使うか決める。使うなら **Privacy & messaging** → **IDFA** → **Create message** → **Select apps** → **Confirm** → 言語・メッセージ名を入れて **Publish**
  - 出典: Create an IDFA message <https://support.google.com/admob/answer/10115331>、About IDFA explainer messages <https://support.google.com/admob/answer/10115027>（ATT のアラートの直前に IDFA の説明を出せる）
  - このアプリは ATT のダイアログを UMP の後にアプリ自身が出す（`PrimePickApp/Ads/GoogleMobileAdsServices.swift` の `ATTrackingManager`）。IDFA の説明メッセージを公開したときに ATT の出方（説明 → ATT が 1 回ずつ出るか）が変わらないかは、公開した後に実機で確かめる（**要確認**）
  - 補足: Debug（Google のテスト用 App ID）で起動すると、ATT の前に「Our app wants to stay free for you」という説明が出る（2026-10-21 に Simulator で確かめた）。これはテスト用 App ID の側の設定によるもので、このアプリの AdMob の設定ではないと思われる（**要確認**）

### テストデバイス — 済み

- [x] 開発・TestFlight で触る iPhone を登録した
- 新しい端末で確かめるときは **Settings** → **Test devices** → **Add test device** で、端末名・プラットフォーム・広告 ID（IDFA）を入れて **Save**
  - 出典: Set up a test device <https://support.google.com/admob/answer/9691433>（テストデバイスには本番の広告がテストモードで届く。反映まで最大 1 時間、場合によっては 24 時間）
- TestFlight のビルドは Release なので本番 ID で広告を読み込む。触るテスターの端末は必ず登録する（自分の広告を見る・タップすると無効なトラフィックになりうる）

### お支払い情報 — 済み

- [x] 登録した（税務情報・振込先）
- 画面: **Payments** → **Set up payments**（入力済みなら **Manage settings**）
  - 出典: Enter your payment details <https://support.google.com/admob/answer/12835021>（税務情報の画面はこのページには書かれていない）

### app-ads.txt タブ — まだ

- [ ] マーケティング URL（下の 4）が App Store に出た後、**Apps** → **View all apps** → **app-ads.txt** タブで、緑の丸（found and verified）になるのを確かめる
  - 出典: Set up an app-ads.txt file for your app <https://support.google.com/admob/answer/9363762>（クロールと確認に最大 24 時間。状態が変わるまで少なくとも 24 時間待つ）、Resolve issues with app-ads.txt <https://support.google.com/admob/answer/9776740>
  - 本番 ID に切り替えても、AdMob がストアの掲載情報と app-ads.txt を確認できるまでは、広告の配信が少なめになることがある（Discussion #421）

## 3. app-ads.txt — 済み

- [x] `https://shilokuma.jp/app-ads.txt` に置いた。中身は次の 1 行（App ID・広告ユニット ID のパブリッシャー ID `7683522872696760` と一致。2026-10-21 に確かめた）
  ```
  google.com, pub-7683522872696760, DIRECT, f08c47fec0942fa0
  ```
- AdMob は、App Store の掲載情報の**マーケティング URL**（Developer Website）のドメインのルートで app-ads.txt を探す。掲載情報に app-ads.txt の URL そのものを書く必要は無い。`www.` と `m.` のサブドメインは除いて探す
  - 出典: Set up an app-ads.txt file for your app <https://support.google.com/admob/answer/9363762>
- サポート URL（`supportUrl`、Google フォーム）は app-ads.txt には関係しない（出典のヘルプはマーケティング URL だけを挙げている）
- ドメインを変えるときは、新しいドメインにも app-ads.txt を置いてからマーケティング URL を変える

## 4. App Store Connect

### マーケティング URL — リポジトリは済み・反映はまだ

- [x] `AppStore/metadata/shared.json` の `marketingUrl` を `https://shilokuma.jp` にした（#429）
- [ ] `Metadata/App Store` ワークフローを `mode: dry-run` で流し、差分が `marketingUrl` だけであることを確かめてから `mode: upload` で流す（`.github/workflows/app-store-metadata.yml`。CLAUDE.md の「App Store の掲載情報」）
  - `upload` が書き込むのは編集中のバージョン（審査前）だけ。marketingUrl はバージョンごとの値なので、配信中の掲載情報が変わるのは、そのバージョンが配信されてから（AdMob の app-ads.txt タブの確認もその後）

### 「App のプライバシー」 — まだ（審査に出す前に）

- [ ] 回答案（[ads-privacy-drafts.md](ads-privacy-drafts.md) の「2. App Store Connect の「App のプライバシー」の回答案」）を確かめて入力する。Device ID を「トラッキングに使用」と答える
  - 入力の手順: Apple のヘルプ Manage app privacy <https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/>
  - 回答案には「要確認」（Firebase Analytics の分など）が残っている。入力の前に決める

### `PrivacyInfo.xcprivacy` の宣言と、審査で指摘されたときの方針

アプリのマニフェスト `PrimePickApp/PrivacyInfo.xcprivacy` は、`NSPrivacyTracking` = true・`NSPrivacyTrackingDomains` は空で出しています（#367 の ask の回答「案1: true・ドメインは空（今のまま）」）。

- Apple のドキュメントでは、`NSPrivacyTracking` を true にしたら `NSPrivacyTrackingDomains` にトラッキングに使うドメインを並べることになっていて、並べたドメインへの通信は ATT で許可していない利用者では失敗する（#367 の ask の説明）
- 審査でドメインが空であることを指摘されたときの方針（#367 の ask の選択肢。どれにするかは指摘の内容を見て人間が決める）:
  1. `NSPrivacyTracking` を false にする（アプリのコード自身はトラッキングしない。IDFA は Google Mobile Ads が扱い、SDK 側のマニフェストが Device ID を「トラッキングあり」と宣言している。「App のプライバシー」は「トラッキングに使用」のまま）
  2. Google の広告ドメインを並べる（ATT を拒否した人には広告そのものが出なくなるおそれがあり、「拒否しても広告は出る」という決定と合わなくなる。Google はトラッキング専用のドメインの一覧を公開していない）
- 変えたら、[ads-privacy-drafts.md](ads-privacy-drafts.md) の回答案の該当の記述も直す

## 5. プライバシーポリシー — まだ（審査に出す前に）

- [ ] [ads-privacy-drafts.md](ads-privacy-drafts.md) の「1. プライバシーポリシーの追記案」を確かめ、`shilokuma-inc/iOS-Release-Sample` の `PrivacyPolicy/Prime-Pick/PrivacyPolicy.html` に反映する（法的な確認は人間がする）
  - 追記案には「要確認」（同意を求める地域・雛形の記述など）が残っている
  - GDPR のメッセージに入れるプライバシーポリシーの URL は、このページ

## 6. 実機確認 — まだ

- [ ] #427: 本番 ID の Release（TestFlight）のビルドで、4 か所の広告・UMP / ATT が出ること・AdMob のレポートで 4 つの広告ユニットに分かれること
- [ ] #356: 起動時の UMP の同意フォームと ATT ダイアログ（本番 ID のビルドでも確かめる）
- [ ] #362: 設定の「プライバシー設定」（本番 ID のビルドでも確かめる）
- [ ] #359・#365（バナーの確認）: バナーはネイティブ広告に置き換えた（#377・#386・#389）ので、不要になっている可能性が高い。閉じるかは人間が決める
- EU の確かめ方は UMP のデバッグ設定（テストデバイスと地域の指定）を使う（Discussion #421）。コードには入れていない
