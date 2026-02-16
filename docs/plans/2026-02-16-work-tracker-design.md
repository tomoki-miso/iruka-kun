# 作業時間トラッカー設計

## 概要

iruka-kun に作業時間トラッカー機能を追加する。メニューバーにリアルタイムで経過時間を表示し、手動の開始/停止と自動休止を組み合わせて作業時間を計測する。日別の履歴を UserDefaults に保存する。

## アーキテクチャ

### 新規ファイル

```
IrukaKun/
├── WorkTracker/
│   ├── WorkTracker.swift          # 作業時間計測ロジック
│   └── WorkHistoryStore.swift     # 日別履歴の永続化
```

### 変更ファイル

- `MenuBar/StatusBarController.swift` — タイマー表示 + 操作メニュー追加
- `App/AppDelegate.swift` — WorkTracker の統合

### 変更なし

- `App/CharacterController.swift`
- その他既存ファイル

## コンポーネント設計

### WorkTracker

作業時間の計測エンジン。

**状態:**

```
idle --[start()]--> tracking --[5分操作なし]--> paused --[操作検出]--> tracking
                       │                                                │
                       └──[stop()]──> idle <──[start()]─────────────────┘
```

- `idle`: 未計測
- `tracking`: 計測中（1秒ごとに onTick 発火）
- `paused`: 自動休止中（操作なしで自動遷移、操作再開で自動復帰）

**インターフェース:**

```swift
@MainActor
final class WorkTracker {
    enum State { case idle, tracking, paused }

    var state: State { get }
    var elapsedTime: TimeInterval { get }      // 現セッションの経過時間
    var todayTotal: TimeInterval { get }       // 今日の合計（過去セッション含む）

    var onTick: ((TimeInterval) -> Void)?      // 1秒ごとのコールバック
    var onStateChanged: ((State) -> Void)?     // 状態変更コールバック

    func start()
    func stop()
}
```

**自動休止:**

- `NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .keyDown, .leftMouseDown, .rightMouseDown])` でユーザー操作を監視
- 5分間（300秒）操作がなければ自動的に `paused` に遷移
- 操作検出で `tracking` に復帰
- 休止中の時間は作業時間にカウントしない

**日またぎ対応:**

- 1秒タイマーのたびに日付をチェック
- 0:00 を超えたら現在までの経過時間を前日分として保存し、新しいセッションを開始

### WorkHistoryStore

日別の作業時間履歴を UserDefaults に保存する。

```swift
@MainActor
final class WorkHistoryStore {
    func addDuration(_ duration: TimeInterval, for date: Date)
    func todayTotal() -> TimeInterval
    func recentHistory(days: Int = 7) -> [(date: String, duration: TimeInterval)]
}
```

**保存形式:** UserDefaults に `[String: TimeInterval]` で保存（キー: `"yyyy-MM-dd"`、値: 累計秒数）

### StatusBarController の拡張

**メニューバー表示:**

- 計測中: `🐟 1:23:45`（`variableLength` に変更）
- 自動休止中: `🐟 1:23:45 (休止中)`
- 停止中: `🐟`（アイコンのみ）

**メニュー項目追加:**

- `▶ 作業を開始` / `⏸ 作業を中断`（状態に応じて切替）
- `今日の合計: X:XX:XX`（読み取り専用）
- 既存メニュー項目（表示/非表示、状態、設定など）はそのまま

### AppDelegate の変更

- `WorkTracker` と `WorkHistoryStore` をインスタンス化
- `WorkTracker.onTick` → `StatusBarController` の表示更新
- `WorkTracker.onStateChanged` → メニュー項目のラベル切替
- `WorkTracker.stop()` 時に `WorkHistoryStore.addDuration()` で保存
- `applicationWillTerminate` で計測中なら保存

## テスト計画

- `WorkTrackerTests`: 状態遷移（start/stop/pause/resume）、経過時間計算、日またぎ
- `WorkHistoryStoreTests`: 保存/読み込み、日別集計、複数日の履歴
