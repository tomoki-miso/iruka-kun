# 作業履歴確認ウィンドウ Implementation Plan

**Goal:** 記録された作業時間をプリセット別・日別に確認できるウィンドウを追加

**Tech Stack:** Swift 6, SwiftUI, AppKit, UserDefaults

---

### Task 1: WorkHistoryStore — recentHistory メソッド追加

**Files:**
- Modify: `IrukaKun/WorkTracker/WorkHistoryStore.swift`
- Modify: `IrukaKunTests/WorkHistoryStoreTests.swift`

**Step 1: テストを追加**

```swift
// WorkHistoryStoreTests.swift に追加

func testRecentHistoryReturnsData() {
    let calendar = Calendar.current
    let today = Date()
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    store.addDuration(3600, for: today, preset: "A")
    store.addDuration(1800, for: today, preset: "B")
    store.addDuration(7200, for: yesterday, preset: "A")
    let history = store.recentHistory(days: 7)
    XCTAssertEqual(history.count, 2)
    // Today
    XCTAssertEqual(history[0].presets["A"] ?? 0, 3600, accuracy: 0.1)
    XCTAssertEqual(history[0].presets["B"] ?? 0, 1800, accuracy: 0.1)
    XCTAssertEqual(history[0].total, 5400, accuracy: 0.1)
    // Yesterday
    XCTAssertEqual(history[1].presets["A"] ?? 0, 7200, accuracy: 0.1)
    XCTAssertEqual(history[1].total, 7200, accuracy: 0.1)
}

func testRecentHistorySkipsEmptyDays() {
    store.addDuration(100, for: Date(), preset: nil)
    let history = store.recentHistory(days: 7)
    XCTAssertEqual(history.count, 1)
}
```

**Step 2: テスト失敗を確認**

Run: `xcodebuild test -project IrukaKun.xcodeproj -scheme IrukaKunTests -destination 'platform=macOS' 2>&1 | tail -20`

**Step 3: recentHistory メソッドを実装**

WorkHistoryStore に追加:

```swift
struct DayHistory {
    let date: Date
    let dateString: String
    let presets: [String: TimeInterval]
    var total: TimeInterval { presets.values.reduce(0, +) }
}

func recentHistory(days: Int = 7) -> [DayHistory] {
    let history = loadHistory()
    let calendar = Calendar.current
    let today = Date()
    var results: [DayHistory] = []

    for offset in 0..<days {
        guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
        let dateKey = dateFormatter.string(from: date)
        guard let dayData = history[dateKey], !dayData.isEmpty else { continue }
        results.append(DayHistory(date: date, dateString: dateKey, presets: dayData))
    }
    return results
}
```

**Step 4: テスト全パス確認**

Run: `xcodebuild test -project IrukaKun.xcodeproj -scheme IrukaKunTests -destination 'platform=macOS' 2>&1 | tail -20`

**Step 5: コミット**

```bash
git add IrukaKun/WorkTracker/WorkHistoryStore.swift IrukaKunTests/WorkHistoryStoreTests.swift
git commit -m "feat: WorkHistoryStore — recentHistory メソッド追加"
```

---

### Task 2: WorkHistoryView + WorkHistoryWindowController 作成

**Files:**
- Create: `IrukaKun/Settings/WorkHistoryView.swift`
- Create: `IrukaKun/Settings/WorkHistoryWindowController.swift`

**Step 1: WorkHistoryWindowController を作成**

SettingsWindowController と同じパターン。

```swift
import AppKit
import SwiftUI

@MainActor
final class WorkHistoryWindowController {
    private var window: NSWindow?

    func show(historyStore: WorkHistoryStore) {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let view = WorkHistoryView(historyStore: historyStore)
        let hostingController = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "作業履歴"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 400, height: 500))
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window

        NSApp.activate(ignoringOtherApps: true)
    }
}
```

**Step 2: WorkHistoryView を作成**

SwiftUI で過去7日の日別×プリセット別リストを表示。

**Step 3: Xcode プロジェクトにファイルを追加**

新しいファイルを Xcode プロジェクトの IrukaKun ターゲットに追加する。

**Step 4: ビルド確認**

Run: `xcodebuild build -project IrukaKun.xcodeproj -scheme IrukaKun -destination 'platform=macOS' 2>&1 | tail -10`

**Step 5: コミット**

```bash
git add IrukaKun/Settings/WorkHistoryView.swift IrukaKun/Settings/WorkHistoryWindowController.swift IrukaKun.xcodeproj
git commit -m "feat: 作業履歴ウィンドウを追加"
```

---

### Task 3: StatusBarController + AppDelegate — メニュー項目と接続

**Files:**
- Modify: `IrukaKun/MenuBar/StatusBarController.swift`
- Modify: `IrukaKun/App/AppDelegate.swift`

**Step 1: StatusBarController にコールバック追加**

```swift
var onShowHistory: (() -> Void)?
```

rebuildMenu() の「設定...」の上に「作業履歴...」メニュー項目を追加。

**Step 2: AppDelegate に WorkHistoryWindowController を追加**

```swift
private let workHistoryWindowController = WorkHistoryWindowController()
```

setupMenuBar() で接続:
```swift
statusBarController.onShowHistory = { [weak self] in
    guard let self else { return }
    self.workHistoryWindowController.show(historyStore: self.workHistoryStore)
}
```

**Step 3: ビルド＆テスト確認**

Run: `xcodebuild build -project IrukaKun.xcodeproj -scheme IrukaKun -destination 'platform=macOS' 2>&1 | tail -10`
Run: `xcodebuild test -project IrukaKun.xcodeproj -scheme IrukaKunTests -destination 'platform=macOS' 2>&1 | tail -20`

**Step 4: コミット**

```bash
git add IrukaKun/MenuBar/StatusBarController.swift IrukaKun/App/AppDelegate.swift
git commit -m "feat: メニューバーに作業履歴メニュー項目を追加"
```
