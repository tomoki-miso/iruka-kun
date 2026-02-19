# DMG 配布 設計

## 概要

`scripts/build-dmg.sh` 一つで「ビルド → .app 生成 → DMG 作成」を完結させる。外部依存なし、macOS 標準の `hdiutil` のみ使用。

## 方針

- **アプローチ**: シェルスクリプト + `hdiutil`（依存ゼロ）
- **コード署名**: 現時点ではアドホック署名。Developer ID 署名・公証は後日対応
- **DMG スタイル**: シンプル（アプリ + Applications シンボリックリンク）

## ビルドフロー

```
xcodegen generate
    ↓
xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKun -configuration Release build
    ↓
build 成果物から iruka-kun.app を取得
    ↓
一時ディレクトリに iruka-kun.app + Applications シンボリックリンクを配置
    ↓
hdiutil create で DMG を生成（UDZO 圧縮）
    ↓
build/IrukaKun-{version}.dmg として出力
```

## 成果物

- **出力先**: `build/IrukaKun-{version}.dmg`
- **DMG 内容**: `iruka-kun.app` + `Applications` へのシンボリックリンク
- **バージョン**: Info.plist の `CFBundleShortVersionString` から自動取得

## スクリプト仕様 (`scripts/build-dmg.sh`)

- `set -euo pipefail` でエラー時に即停止
- XcodeGen でプロジェクト生成
- `xcodebuild` で Release ビルド
- ビルド成果物のパスを `xcodebuild -showBuildSettings` から取得
- 一時ディレクトリにステージング（.app + Applications リンク）
- `hdiutil create` で DMG 生成（UDZO 圧縮）
- 一時ディレクトリのクリーンアップ（trap で確実に実行）

## .gitignore 変更

`build/` ディレクトリを追加して DMG やビルド成果物を除外する。

## 将来の拡張

- Developer ID 署名 + 公証（Notarization）対応
- カスタム背景画像付き DMG
- GitHub Actions での自動ビルド・リリース
