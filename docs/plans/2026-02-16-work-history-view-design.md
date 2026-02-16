# 作業履歴確認ウィンドウ Design Document

**Goal:** 記録された作業時間をプリセット別・日別に確認できるウィンドウを追加する

## 導線

メニューバーに「作業履歴...」メニュー項目を追加。クリックで専用ウィンドウを開く。

## 表示内容

過去7日間の日別×プリセット別作業時間。データなしの日はスキップ。

```
┌─ 作業履歴 ──────────────────────┐
│                                  │
│  2/16 (日) ────────── 合計 2:30:00 │
│    ProjectA           1:30:00    │
│    ProjectB           1:00:00    │
│                                  │
│  2/15 (土) ────────── 合計 3:15:00 │
│    ProjectA           2:00:00    │
│    未分類              1:15:00    │
│                                  │
│  ...                             │
└──────────────────────────────────┘
```

## Architecture

既存の SettingsWindowController と同じパターン（NSHostingController + SwiftUI）。

## 変更ファイル

- 新規: `IrukaKun/Settings/WorkHistoryView.swift` — SwiftUI 履歴表示
- 新規: `IrukaKun/Settings/WorkHistoryWindowController.swift` — ウィンドウ管理
- 変更: `IrukaKun/WorkTracker/WorkHistoryStore.swift` — `recentHistory(days:)` 追加
- 変更: `IrukaKun/MenuBar/StatusBarController.swift` — メニュー項目追加
- 変更: `IrukaKun/App/AppDelegate.swift` — コールバック接続
