# LEARNINGS（prime-pick-ios 固有）

このリポジトリだけに当てはまる知見。全リポジトリ共通のものは `~/.agents/LEARNINGS.md` に書く。

## App Store の掲載情報（スクリーンショット / メタデータ）

- `PrimePickApp.xcodeproj/project.pbxproj` には `PRODUCT_BUNDLE_IDENTIFIER` がアプリ（`ml.mrs1669.PrimePickApp`）とテスト（`…Tests`）の 2 種類ある。`Tools/app_store_config.py` の `bundle_id()` は productType が application のターゲットの build configuration だけをたどる（ninjacord 由来の「全部集めて 1 つ」の実装だとテストの値が混ざって止まる）（2026-10-05）
- 撮影モード（`-screenshot-demo`）で止める必要があった動き: `gamingText()` の hueRotation（タイトル）、`QuizResultView` の枠色を変える Timer、タイムアタックのカウントダウン。`Tools/capture_screenshots.sh` は連続 2 枚のスクリーンショットが一致するまで待つので、どれか 1 つでも動いていると撮影が落ち着かない（2026-10-05）
- 撮影モードを入れた後に足した演出も、撮影モードで止めないと撮れなくなる。コンボの Great（`phaseAnimator` の脈打ち）・MAX（色の回転）がそうで、6 コンボのタイムアタックの画面が「40 秒たっても画面が落ち着きません」で止まった（#440）。繰り返す動きを足したら、`ScreenshotDemo.isEnabled` で止めるか、リリース前に `Tools/capture_screenshots.sh APP_IPHONE_67` を手元で 1 回流して確かめる（2026-10-22）
- プロジェクトは objectVersion 56（ファイル同期グループ無し）。Swift ファイルを足したら `project.pbxproj` の PBXBuildFile / PBXFileReference / PBXGroup / PBXSourcesBuildPhase に手で登録する（2026-10-05）

## 広告（AdMob）

- AdMob の ID は `PrimePickApp/AdMob-Debug.xcconfig`（テスト用 ID）と `AdMob-Release.xcconfig`（本番 ID）から `Info.plist` の `$(ADMOB_…)` に差し込む。Release の値は Unit テストでは読めないので、Release 構成でビルドした `.app` の `Info.plist` を `plutil -p` で確かめる（Release のアプリは起動しない）。手順は `docs/ads-release-checklist.md`（2026-10-21）
- xcconfig では `//` から後ろがコメントになる。AdMob の広告ユニット ID（`ca-app-pub-…/…`）は `/` が 1 つなので切れないが、URL などを値に入れるときは注意する（2026-10-21）
- `Tools/capture_screenshots.sh` の既定の構成は Release で、Simulator で起動する。撮影モードでは `AdEligibility` が広告 SDK を動かさないので本番の広告は読み込まないが、撮影モードを外して Release を起動しない（2026-10-21）
- ATT ダイアログを Simulator で撮るとき、ふつうに起動すると先に UMP の説明メッセージ（Continue）が出て、タップできない環境では先に進めない。コミットしない一時的なテストで `ATTrackingManager.requestTrackingAuthorization` を呼ぶと、テストホストのアプリにダイアログが出る。ダイアログはテストが終わっても残るので、撮るたびに Simulator を再起動する。見出しは端末の言語で出るので、`simctl spawn <udid> defaults write 'Apple Global Domain' AppleLanguages` で端末の言語も切り替える（2026-10-21、PR #424）
