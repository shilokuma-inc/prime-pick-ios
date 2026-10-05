# prime-pick-ios
素数クイズアプリ

## Environment
- Xcode 26.3
- iOS 17.0+

## Status

| branch \ workflow | Build | Archive | Upload |
| --- | --- | --- | --- |
| main | [![Build/main](https://github.com/shilokuma-inc/prime-pick-ios/actions/workflows/build-main.yml/badge.svg)](https://github.com/shilokuma-inc/prime-pick-ios/actions/workflows/build-main.yml) | [![Archive/main](https://github.com/shilokuma-inc/prime-pick-ios/actions/workflows/archive-main.yml/badge.svg)](https://github.com/shilokuma-inc/prime-pick-ios/actions/workflows/archive-main.yml) | |
| develop | [![Build/develop](https://github.com/shilokuma-inc/prime-pick-ios/actions/workflows/build-develop.yml/badge.svg)](https://github.com/shilokuma-inc/prime-pick-ios/actions/workflows/build-develop.yml) | [![Archive/develop](https://github.com/shilokuma-inc/prime-pick-ios/actions/workflows/archive-develop.yml/badge.svg)](https://github.com/shilokuma-inc/prime-pick-ios/actions/workflows/archive-develop.yml) | [![Upload/develop](https://github.com/shilokuma-inc/prime-pick-ios/actions/workflows/upload-develop.yml/badge.svg)](https://github.com/shilokuma-inc/prime-pick-ios/actions/workflows/upload-develop.yml) |

## App Store の掲載情報

スクリーンショットと説明文は、手動で発火する GitHub Actions で App Store Connect の編集中バージョンに反映する（詳しくは [CLAUDE.md](CLAUDE.md) の「App Store の掲載情報」）。

| workflow | 内容 |
| --- | --- |
| [![Screenshots/App Store](https://github.com/shilokuma-inc/prime-pick-ios/actions/workflows/app-store-screenshots.yml/badge.svg)](https://github.com/shilokuma-inc/prime-pick-ios/actions/workflows/app-store-screenshots.yml) | スクリーンショットを撮って反映する（`AppStore/screenshots.json`） |
| [![Metadata/App Store](https://github.com/shilokuma-inc/prime-pick-ios/actions/workflows/app-store-metadata.yml/badge.svg)](https://github.com/shilokuma-inc/prime-pick-ios/actions/workflows/app-store-metadata.yml) | 説明文・キーワード・URL を反映する（`AppStore/metadata/*.json`。既定は dry-run） |
