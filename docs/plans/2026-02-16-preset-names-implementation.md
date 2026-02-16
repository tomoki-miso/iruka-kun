# 作業時間プリセット名機能 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 作業時間にプロジェクト名プリセットを付与し、プリセット別に記録・表示する

**Architecture:** WorkHistoryStore のデータ構造を日別×プリセット別に拡張し、WorkTracker にプリセット切り替え機能を追加。StatusBarController のメニューにプリセット選択UI を追加し、WorkTimerOverlay にプリセット名を表示する。

**Tech Stack:** Swift 6, AppKit, UserDefaults, XCTest

---

### Task 1: WorkHistoryStore — プリセット対応のデータ構造に変更

**Files:**
- Modify: `IrukaKun/WorkTracker/WorkHistoryStore.swift`
- Modify: `IrukaKunTests/WorkHistoryStoreTests.swift`

**Step 1: テストを書き換える**

既存テストをプリセット対応に全面書き換え。

```swift
import XCTest
@testable import IrukaKun

final class WorkHistoryStoreTests: XCTestCase {
    var store: WorkHistoryStore!
    var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test_\(UUID().uuidString)")!
        store = WorkHistoryStore(defaults: defaults)
    }

    func testAddAndRetrieveDuration() {
        let today = Date()
        store.addDuration(3600, for: today, preset: "ProjectA")
        XCTAssertEqual(store.totalDuration(for: today, preset: "ProjectA"), 3600, accuracy: 0.1)
    }

    func testAddDurationAccumulates() {
        let today = Date()
        store.addDuration(1800, for: today, preset: "ProjectA")
        store.addDuration(1200, for: today, preset: "ProjectA")
        XCTAssertEqual(store.totalDuration(for: today, preset: "ProjectA"), 3000, accuracy: 0.1)
    }

    func testTodayTotalAcrossPresets() {
        store.addDuration(3600, for: Date(), preset: "A")
        store.addDuration(1800, for: Date(), preset: "B")
        XCTAssertEqual(store.todayTotal(), 5400, accuracy: 0.1)
    }

    func testTodayTotalReturnsZeroWhenNoData() {
        XCTAssertEqual(store.todayTotal(), 0, accuracy: 0.1)
    }

    func testDifferentPresetsAreSeparate() {
        let today = Date()
        store.addDuration(100, for: today, preset: "A")
        store.addDuration(200, for: today, preset: "B")
        XCTAssertEqual(store.totalDuration(for: today, preset: "A"), 100, accuracy: 0.1)
        XCTAssertEqual(store.totalDuration(for: today, preset: "B"), 200, accuracy: 0.1)
    }

    func testTodayBreakdown() {
        store.addDuration(3600, for: Date(), preset: "A")
        store.addDuration(1800, for: Date(), preset: "B")
        let breakdown = store.todayBreakdown()
        XCTAssertEqual(breakdown["A"], 3600, accuracy: 0.1)
        XCTAssertEqual(breakdown["B"], 1800, accuracy: 0.1)
    }

    func testNilPresetUsesDefaultKey() {
        let today = Date()
        store.addDuration(500, for: today, preset: nil)
        XCTAssertEqual(store.totalDuration(for: today, preset: nil), 500, accuracy: 0.1)
        XCTAssertEqual(store.todayTotal(), 500, accuracy: 0.1)
    }

    func testPresetsCRUD() {
        XCTAssertEqual(store.presets, [])
        store.addPreset("ProjectA")
        store.addPreset("ProjectB")
        XCTAssertEqual(store.presets, ["ProjectA", "ProjectB"])
        store.removePreset("ProjectA")
        XCTAssertEqual(store.presets, ["ProjectB"])
    }

    func testAddDuplicatePresetIsIgnored() {
        store.addPreset("A")
        store.addPreset("A")
        XCTAssertEqual(store.presets, ["A"])
    }
}
```

**Step 2: テストが失敗することを確認**

Run: `xcodebuild test -project IrukaKun.xcodeproj -scheme IrukaKunTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: コンパイルエラー（新しいAPIがまだない）

**Step 3: WorkHistoryStore を書き換える**

```swift
import Foundation

final class WorkHistoryStore: Sendable {
    private nonisolated(unsafe) let defaults: UserDefaults
    private static let historyKey = "iruka_work_history_v2"
    private static let presetsKey = "iruka_presets"
    private static let noPresetKey = "__none__"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    // MARK: - Duration

    func addDuration(_ duration: TimeInterval, for date: Date, preset: String? = nil) {
        var history = loadHistory()
        let dateKey = dateFormatter.string(from: date)
        let presetKey = preset ?? Self.noPresetKey
        var dayData = history[dateKey] ?? [:]
        dayData[presetKey, default: 0] += duration
        history[dateKey] = dayData
        defaults.set(history, forKey: Self.historyKey)
    }

    func totalDuration(for date: Date, preset: String? = nil) -> TimeInterval {
        let dateKey = dateFormatter.string(from: date)
        let presetKey = preset ?? Self.noPresetKey
        return loadHistory()[dateKey]?[presetKey] ?? 0
    }

    func todayTotal() -> TimeInterval {
        let dateKey = dateFormatter.string(from: Date())
        guard let dayData = loadHistory()[dateKey] else { return 0 }
        return dayData.values.reduce(0, +)
    }

    func todayBreakdown() -> [String: TimeInterval] {
        let dateKey = dateFormatter.string(from: Date())
        return loadHistory()[dateKey] ?? [:]
    }

    // MARK: - Presets

    var presets: [String] {
        defaults.stringArray(forKey: Self.presetsKey) ?? []
    }

    func addPreset(_ name: String) {
        var list = presets
        guard !list.contains(name) else { return }
        list.append(name)
        defaults.set(list, forKey: Self.presetsKey)
    }

    func removePreset(_ name: String) {
        var list = presets
        list.removeAll { $0 == name }
        defaults.set(list, forKey: Self.presetsKey)
    }

    // MARK: - Private

    private func loadHistory() -> [String: [String: TimeInterval]] {
        guard let raw = defaults.dictionary(forKey: Self.historyKey) else { return [:] }
        var result: [String: [String: TimeInterval]] = [:]
        for (dateKey, value) in raw {
            if let dayDict = value as? [String: TimeInterval] {
                result[dateKey] = dayDict
            }
        }
        return result
    }
}
```

**Step 4: テストを実行して全パス確認**

Run: `xcodebuild test -project IrukaKun.xcodeproj -scheme IrukaKunTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: WorkHistoryStoreTests 全パス

**Step 5: コミット**

```bash
git add IrukaKun/WorkTracker/WorkHistoryStore.swift IrukaKunTests/WorkHistoryStoreTests.swift
git commit -m "feat: WorkHistoryStore — プリセット対応のデータ構造に変更"
```

---

### Task 2: WorkTracker — プリセット切り替え機能を追加

**Files:**
- Modify: `IrukaKun/WorkTracker/WorkTracker.swift`
- Modify: `IrukaKunTests/WorkTrackerTests.swift`

**Step 1: テストを追加**

既存テストの `historyStore.todayTotal()` 呼び出しはそのまま動く（`addDuration` のデフォルト引数が nil）。新しいプリセット関連テストを追加。

```swift
// WorkTrackerTests.swift の末尾に追加

func testCurrentPresetDefault() {
    XCTAssertNil(tracker.currentPreset)
}

func testSetCurrentPreset() {
    tracker.currentPreset = "ProjectA"
    XCTAssertEqual(tracker.currentPreset, "ProjectA")
}

func testStopSavesToPreset() {
    tracker.currentPreset = "ProjectA"
    tracker.start()
    let expectation = expectation(description: "tick")
    tracker.onTick = { elapsed in
        if elapsed >= 1.0 { expectation.fulfill() }
    }
    wait(for: [expectation], timeout: 3.0)
    tracker.stop()
    XCTAssertGreaterThan(historyStore.totalDuration(for: Date(), preset: "ProjectA"), 0)
}

func testSwitchPresetSavesCurrentAndResets() {
    tracker.currentPreset = "A"
    tracker.start()
    let expectation = expectation(description: "tick")
    tracker.onTick = { elapsed in
        if elapsed >= 1.0 { expectation.fulfill() }
    }
    wait(for: [expectation], timeout: 3.0)
    tracker.switchPreset(to: "B")
    XCTAssertEqual(tracker.currentPreset, "B")
    XCTAssertEqual(tracker.elapsedTime, 0)
    XCTAssertEqual(tracker.state, .tracking)
    XCTAssertGreaterThan(historyStore.totalDuration(for: Date(), preset: "A"), 0)
}

func testSwitchPresetWhileIdleJustSetsPreset() {
    tracker.switchPreset(to: "B")
    XCTAssertEqual(tracker.currentPreset, "B")
    XCTAssertEqual(tracker.state, .idle)
}
```

**Step 2: テストが失敗することを確認**

Run: `xcodebuild test -project IrukaKun.xcodeproj -scheme IrukaKunTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: コンパイルエラー（`currentPreset`, `switchPreset` がない）

**Step 3: WorkTracker にプリセット機能を実装**

WorkTracker.swift に以下を追加・変更:

プロパティ追加（`elapsedTime` の下あたり）:
```swift
var currentPreset: String?
```

`switchPreset` メソッド追加（`start()` の上あたり）:
```swift
func switchPreset(to preset: String) {
    if state != .idle, elapsedTime > 0 {
        historyStore.addDuration(elapsedTime, for: sessionStartDate ?? Date(), preset: currentPreset)
        elapsedTime = 0
        sessionStartDate = Date()
    }
    currentPreset = preset
}
```

`stop()` の `addDuration` 呼び出しを変更:
```swift
// 変更前:
historyStore.addDuration(elapsedTime, for: sessionStartDate ?? Date())
// 変更後:
historyStore.addDuration(elapsedTime, for: sessionStartDate ?? Date(), preset: currentPreset)
```

`tick()` の日付変更時の `addDuration` も同様に変更:
```swift
// 変更前:
historyStore.addDuration(elapsedTime, for: startDate)
// 変更後:
historyStore.addDuration(elapsedTime, for: startDate, preset: currentPreset)
```

**Step 4: テストを実行して全パス確認**

Run: `xcodebuild test -project IrukaKun.xcodeproj -scheme IrukaKunTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: WorkTrackerTests 全パス

**Step 5: コミット**

```bash
git add IrukaKun/WorkTracker/WorkTracker.swift IrukaKunTests/WorkTrackerTests.swift
git commit -m "feat: WorkTracker — プリセット切り替え機能を追加"
```

---

### Task 3: StatusBarController — プリセットメニューを追加

**Files:**
- Modify: `IrukaKun/MenuBar/StatusBarController.swift`

**Step 1: プロバイダとコールバックを追加**

StatusBarController のプロパティ宣言部分に追加:

```swift
var presetsProvider: (() -> [String])?
var currentPresetProvider: (() -> String?)?
var todayBreakdownProvider: (() -> [String: TimeInterval])?
var onSelectPreset: ((String) -> Void)?
var onAddPreset: ((String) -> Void)?
```

**Step 2: rebuildMenu() をプリセット対応に変更**

`rebuildMenu()` を以下に置き換え:

```swift
private func rebuildMenu() {
    let menu = NSMenu()

    // Work tracker toggle
    let workItem = NSMenuItem(title: "▶ 作業を開始", action: #selector(toggleWork), keyEquivalent: "w")
    workToggleMenuItem = workItem
    menu.addItem(workItem)

    menu.addItem(NSMenuItem.separator())

    // Preset selection
    buildPresetSection(in: menu)

    menu.addItem(NSMenuItem.separator())

    // Today's total with breakdown
    let totalItem = NSMenuItem(title: "今日の合計: 0:00:00", action: nil, keyEquivalent: "")
    totalItem.isEnabled = false
    todayTotalMenuItem = totalItem
    menu.addItem(totalItem)

    menu.addItem(NSMenuItem.separator())

    // Character section
    menu.addItem(NSMenuItem(title: "イルカを表示/非表示", action: #selector(toggleCharacter), keyEquivalent: "i"))
    menu.addItem(NSMenuItem.separator())

    let stateItem = NSMenuItem(title: "状態: 🏊 泳いでいる", action: nil, keyEquivalent: "")
    stateItem.isEnabled = false
    stateMenuItem = stateItem
    menu.addItem(stateItem)

    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "設定...", action: #selector(openSettings), keyEquivalent: ","))
    menu.addItem(NSMenuItem(title: "iruka-kun について", action: #selector(showAbout), keyEquivalent: ""))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "iruka-kun を終了", action: #selector(quit), keyEquivalent: "q"))

    for item in menu.items {
        item.target = self
    }

    statusItem?.menu = menu
}

private func buildPresetSection(in menu: NSMenu) {
    let presets = presetsProvider?() ?? []
    let current = currentPresetProvider?()

    for preset in presets {
        let item = NSMenuItem(title: preset, action: #selector(selectPreset(_:)), keyEquivalent: "")
        item.representedObject = preset
        if preset == current {
            item.state = .on
        }
        menu.addItem(item)
    }

    let addItem = NSMenuItem(title: "＋ プリセットを追加...", action: #selector(addPreset), keyEquivalent: "")
    menu.addItem(addItem)
}
```

**Step 3: アクションメソッドを追加**

```swift
@objc private func selectPreset(_ sender: NSMenuItem) {
    guard let name = sender.representedObject as? String else { return }
    onSelectPreset?(name)
}

@objc private func addPreset() {
    let alert = NSAlert()
    alert.messageText = "プリセットを追加"
    alert.informativeText = "プロジェクト名を入力してください"
    alert.addButton(withTitle: "追加")
    alert.addButton(withTitle: "キャンセル")
    let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
    textField.placeholderString = "プロジェクト名"
    alert.accessoryView = textField
    alert.window.initialFirstResponder = textField

    NSApp.activate(ignoringOtherApps: true)
    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
        let name = textField.stringValue.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty {
            onAddPreset?(name)
        }
    }
}
```

**Step 4: updateWorkMenu() にブレークダウン表示を追加**

`updateWorkMenu()` を変更:

```swift
func updateWorkMenu() {
    let workState = workStateProvider?() ?? .idle
    switch workState {
    case .idle:
        workToggleMenuItem?.title = "▶ 作業を開始"
    case .tracking:
        workToggleMenuItem?.title = "⏸ 作業を中断"
    case .paused:
        workToggleMenuItem?.title = "⏸ 作業を中断"
    }

    let total = todayTotalProvider?() ?? 0
    todayTotalMenuItem?.title = "今日の合計: \(formatTime(total))"

    // Update breakdown submenu
    let breakdown = todayBreakdownProvider?() ?? [:]
    if !breakdown.isEmpty {
        let submenu = NSMenu()
        for (preset, duration) in breakdown.sorted(by: { $0.key < $1.key }) {
            let displayName = preset == "__none__" ? "未分類" : preset
            let item = NSMenuItem(title: "\(displayName): \(formatTime(duration))", action: nil, keyEquivalent: "")
            item.isEnabled = false
            submenu.addItem(item)
        }
        todayTotalMenuItem?.submenu = submenu
    } else {
        todayTotalMenuItem?.submenu = nil
    }

    // Rebuild menu to update preset checkmarks
    rebuildMenu()
}
```

**Step 5: ビルド確認**

Run: `xcodebuild build -project IrukaKun.xcodeproj -scheme IrukaKun -destination 'platform=macOS' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 6: コミット**

```bash
git add IrukaKun/MenuBar/StatusBarController.swift
git commit -m "feat: StatusBarController — プリセット選択メニューを追加"
```

---

### Task 4: WorkTimerOverlay — プリセット名を表示

**Files:**
- Modify: `IrukaKun/Character/WorkTimerOverlay.swift`

**Step 1: update メソッドにプリセット名パラメータを追加**

`update` のシグネチャを変更:

```swift
func update(elapsed: TimeInterval, state: WorkTracker.State, preset: String? = nil) {
    switch state {
    case .tracking:
        if let preset {
            label.stringValue = "\(preset) \(formatTime(elapsed))"
        } else {
            label.stringValue = formatTime(elapsed)
        }
    case .paused:
        if let preset {
            label.stringValue = "\(preset) \(formatTime(elapsed)) ⏸"
        } else {
            label.stringValue = "\(formatTime(elapsed)) ⏸"
        }
    case .idle:
        window.orderOut(nil)
        return
    }

    layoutAndPosition()

    if !window.isVisible {
        window.orderFront(nil)
    }
}
```

**Step 2: ビルド確認**

Run: `xcodebuild build -project IrukaKun.xcodeproj -scheme IrukaKun -destination 'platform=macOS' 2>&1 | tail -10`
Expected: CharacterController で呼び出し元がコンパイルエラー（preset 引数がないため）。これは Task 5 で修正する。

**Step 3: コミット**

```bash
git add IrukaKun/Character/WorkTimerOverlay.swift
git commit -m "feat: WorkTimerOverlay — プリセット名を表示"
```

---

### Task 5: AppDelegate — 全体統合

**Files:**
- Modify: `IrukaKun/App/AppDelegate.swift`
- Modify: `IrukaKun/App/CharacterController.swift`

**Step 1: CharacterController の updateWorkTimer にプリセット引数を追加**

CharacterController.swift の `updateWorkTimer` を確認し、preset 引数を追加して WorkTimerOverlay に渡す。

現在のシグネチャ:
```swift
func updateWorkTimer(elapsed: TimeInterval, state: WorkTracker.State)
```

変更後:
```swift
func updateWorkTimer(elapsed: TimeInterval, state: WorkTracker.State, preset: String? = nil)
```

内部で `workTimerOverlay.update(elapsed:state:preset:)` を呼ぶように変更。

**Step 2: AppDelegate の setupMenuBar() にプリセットプロバイダを接続**

`setupMenuBar()` に追加:

```swift
statusBarController.presetsProvider = { [weak self] in
    self?.workHistoryStore.presets ?? []
}
statusBarController.currentPresetProvider = { [weak self] in
    self?.workTracker?.currentPreset
}
statusBarController.todayBreakdownProvider = { [weak self] in
    self?.workHistoryStore.todayBreakdown() ?? [:]
}
statusBarController.onSelectPreset = { [weak self] name in
    self?.workTracker?.switchPreset(to: name)
}
statusBarController.onAddPreset = { [weak self] name in
    self?.workHistoryStore.addPreset(name)
    self?.workTracker?.switchPreset(to: name)
    self?.statusBarController.updateWorkMenu()
}
```

**Step 3: setupWorkTracker() の onTick/onStateChanged でプリセット名を渡す**

`setupWorkTracker()` の `characterController?.updateWorkTimer` 呼び出しに `preset` を追加:

```swift
workTracker?.onTick = { [weak self] elapsed in
    self?.statusBarController.updateTimerDisplay(elapsed: elapsed)
    self?.characterController?.updateWorkTimer(
        elapsed: elapsed,
        state: self?.workTracker?.state ?? .idle,
        preset: self?.workTracker?.currentPreset
    )
}
workTracker?.onStateChanged = { [weak self] _ in
    self?.statusBarController.updateWorkMenu()
    let elapsed = self?.workTracker?.elapsedTime ?? 0
    self?.statusBarController.updateTimerDisplay(elapsed: elapsed)
    self?.characterController?.updateWorkTimer(
        elapsed: elapsed,
        state: self?.workTracker?.state ?? .idle,
        preset: self?.workTracker?.currentPreset
    )
}
```

**Step 4: ビルドして確認**

Run: `xcodebuild build -project IrukaKun.xcodeproj -scheme IrukaKun -destination 'platform=macOS' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 5: 全テストを実行**

Run: `xcodebuild test -project IrukaKun.xcodeproj -scheme IrukaKunTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: 全テストパス

**Step 6: コミット**

```bash
git add IrukaKun/App/AppDelegate.swift IrukaKun/App/CharacterController.swift
git commit -m "feat: AppDelegate — プリセット機能を全体統合"
```
