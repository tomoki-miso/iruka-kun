# 作業時間トラッカー 実装計画

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** iruka-kun に作業時間トラッカーを追加し、メニューバーにリアルタイム表示、手動開始/停止 + 自動休止、日別履歴保存を実現する。

**Architecture:** 新規に `WorkHistoryStore`（UserDefaults 永続化）と `WorkTracker`（計測エンジン、3状態: idle/tracking/paused）を追加。既存の `StatusBarController` にタイマー表示とメニュー操作を拡張し、`AppDelegate` で統合する。

**Tech Stack:** Swift 6 / AppKit / UserDefaults / NSEvent グローバルモニター / XCTest

---

### Task 1: WorkHistoryStore — 日別履歴の永続化

**Files:**
- Create: `IrukaKun/WorkTracker/WorkHistoryStore.swift`
- Create: `IrukaKunTests/WorkHistoryStoreTests.swift`

**Step 1: Write the failing tests**

`IrukaKunTests/WorkHistoryStoreTests.swift`:

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
        store.addDuration(3600, for: today)
        XCTAssertEqual(store.totalDuration(for: today), 3600, accuracy: 0.1)
    }

    func testAddDurationAccumulates() {
        let today = Date()
        store.addDuration(1800, for: today)
        store.addDuration(1200, for: today)
        XCTAssertEqual(store.totalDuration(for: today), 3000, accuracy: 0.1)
    }

    func testTodayTotal() {
        store.addDuration(7200, for: Date())
        XCTAssertEqual(store.todayTotal(), 7200, accuracy: 0.1)
    }

    func testTodayTotalReturnsZeroWhenNoData() {
        XCTAssertEqual(store.todayTotal(), 0, accuracy: 0.1)
    }

    func testRecentHistory() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        store.addDuration(3600, for: today)
        store.addDuration(7200, for: yesterday)

        let history = store.recentHistory(days: 7)
        XCTAssertEqual(history.count, 2)
    }

    func testDifferentDaysAreSeparate() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        store.addDuration(100, for: today)
        store.addDuration(200, for: yesterday)

        XCTAssertEqual(store.totalDuration(for: today), 100, accuracy: 0.1)
        XCTAssertEqual(store.totalDuration(for: yesterday), 200, accuracy: 0.1)
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project IrukaKun.xcodeproj -scheme IrukaKunTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: Compilation error — `WorkHistoryStore` not defined

**Step 3: Write minimal implementation**

`IrukaKun/WorkTracker/WorkHistoryStore.swift`:

```swift
import Foundation

final class WorkHistoryStore: Sendable {
    private nonisolated(unsafe) let defaults: UserDefaults
    private static let storageKey = "iruka_work_history"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    func addDuration(_ duration: TimeInterval, for date: Date) {
        var history = loadHistory()
        let key = dateFormatter.string(from: date)
        history[key, default: 0] += duration
        defaults.set(history, forKey: Self.storageKey)
    }

    func totalDuration(for date: Date) -> TimeInterval {
        let key = dateFormatter.string(from: date)
        return loadHistory()[key] ?? 0
    }

    func todayTotal() -> TimeInterval {
        totalDuration(for: Date())
    }

    func recentHistory(days: Int = 7) -> [(date: String, duration: TimeInterval)] {
        let history = loadHistory()
        let calendar = Calendar.current
        let today = Date()

        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let key = dateFormatter.string(from: date)
            guard let duration = history[key] else { return nil }
            return (date: key, duration: duration)
        }
    }

    private func loadHistory() -> [String: TimeInterval] {
        defaults.dictionary(forKey: Self.storageKey) as? [String: TimeInterval] ?? [:]
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project IrukaKun.xcodeproj -scheme IrukaKunTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: All `WorkHistoryStoreTests` PASS

**Step 5: Commit**

```bash
git add IrukaKun/WorkTracker/WorkHistoryStore.swift IrukaKunTests/WorkHistoryStoreTests.swift
git commit -m "feat: WorkHistoryStore — 日別作業時間の永続化"
```

---

### Task 2: WorkTracker — 計測エンジン（コアロジック）

**Files:**
- Create: `IrukaKun/WorkTracker/WorkTracker.swift`
- Create: `IrukaKunTests/WorkTrackerTests.swift`

**Step 1: Write the failing tests**

`IrukaKunTests/WorkTrackerTests.swift`:

```swift
import XCTest
@testable import IrukaKun

@MainActor
final class WorkTrackerTests: XCTestCase {
    var tracker: WorkTracker!
    var historyStore: WorkHistoryStore!

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "test_\(UUID().uuidString)")!
        historyStore = WorkHistoryStore(defaults: defaults)
        tracker = WorkTracker(historyStore: historyStore, idleThreshold: 2.0)
    }

    override func tearDown() {
        tracker.stop()
        super.tearDown()
    }

    func testInitialStateIsIdle() {
        XCTAssertEqual(tracker.state, .idle)
    }

    func testStartTransitionsToTracking() {
        tracker.start()
        XCTAssertEqual(tracker.state, .tracking)
    }

    func testStopTransitionsToIdle() {
        tracker.start()
        tracker.stop()
        XCTAssertEqual(tracker.state, .idle)
    }

    func testStopFromIdleDoesNothing() {
        tracker.stop()
        XCTAssertEqual(tracker.state, .idle)
    }

    func testStartWhileTrackingDoesNothing() {
        tracker.start()
        tracker.start()
        XCTAssertEqual(tracker.state, .tracking)
    }

    func testElapsedTimeIncrements() {
        tracker.start()
        let expectation = expectation(description: "tick")
        tracker.onTick = { elapsed in
            if elapsed >= 1.0 {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
        XCTAssertGreaterThanOrEqual(tracker.elapsedTime, 1.0)
    }

    func testStopSavesToHistory() {
        tracker.start()
        // Wait a moment so elapsed > 0
        let expectation = expectation(description: "tick")
        tracker.onTick = { elapsed in
            if elapsed >= 1.0 {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
        tracker.stop()
        XCTAssertGreaterThan(historyStore.todayTotal(), 0)
    }

    func testOnStateChangedCallback() {
        var states: [WorkTracker.State] = []
        tracker.onStateChanged = { state in
            states.append(state)
        }
        tracker.start()
        tracker.stop()
        XCTAssertEqual(states, [.tracking, .idle])
    }

    func testElapsedTimeResetsOnStop() {
        tracker.start()
        let expectation = expectation(description: "tick")
        tracker.onTick = { elapsed in
            if elapsed >= 1.0 {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
        tracker.stop()
        XCTAssertEqual(tracker.elapsedTime, 0)
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project IrukaKun.xcodeproj -scheme IrukaKunTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: Compilation error — `WorkTracker` not defined

**Step 3: Write minimal implementation**

`IrukaKun/WorkTracker/WorkTracker.swift`:

```swift
import AppKit

@MainActor
final class WorkTracker {
    enum State: Equatable, Sendable {
        case idle
        case tracking
        case paused
    }

    private(set) var state: State = .idle
    private(set) var elapsedTime: TimeInterval = 0

    var onTick: ((TimeInterval) -> Void)?
    var onStateChanged: ((State) -> Void)?

    private let historyStore: WorkHistoryStore
    private let idleThreshold: TimeInterval

    private var tickTimer: Timer?
    private var sessionStartDate: Date?
    private var lastActivityDate: Date?
    private var eventMonitor: Any?

    init(historyStore: WorkHistoryStore, idleThreshold: TimeInterval = 300) {
        self.historyStore = historyStore
        self.idleThreshold = idleThreshold
    }

    var todayTotal: TimeInterval {
        historyStore.todayTotal() + (state != .idle ? elapsedTime : 0)
    }

    func start() {
        guard state == .idle else { return }
        elapsedTime = 0
        sessionStartDate = Date()
        lastActivityDate = Date()
        transition(to: .tracking)
        startTickTimer()
        startEventMonitor()
    }

    func stop() {
        guard state != .idle else { return }
        stopTickTimer()
        stopEventMonitor()
        if elapsedTime > 0 {
            historyStore.addDuration(elapsedTime, for: sessionStartDate ?? Date())
        }
        elapsedTime = 0
        sessionStartDate = nil
        transition(to: .idle)
    }

    // MARK: - Private

    private func transition(to newState: State) {
        guard newState != state else { return }
        state = newState
        onStateChanged?(newState)
    }

    private func startTickTimer() {
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopTickTimer() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func tick() {
        guard state != .idle else { return }

        // Check for day change
        if let startDate = sessionStartDate {
            let startDay = Calendar.current.startOfDay(for: startDate)
            let today = Calendar.current.startOfDay(for: Date())
            if startDay != today {
                // Day changed — save previous day and reset
                historyStore.addDuration(elapsedTime, for: startDate)
                elapsedTime = 0
                sessionStartDate = Date()
            }
        }

        // Check for idle timeout
        if state == .tracking, let lastActivity = lastActivityDate {
            if Date().timeIntervalSince(lastActivity) >= idleThreshold {
                transition(to: .paused)
            }
        }

        // Only count time when tracking (not paused)
        if state == .tracking {
            elapsedTime += 1
            onTick?(elapsedTime)
        } else if state == .paused {
            // Still fire onTick so UI can update the "(休止中)" display
            onTick?(elapsedTime)
        }
    }

    private func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .keyDown, .leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleUserActivity()
            }
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func handleUserActivity() {
        lastActivityDate = Date()
        if state == .paused {
            transition(to: .tracking)
        }
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project IrukaKun.xcodeproj -scheme IrukaKunTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: All `WorkTrackerTests` PASS

**Step 5: Commit**

```bash
git add IrukaKun/WorkTracker/WorkTracker.swift IrukaKunTests/WorkTrackerTests.swift
git commit -m "feat: WorkTracker — 作業時間計測エンジン（手動開始/停止 + 自動休止）"
```

---

### Task 3: StatusBarController — タイマー表示 + 操作メニュー

**Files:**
- Modify: `IrukaKun/MenuBar/StatusBarController.swift`

**Step 1: Add work tracker menu items and timer display**

`StatusBarController.swift` を以下のように拡張:

```swift
import AppKit

@MainActor
final class StatusBarController {
    private var statusItem: NSStatusItem?
    private var stateMenuItem: NSMenuItem?
    private var workToggleMenuItem: NSMenuItem?
    private var todayTotalMenuItem: NSMenuItem?

    var onToggleCharacter: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?
    var onToggleWork: (() -> Void)?
    var currentStateProvider: (() -> CharacterState)?
    var workStateProvider: (() -> WorkTracker.State)?
    var todayTotalProvider: (() -> TimeInterval)?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "fish.fill", accessibilityDescription: "iruka-kun")

        rebuildMenu()
    }

    func updateStateDisplay() {
        guard let state = currentStateProvider?() else { return }
        let label: String
        switch state {
        case .idle: label = "🏊 泳いでいる"
        case .happy: label = "😊 喜んでいる"
        case .sleeping: label = "😴 寝ている"
        case .surprised: label = "😲 驚いている"
        case .bored: label = "😑 退屈している"
        }
        stateMenuItem?.title = "状態: \(label)"
    }

    func updateTimerDisplay(elapsed: TimeInterval) {
        guard let button = statusItem?.button else { return }
        let workState = workStateProvider?() ?? .idle

        switch workState {
        case .tracking:
            button.title = " \(formatTime(elapsed))"
        case .paused:
            button.title = " \(formatTime(elapsed)) (休止中)"
        case .idle:
            button.title = ""
        }
    }

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
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        // Work tracker section
        let workItem = NSMenuItem(title: "▶ 作業を開始", action: #selector(toggleWork), keyEquivalent: "w")
        workToggleMenuItem = workItem
        menu.addItem(workItem)

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

    @objc private func toggleWork() { onToggleWork?() }
    @objc private func toggleCharacter() { onToggleCharacter?() }
    @objc private func openSettings() { onOpenSettings?() }
    @objc private func quit() { onQuit?() }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }
}
```

**Step 2: Build to verify compilation**

Run: `xcodebuild build -project IrukaKun.xcodeproj -scheme IrukaKun -destination 'platform=macOS' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add IrukaKun/MenuBar/StatusBarController.swift
git commit -m "feat: StatusBarController — タイマー表示と作業開始/停止メニュー追加"
```

---

### Task 4: AppDelegate — WorkTracker 統合

**Files:**
- Modify: `IrukaKun/App/AppDelegate.swift`

**Step 1: Integrate WorkTracker into AppDelegate**

```swift
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarController = StatusBarController()
    private let settingsWindowController = SettingsWindowController()
    private let workHistoryStore = WorkHistoryStore()
    private var workTracker: WorkTracker?
    private var characterController: CharacterController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        characterController = CharacterController()
        characterController?.showCharacter()

        workTracker = WorkTracker(historyStore: workHistoryStore)
        setupMenuBar()
        setupWorkTracker()
    }

    func applicationWillTerminate(_ notification: Notification) {
        workTracker?.stop()
    }

    private func setupMenuBar() {
        statusBarController.setup()
        statusBarController.currentStateProvider = { [weak self] in
            self?.characterController?.currentState ?? .idle
        }
        statusBarController.workStateProvider = { [weak self] in
            self?.workTracker?.state ?? .idle
        }
        statusBarController.todayTotalProvider = { [weak self] in
            self?.workTracker?.todayTotal ?? 0
        }
        statusBarController.onToggleCharacter = { [weak self] in
            self?.characterController?.toggleCharacter()
        }
        statusBarController.onToggleWork = { [weak self] in
            self?.toggleWork()
        }
        statusBarController.onOpenSettings = { [weak self] in
            self?.settingsWindowController.show()
        }
        statusBarController.onQuit = {
            NSApp.terminate(nil)
        }

        characterController?.onStateChanged = { [weak self] _ in
            self?.statusBarController.updateStateDisplay()
        }

        statusBarController.updateWorkMenu()
    }

    private func setupWorkTracker() {
        workTracker?.onTick = { [weak self] elapsed in
            self?.statusBarController.updateTimerDisplay(elapsed: elapsed)
        }
        workTracker?.onStateChanged = { [weak self] _ in
            self?.statusBarController.updateWorkMenu()
            // Update timer display when state changes (e.g. paused/resumed)
            self?.statusBarController.updateTimerDisplay(elapsed: self?.workTracker?.elapsedTime ?? 0)
        }
    }

    private func toggleWork() {
        guard let tracker = workTracker else { return }
        if tracker.state == .idle {
            tracker.start()
        } else {
            tracker.stop()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
```

**Step 2: Build and run all tests**

Run: `xcodebuild test -project IrukaKun.xcodeproj -scheme IrukaKunTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: All tests PASS, BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add IrukaKun/App/AppDelegate.swift
git commit -m "feat: AppDelegate — WorkTracker統合、メニューバー経由で作業時間計測"
```

---

### Task 5: XcodeGen 再生成 & 動作確認

**Step 1: Regenerate Xcode project**

新しい `WorkTracker/` ディレクトリが `project.yml` の `sources` に含まれることを確認（`path: IrukaKun` で自動的にサブディレクトリも含まれる）。

Run: `cd /Users/misoshiru/Development/iruka-kun && xcodegen generate`
Expected: `Generated IrukaKun.xcodeproj`

**Step 2: Build and run all tests**

Run: `xcodebuild test -project IrukaKun.xcodeproj -scheme IrukaKunTests -destination 'platform=macOS' 2>&1 | tail -20`
Expected: All tests PASS

**Step 3: Manual smoke test**

- アプリを起動
- メニューバーの「▶ 作業を開始」をクリック → 🐟 の横に `0:00:01` が表示される
- 数秒待って「⏸ 作業を中断」をクリック → タイマーが消える
- メニュー内の「今日の合計」に作業時間が反映されている
