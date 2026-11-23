# LEARNINGS（prime-pick-ios 固有）

このリポジトリだけに当てはまる知見。全リポジトリ共通のものは `~/.agents/LEARNINGS.md` に書く。

## リリース

- リポジトリの設定で「マージしたら head ブランチを自動で消す」（`delete_branch_on_merge`）がオンになっている。`release/<バージョン>` を head にした PR（`develop` に戻す・`main` に反映する）をマージすると、`gh pr merge` に `--delete-branch` を付けなくても release ブランチが消える。消えたら同じコミットで作り直す（`gh api -X POST repos/shilokuma-inc/prime-pick-ios/git/refs -f ref=refs/heads/release/<バージョン> -f sha=<コミット>`）。作り直しは push 扱いで `Upload` が動くので、同じ中身のビルドを上げ直さないよう取り消す。タグ `v<バージョン>` を先に打っておけば、ブランチが消えてもコミットは残る（2026-11-14、#510）

## App Store の掲載情報（スクリーンショット / メタデータ）

- `PrimePickApp.xcodeproj/project.pbxproj` には `PRODUCT_BUNDLE_IDENTIFIER` がアプリ（`ml.mrs1669.PrimePickApp`）とテスト（`…Tests`）の 2 種類ある。`Tools/app_store_config.py` の `bundle_id()` は productType が application のターゲットの build configuration だけをたどる（ninjacord 由来の「全部集めて 1 つ」の実装だとテストの値が混ざって止まる）（2026-10-05）
- 撮影モード（`-screenshot-demo`）で止める必要があった動き: `gamingText()` の hueRotation（タイトル）、`QuizResultView` の枠色を変える Timer、タイムアタックのカウントダウン。`Tools/capture_screenshots.sh` は連続 2 枚のスクリーンショットが一致するまで待つので、どれか 1 つでも動いていると撮影が落ち着かない（2026-10-05）
- 撮影モードを入れた後に足した演出も、撮影モードで止めないと撮れなくなる。コンボの Great（`phaseAnimator` の脈打ち）・MAX（色の回転）がそうで、6 コンボのタイムアタックの画面が「40 秒たっても画面が落ち着きません」で止まった（#440）。繰り返す動きを足したら、`ScreenshotDemo.isEnabled` で止めるか、リリース前に `Tools/capture_screenshots.sh APP_IPHONE_67` を手元で 1 回流して確かめる（2026-10-22）
- App Store Connect のスクリーンショットの取り込みは、同じ画像でもときどき `assetDeliveryState.errors` が `ASSET_FAILED` になる（2026-10-22 の 1.3.0 では、4 サイズとも 3 回続けて、毎回違う画像が失敗した。画像の形式は前回通ったときと同じで、Apple のシステム状況にも障害は出ていなかった）。セットごとやり直すと別の画像がまた失敗するので、`Tools/upload_screenshots.py` は失敗した画像だけを消して上げ直す（#445）。fastlane の deliver も同じやり方をしている
- App Asset Library の画像の参照名（`referenceName`）はライブラリの中で一意。「置き場所 言語 バージョン」だけで名前を付けていたら、同じバージョン（1.3.0）にクリエイティブアセットを上げ直したときに `409 ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE` で止まった。参照名に画像の MD5 の先頭 8 文字を入れ、同じ名前の画像があれば上げ直さずに使う（#500、idfa-vault-ios から移植）（2026-11-11）
- App Store Connect で言語を足すとき、バージョンの言語（`appStoreVersionLocalizations`）を先に作ると、App Store Connect がアプリ情報の言語を今の名前（主言語の名前）で作ろうとする。1.4.0 で en-US を足したとき、今の名前「Prime Pick」が en-US でほかのアプリに使われていて `409 STATE_ERROR.DUPLICATE_NAME.DIFFERENT_ACCOUNT`（Cannot add localization due to app name）で止まった。fastlane の deliver と同じ「バージョン → アプリ情報」の順は、名前を変えるときに通らない。新しい名前でアプリ情報の言語（`appInfoLocalizations`）を先に作る（#538）（2026-11-23）
- 逆に、アプリ情報の言語（`appInfoLocalizations`）を POST すると、App Store Connect はバージョンの言語（`appStoreVersionLocalizations`）も空のまま自動で作る。続けてバージョンの言語を POST すると `409 ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE`（locale already exists. Try updating.）になるので、読み直して PATCH する。また名前は普通の空白以外（フランス語の「?」の前の U+202F など）を `409 ENTITY_ERROR.ATTRIBUTE.INVALID.INVALID_CHARACTERS` で弾く（#540）（2026-11-23）
- App Store Connect は最新情報などの掲載文の絵文字（🟩🟥 など U+10000 以降の文字）を `409 ENTITY_ERROR.ATTRIBUTE.INVALID.INVALID_CHARACTERS`（What's New in This Version can’t contain the following character(s)）で弾く。■（U+25A0）は通った。`Tools/upload_metadata.py --check` で止める（#542）（2026-11-23）
- プロジェクトは objectVersion 56（ファイル同期グループ無し）。Swift ファイルを足したら `project.pbxproj` の PBXBuildFile / PBXFileReference / PBXGroup / PBXSourcesBuildPhase に手で登録する（2026-10-05）

## 広告（AdMob）

- AdMob の ID は `PrimePickApp/AdMob-Debug.xcconfig`（テスト用 ID）と `AdMob-Release.xcconfig`（本番 ID）から `Info.plist` の `$(ADMOB_…)` に差し込む。Release の値は Unit テストでは読めないので、Release 構成でビルドした `.app` の `Info.plist` を `plutil -p` で確かめる（Release のアプリは起動しない）。手順は `docs/ads-release-checklist.md`（2026-10-21）
- xcconfig では `//` から後ろがコメントになる。AdMob の広告ユニット ID（`ca-app-pub-…/…`）は `/` が 1 つなので切れないが、URL などを値に入れるときは注意する（2026-10-21）
- `Tools/capture_screenshots.sh` の既定の構成は Release で、Simulator で起動する。撮影モードでは `AdEligibility` が広告 SDK を動かさないので本番の広告は読み込まないが、撮影モードを外して Release を起動しない（2026-10-21）
- ATT ダイアログを Simulator で撮るとき、ふつうに起動すると先に UMP の説明メッセージ（Continue）が出て、タップできない環境では先に進めない。コミットしない一時的なテストで `ATTrackingManager.requestTrackingAuthorization` を呼ぶと、テストホストのアプリにダイアログが出る。ダイアログはテストが終わっても残るので、撮るたびに Simulator を再起動する。見出しは端末の言語で出るので、`simctl spawn <udid> defaults write 'Apple Global Domain' AppleLanguages` で端末の言語も切り替える（2026-10-21、PR #424）
