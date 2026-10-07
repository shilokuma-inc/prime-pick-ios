# LEARNINGS（prime-pick-ios 固有）

このリポジトリだけに当てはまる知見。全リポジトリ共通のものは `~/.agents/LEARNINGS.md` に書く。

## App Store の掲載情報（スクリーンショット / メタデータ）

- `PrimePickApp.xcodeproj/project.pbxproj` には `PRODUCT_BUNDLE_IDENTIFIER` がアプリ（`ml.mrs1669.PrimePickApp`）とテスト（`…Tests`）の 2 種類ある。`Tools/app_store_config.py` の `bundle_id()` は productType が application のターゲットの build configuration だけをたどる（ninjacord 由来の「全部集めて 1 つ」の実装だとテストの値が混ざって止まる）（2026-10-05）
- 撮影モード（`-screenshot-demo`）で止める必要があった動き: `gamingText()` の hueRotation（タイトル）、`QuizResultView` の枠色を変える Timer、タイムアタックのカウントダウン。`Tools/capture_screenshots.sh` は連続 2 枚のスクリーンショットが一致するまで待つので、どれか 1 つでも動いていると撮影が落ち着かない（2026-10-05）
- プロジェクトは objectVersion 56（ファイル同期グループ無し）。Swift ファイルを足したら `project.pbxproj` の PBXBuildFile / PBXFileReference / PBXGroup / PBXSourcesBuildPhase に手で登録する（2026-10-05）
