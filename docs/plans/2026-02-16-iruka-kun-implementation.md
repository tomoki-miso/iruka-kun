# iruka-kun Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** macOS上に常駐するドット絵イルカのデスクトップキャラクターアプリを実装する

**Architecture:** AppKit主体のハイブリッド構成。透過NSWindowにCALayerベースのスプライトアニメーションを表示し、メニューバーから制御する。状態管理・セリフ管理はテスト可能なモデル層に分離し、設定画面のみSwiftUIで実装する。

**Tech Stack:** Swift 6.2 / AppKit / Core Animation / SwiftUI (settings only) / XcodeGen / macOS 15+

**Design Doc:** `docs/plans/2026-02-16-iruka-kun-design.md`

---

## Task 1: プロジェクトスキャフォールディング

**Files:**
- Create: `project.yml`
- Create: `IrukaKun/App/AppDelegate.swift`
- Create: `IrukaKun/App/main.swift`
- Create: `IrukaKun/Info.plist`
- Create: `IrukaKun/iruka-kun.entitlements`
- Create: `IrukaKunTests/IrukaKunTests.swift`

**Step 1: XcodeGenをインストール**

Run: `brew install xcodegen`
Expected: XcodeGen がインストールされる

**Step 2: project.yml を作成**

```yaml
name: IrukaKun
options:
  bundleIdPrefix: com.iruka-kun
  deploymentTarget:
    macOS: "15.0"
  xcodeVersion: "16.0"
  minimumXcodeGenVersion: "2.38"
settings:
  base:
    SWIFT_VERSION: "6"
    MACOSX_DEPLOYMENT_TARGET: "15.0"
    GENERATE_INFOPLIST_FILE: false
    CODE_SIGN_IDENTITY: "-"
    PRODUCT_NAME: "iruka-kun"
targets:
  IrukaKun:
    type: application
    platform: macOS
    sources:
      - path: IrukaKun
        excludes:
          - "**/*.entitlements"
    resources:
      - path: Resources
    settings:
      base:
        INFOPLIST_FILE: IrukaKun/Info.plist
        CODE_SIGN_ENTITLEMENTS: IrukaKun/iruka-kun.entitlements
        LD_RUNPATH_SEARCH_PATHS: "$(inherited) @executable_path/../Frameworks"
    info:
      path: IrukaKun/Info.plist
    entitlements:
      path: IrukaKun/iruka-kun.entitlements
  IrukaKunTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - path: IrukaKunTests
    dependencies:
      - target: IrukaKun
    settings:
      base:
        BUNDLE_LOADER: "$(TEST_HOST)"
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/iruka-kun.app/Contents/MacOS/iruka-kun"
```

**Step 3: Info.plist を作成**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>ja</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIconFile</key>
    <string></string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>iruka-kun</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSMainNibFile</key>
    <string></string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
</dict>
</plist>
```

**Step 4: Entitlements を作成**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```

**Step 5: main.swift を作成（最小エントリポイント）**

```swift
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

**Step 6: AppDelegate.swift を作成（最小版）**

```swift
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("iruka-kun launched")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
```

**Step 7: テストファイルを作成（最小版）**

```swift
import XCTest
@testable import IrukaKun

final class IrukaKunTests: XCTestCase {
    func testAppLaunches() {
        XCTAssertTrue(true)
    }
}
```

**Step 8: Resources ディレクトリを準備**

```bash
mkdir -p Resources/Sprites Resources/Sounds
cp assets/iruka.png Resources/Sprites/iruka_idle_0.png
```

**Step 9: プロジェクトを生成してビルド**

Run: `xcodegen generate && xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKun -configuration Debug build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

**Step 10: テストを実行**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKunTests -configuration Debug test 2>&1 | tail -5`
Expected: `** TEST SUCCEEDED **`

**Step 11: コミット**

```bash
git add project.yml IrukaKun/ IrukaKunTests/ Resources/ .gitignore
git commit -m "feat: プロジェクトスキャフォールディング

XcodeGenベースのプロジェクト構成。LSUIElement=YES、macOS 15+。"
```

---

## Task 2: メニューバー常駐 + 基本メニュー

**Files:**
- Create: `IrukaKun/MenuBar/StatusBarController.swift`
- Modify: `IrukaKun/App/AppDelegate.swift`

**Step 1: StatusBarController を作成**

```swift
import AppKit

@MainActor
final class StatusBarController {
    private var statusItem: NSStatusItem?
    var onToggleCharacter: (() -> Void)?
    var onQuit: (() -> Void)?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "fish.fill", accessibilityDescription: "iruka-kun")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "イルカを表示/非表示", action: #selector(toggleCharacter), keyEquivalent: "i"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "iruka-kun を終了", action: #selector(quit), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        statusItem?.menu = menu
    }

    @objc private func toggleCharacter() {
        onToggleCharacter?()
    }

    @objc private func quit() {
        onQuit?()
    }
}
```

**Step 2: AppDelegate を更新してメニューバーを表示**

```swift
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarController = StatusBarController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController.setup()
        statusBarController.onToggleCharacter = { [weak self] in
            NSLog("Toggle character")
        }
        statusBarController.onQuit = {
            NSApp.terminate(nil)
        }
        NSLog("iruka-kun launched")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
```

**Step 3: ビルドして手動確認**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKun build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

手動確認: アプリを起動し、メニューバーに魚アイコンが表示される。クリックでメニューが出る。「終了」でアプリが終了する。Dockにはアイコンが表示されない。

**Step 4: コミット**

```bash
git add IrukaKun/MenuBar/ IrukaKun/App/AppDelegate.swift
git commit -m "feat: メニューバー常駐と基本メニュー

NSStatusItemでメニューバーにアイコン表示。表示/非表示トグルと終了メニュー。"
```

---

## Task 3: 透過フローティングウィンドウ

**Files:**
- Create: `IrukaKun/Character/CharacterWindow.swift`
- Modify: `IrukaKun/App/AppDelegate.swift`

**Step 1: CharacterWindow を作成**

```swift
import AppKit

@MainActor
final class CharacterWindow: NSWindow {
    static let characterSize = CGSize(width: 128, height: 128)

    init() {
        let initialFrame = Self.defaultFrame()
        super.init(
            contentRect: initialFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        isReleasedWhenClosed = false
        ignoresMouseEvents = false
    }

    override var canBecomeKey: Bool { true }

    private static func defaultFrame() -> NSRect {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let x = screenFrame.maxX - characterSize.width - 40
        let y = screenFrame.minY + 40
        return NSRect(origin: CGPoint(x: x, y: y), size: characterSize)
    }
}
```

**Step 2: AppDelegate からウィンドウを表示**

```swift
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarController = StatusBarController()
    private var characterWindow: CharacterWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupCharacterWindow()
        setupMenuBar()
        NSLog("iruka-kun launched")
    }

    private func setupCharacterWindow() {
        characterWindow = CharacterWindow()
        characterWindow?.orderFront(nil)
    }

    private func setupMenuBar() {
        statusBarController.setup()
        statusBarController.onToggleCharacter = { [weak self] in
            guard let window = self?.characterWindow else { return }
            if window.isVisible {
                window.orderOut(nil)
            } else {
                window.orderFront(nil)
            }
        }
        statusBarController.onQuit = {
            NSApp.terminate(nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
```

**Step 3: ビルドして手動確認**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKun build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

手動確認: 起動後、画面右下に透明な（何も見えない）ウィンドウが存在する。メニューバーの「表示/非表示」で切り替わる。

**Step 4: コミット**

```bash
git add IrukaKun/Character/CharacterWindow.swift IrukaKun/App/AppDelegate.swift
git commit -m "feat: 透過フローティングウィンドウ

borderless + 透明背景 + 常に最前面のNSWindow。画面右下に初期配置。"
```

---

## Task 4: 静的スプライト表示

**Files:**
- Create: `IrukaKun/Character/CharacterView.swift`
- Modify: `IrukaKun/App/AppDelegate.swift`

**Step 1: CharacterView を作成（静的画像表示）**

```swift
import AppKit

@MainActor
final class CharacterView: NSView {
    private let imageLayer = CALayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayer() {
        wantsLayer = true
        guard let layer else { return }
        layer.backgroundColor = NSColor.clear.cgColor

        imageLayer.contentsGravity = .resizeAspect
        imageLayer.magnificationFilter = .nearest
        layer.addSublayer(imageLayer)

        if let image = NSImage(named: "iruka_idle_0") {
            imageLayer.contents = image
        }
    }

    override func layout() {
        super.layout()
        imageLayer.frame = bounds
    }

    func setSprite(_ image: NSImage) {
        imageLayer.contents = image
    }
}
```

**Step 2: AppDelegate でウィンドウにCharacterViewを設定**

`setupCharacterWindow()` を以下に更新:

```swift
private var characterView: CharacterView?

private func setupCharacterWindow() {
    characterWindow = CharacterWindow()
    let view = CharacterView(frame: NSRect(origin: .zero, size: CharacterWindow.characterSize))
    characterView = view
    characterWindow?.contentView = view
    characterWindow?.orderFront(nil)
}
```

**Step 3: ビルドして手動確認**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKun build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

手動確認: 画面右下にドット絵のイルカが表示される。背景は透明で、デスクトップが見える。

**Step 4: コミット**

```bash
git add IrukaKun/Character/CharacterView.swift IrukaKun/App/AppDelegate.swift
git commit -m "feat: 静的スプライト表示

CALayerベースのCharacterViewでiruka.pngをウィンドウに表示。nearest neighborフィルタでドット絵の鮮明さを維持。"
```

---

## Task 5: 状態マシン（TDD）

**Files:**
- Create: `IrukaKun/State/CharacterState.swift`
- Create: `IrukaKun/State/StateMachine.swift`
- Create: `IrukaKunTests/StateMachineTests.swift`

**Step 1: テストを書く**

```swift
import XCTest
@testable import IrukaKun

final class StateMachineTests: XCTestCase {
    var stateMachine: StateMachine!

    override func setUp() {
        super.setUp()
        stateMachine = StateMachine()
    }

    func testInitialStateIsIdle() {
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    func testClickTransitionsToHappy() {
        stateMachine.handleEvent(.clicked)
        XCTAssertEqual(stateMachine.currentState, .happy)
    }

    func testHappyReturnsToIdleAfterDuration() {
        stateMachine.handleEvent(.clicked)
        XCTAssertEqual(stateMachine.currentState, .happy)
        stateMachine.handleEvent(.temporaryStateExpired)
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    func testDragTransitionsToSurprised() {
        stateMachine.handleEvent(.dragStarted)
        XCTAssertEqual(stateMachine.currentState, .surprised)
    }

    func testSurprisedReturnsToIdleAfterDuration() {
        stateMachine.handleEvent(.dragStarted)
        stateMachine.handleEvent(.temporaryStateExpired)
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    func testNightTimeTransitionsToSleeping() {
        stateMachine.handleEvent(.nightTime)
        XCTAssertEqual(stateMachine.currentState, .sleeping)
    }

    func testDayTimeReturnsSleepingToIdle() {
        stateMachine.handleEvent(.nightTime)
        stateMachine.handleEvent(.dayTime)
        XCTAssertEqual(stateMachine.currentState, .idle)
    }

    func testIdleTimeoutTransitionsToBored() {
        stateMachine.handleEvent(.idleTimeout)
        XCTAssertEqual(stateMachine.currentState, .bored)
    }

    func testClickFromBoredTransitionsToHappy() {
        stateMachine.handleEvent(.idleTimeout)
        stateMachine.handleEvent(.clicked)
        XCTAssertEqual(stateMachine.currentState, .happy)
    }

    func testSleepingIgnoresClickAndDrag() {
        stateMachine.handleEvent(.nightTime)
        stateMachine.handleEvent(.clicked)
        XCTAssertEqual(stateMachine.currentState, .sleeping)
        stateMachine.handleEvent(.dragStarted)
        XCTAssertEqual(stateMachine.currentState, .sleeping)
    }

    func testStateChangeCallback() {
        var receivedStates: [CharacterState] = []
        stateMachine.onStateChanged = { newState in
            receivedStates.append(newState)
        }
        stateMachine.handleEvent(.clicked)
        stateMachine.handleEvent(.temporaryStateExpired)
        XCTAssertEqual(receivedStates, [.happy, .idle])
    }
}
```

**Step 2: テストが失敗することを確認**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKunTests test 2>&1 | tail -5`
Expected: コンパイルエラー（CharacterState, StateMachine が存在しない）

**Step 3: CharacterState を実装**

```swift
enum CharacterState: Equatable, Sendable {
    case idle
    case happy
    case sleeping
    case surprised
    case bored
}

enum CharacterEvent: Sendable {
    case clicked
    case dragStarted
    case nightTime
    case dayTime
    case idleTimeout
    case temporaryStateExpired
}
```

**Step 4: StateMachine を実装**

```swift
@MainActor
final class StateMachine {
    private(set) var currentState: CharacterState = .idle
    var onStateChanged: ((CharacterState) -> Void)?

    func handleEvent(_ event: CharacterEvent) {
        let newState = nextState(for: event)
        guard newState != currentState else { return }
        currentState = newState
        onStateChanged?(newState)
    }

    private func nextState(for event: CharacterEvent) -> CharacterState {
        switch (currentState, event) {
        // Sleeping state is sticky — only dayTime exits it
        case (.sleeping, .dayTime):
            return .idle
        case (.sleeping, _):
            return .sleeping

        // Night time always transitions to sleeping
        case (_, .nightTime):
            return .sleeping

        // Click transitions to happy from any non-sleeping state
        case (_, .clicked):
            return .happy

        // Drag transitions to surprised
        case (_, .dragStarted):
            return .surprised

        // Idle timeout from idle
        case (.idle, .idleTimeout):
            return .bored

        // Temporary states expire back to idle
        case (.happy, .temporaryStateExpired),
             (.surprised, .temporaryStateExpired),
             (.bored, .temporaryStateExpired):
            return .idle

        default:
            return currentState
        }
    }
}
```

**Step 5: テストを実行して全パス確認**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKunTests test 2>&1 | grep -E "(Test Suite|Test Case|passed|failed)"`
Expected: 全テストPASS

**Step 6: コミット**

```bash
git add IrukaKun/State/ IrukaKunTests/StateMachineTests.swift
git commit -m "feat: 状態マシン（5状態 + イベント駆動遷移）

CharacterState: idle/happy/sleeping/surprised/bored
StateMachine: イベントに基づく状態遷移。sleepingは粘着的。テスト11件。"
```

---

## Task 6: セリフデータとDialogueManager（TDD）

**Files:**
- Create: `Resources/Dialogues.json`
- Create: `IrukaKun/State/DialogueManager.swift`
- Create: `IrukaKun/State/TimeOfDay.swift`
- Create: `IrukaKunTests/DialogueManagerTests.swift`

**Step 1: Dialogues.json を作成**

```json
{
  "morning": [
    "おはよう！今日もがんばろう",
    "いい朝だね〜",
    "朝ごはん食べた？",
    "今日はなにするの？",
    "おはよ〜！元気？"
  ],
  "afternoon": [
    "いい天気だね〜",
    "休憩した？",
    "水分補給してね",
    "がんばってるね！",
    "ちょっと休もうよ"
  ],
  "evening": [
    "おつかれさま",
    "そろそろ休む？",
    "今日もお疲れ〜",
    "夜ごはんの時間だよ",
    "いい一日だった？"
  ],
  "night": [
    "zzz...",
    "すぅ...すぅ...",
    "むにゃ...",
    "...おやすみ..."
  ],
  "clicked": [
    "なあに？",
    "キュッ！",
    "よんだ？",
    "あそぼ！",
    "えへへ"
  ],
  "dragged": [
    "わわっ！",
    "どこ連れてくの？",
    "きゃー！",
    "ちょ、ちょっと！"
  ],
  "bored": [
    "ひまだな〜",
    "遊んでよ〜",
    "ぼーっ...",
    "なにかしようよ",
    "クリックして〜"
  ]
}
```

**Step 2: テストを書く**

```swift
import XCTest
@testable import IrukaKun

final class DialogueManagerTests: XCTestCase {

    func testTimeOfDayClassification() {
        XCTAssertEqual(TimeOfDay.from(hour: 7), .morning)
        XCTAssertEqual(TimeOfDay.from(hour: 9), .morning)
        XCTAssertEqual(TimeOfDay.from(hour: 10), .afternoon)
        XCTAssertEqual(TimeOfDay.from(hour: 14), .afternoon)
        XCTAssertEqual(TimeOfDay.from(hour: 18), .evening)
        XCTAssertEqual(TimeOfDay.from(hour: 23), .evening)
        XCTAssertEqual(TimeOfDay.from(hour: 0), .night)
        XCTAssertEqual(TimeOfDay.from(hour: 5), .night)
    }

    func testLoadDialoguesFromJSON() {
        let manager = DialogueManager()
        let morning = manager.dialogues(for: .morning)
        XCTAssertFalse(morning.isEmpty)
        XCTAssertTrue(morning.contains("おはよう！今日もがんばろう"))
    }

    func testDialogueForEvent() {
        let manager = DialogueManager()
        let clickDialogue = manager.dialogueForEvent(.clicked)
        XCTAssertNotNil(clickDialogue)
    }

    func testDialogueForDragEvent() {
        let manager = DialogueManager()
        let dragDialogue = manager.dialogueForEvent(.dragStarted)
        XCTAssertNotNil(dragDialogue)
    }

    func testDialogueForBoredEvent() {
        let manager = DialogueManager()
        let boredDialogue = manager.dialogueForEvent(.idleTimeout)
        XCTAssertNotNil(boredDialogue)
    }

    func testTimeBasedDialogue() {
        let manager = DialogueManager()
        let dialogue = manager.timeBasedDialogue(hour: 8)
        XCTAssertNotNil(dialogue)
    }

    func testNightTimeDialogue() {
        let manager = DialogueManager()
        let dialogue = manager.timeBasedDialogue(hour: 2)
        XCTAssertNotNil(dialogue)
    }
}
```

**Step 3: テストが失敗することを確認**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKunTests test 2>&1 | tail -5`
Expected: コンパイルエラー

**Step 4: TimeOfDay を実装**

```swift
enum TimeOfDay: String, Sendable, Equatable {
    case morning    // 6:00 - 9:59
    case afternoon  // 10:00 - 17:59
    case evening    // 18:00 - 23:59
    case night      // 0:00 - 5:59

    static func from(hour: Int) -> TimeOfDay {
        switch hour {
        case 6..<10: return .morning
        case 10..<18: return .afternoon
        case 18..<24: return .evening
        default: return .night
        }
    }

    static func current() -> TimeOfDay {
        from(hour: Calendar.current.component(.hour, from: Date()))
    }
}
```

**Step 5: DialogueManager を実装**

```swift
import Foundation

struct DialogueData: Codable {
    let morning: [String]
    let afternoon: [String]
    let evening: [String]
    let night: [String]
    let clicked: [String]
    let dragged: [String]
    let bored: [String]
}

final class DialogueManager: Sendable {
    private let data: DialogueData

    init() {
        guard let url = Bundle.main.url(forResource: "Dialogues", withExtension: "json"),
              let jsonData = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(DialogueData.self, from: jsonData)
        else {
            data = DialogueData(morning: [], afternoon: [], evening: [], night: [],
                                clicked: [], dragged: [], bored: [])
            return
        }
        data = decoded
    }

    func dialogues(for timeOfDay: TimeOfDay) -> [String] {
        switch timeOfDay {
        case .morning: return data.morning
        case .afternoon: return data.afternoon
        case .evening: return data.evening
        case .night: return data.night
        }
    }

    func dialogueForEvent(_ event: CharacterEvent) -> String? {
        let pool: [String]
        switch event {
        case .clicked: pool = data.clicked
        case .dragStarted: pool = data.dragged
        case .idleTimeout: pool = data.bored
        default: return nil
        }
        return pool.randomElement()
    }

    func timeBasedDialogue(hour: Int) -> String? {
        let timeOfDay = TimeOfDay.from(hour: hour)
        return dialogues(for: timeOfDay).randomElement()
    }
}
```

**Step 6: テストを実行して全パス確認**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKunTests test 2>&1 | grep -E "(Test Case|passed|failed)"`
Expected: 全テストPASS

**Step 7: コミット**

```bash
git add Resources/Dialogues.json IrukaKun/State/TimeOfDay.swift IrukaKun/State/DialogueManager.swift IrukaKunTests/DialogueManagerTests.swift
git commit -m "feat: セリフデータとDialogueManager

Dialogues.json: 7カテゴリ計33セリフ。TimeOfDay: 時間帯分類。DialogueManager: イベント/時間帯に応じたセリフ選択。テスト7件。"
```

---

## Task 7: スプライトアニメーター

**Files:**
- Create: `IrukaKun/Character/SpriteAnimator.swift`
- Modify: `IrukaKun/Character/CharacterView.swift`

**Step 1: SpriteAnimator を作成**

```swift
import AppKit

@MainActor
final class SpriteAnimator {
    private var framesByState: [CharacterState: [NSImage]] = [:]
    private var currentFrames: [NSImage] = []
    private var currentFrameIndex = 0
    private var timer: Timer?
    private let fps: Double = 10.0

    var onFrameChanged: ((NSImage) -> Void)?

    init() {
        loadSprites()
    }

    private func loadSprites() {
        for state in [CharacterState.idle, .happy, .sleeping, .surprised, .bored] {
            let prefix = spritePrefix(for: state)
            var frames: [NSImage] = []
            for i in 0..<10 {
                let name = "\(prefix)_\(i)"
                if let image = NSImage(named: name) {
                    frames.append(image)
                }
            }
            // If no specific frames, fall back to idle frame 0
            if frames.isEmpty, let fallback = NSImage(named: "iruka_idle_0") {
                frames.append(fallback)
            }
            framesByState[state] = frames
        }
    }

    private func spritePrefix(for state: CharacterState) -> String {
        switch state {
        case .idle: return "iruka_idle"
        case .happy: return "iruka_happy"
        case .sleeping: return "iruka_sleeping"
        case .surprised: return "iruka_surprised"
        case .bored: return "iruka_bored"
        }
    }

    func play(state: CharacterState) {
        stop()
        currentFrames = framesByState[state] ?? []
        currentFrameIndex = 0
        guard !currentFrames.isEmpty else { return }
        onFrameChanged?(currentFrames[0])

        guard currentFrames.count > 1 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceFrame()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func advanceFrame() {
        guard !currentFrames.isEmpty else { return }
        currentFrameIndex = (currentFrameIndex + 1) % currentFrames.count
        onFrameChanged?(currentFrames[currentFrameIndex])
    }
}
```

**Step 2: CharacterView を更新してアニメーター連携**

```swift
import AppKit

@MainActor
final class CharacterView: NSView {
    private let imageLayer = CALayer()
    let animator = SpriteAnimator()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
        setupAnimator()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayer() {
        wantsLayer = true
        guard let layer else { return }
        layer.backgroundColor = NSColor.clear.cgColor

        imageLayer.contentsGravity = .resizeAspect
        imageLayer.magnificationFilter = .nearest
        layer.addSublayer(imageLayer)

        if let image = NSImage(named: "iruka_idle_0") {
            imageLayer.contents = image
        }
    }

    private func setupAnimator() {
        animator.onFrameChanged = { [weak self] image in
            self?.imageLayer.contents = image
        }
        animator.play(state: .idle)
    }

    override func layout() {
        super.layout()
        imageLayer.frame = bounds
    }

    func setSprite(_ image: NSImage) {
        imageLayer.contents = image
    }
}
```

**Step 3: ビルド確認**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKun build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

手動確認: MVPではスプライトが1フレームのみなので静止画表示。追加フレームが用意できたらアニメーションが動く。

**Step 4: コミット**

```bash
git add IrukaKun/Character/SpriteAnimator.swift IrukaKun/Character/CharacterView.swift
git commit -m "feat: SpriteAnimator

状態ごとのスプライトフレーム配列を管理し、Timerベースでフレーム切り替え。10fps。フレーム不足時はフォールバック。"
```

---

## Task 8: ヒットテスト + ドラッグ + 位置永続化

**Files:**
- Create: `IrukaKun/Utilities/PositionStore.swift`
- Create: `IrukaKunTests/PositionStoreTests.swift`
- Modify: `IrukaKun/Character/CharacterView.swift`
- Modify: `IrukaKun/Character/CharacterWindow.swift`

**Step 1: PositionStore テストを書く**

```swift
import XCTest
@testable import IrukaKun

final class PositionStoreTests: XCTestCase {
    var store: PositionStore!

    override func setUp() {
        super.setUp()
        store = PositionStore(defaults: UserDefaults(suiteName: "test_\(UUID().uuidString)")!)
    }

    func testSaveAndLoadPosition() {
        let point = CGPoint(x: 123.0, y: 456.0)
        store.save(position: point)
        let loaded = store.loadPosition()
        XCTAssertEqual(loaded?.x, 123.0, accuracy: 0.1)
        XCTAssertEqual(loaded?.y, 456.0, accuracy: 0.1)
    }

    func testLoadPositionReturnsNilWhenNotSaved() {
        let loaded = store.loadPosition()
        XCTAssertNil(loaded)
    }
}
```

**Step 2: テストが失敗することを確認**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKunTests test 2>&1 | tail -5`
Expected: コンパイルエラー

**Step 3: PositionStore を実装**

```swift
import Foundation

final class PositionStore: Sendable {
    private let defaults: UserDefaults
    private static let xKey = "iruka_position_x"
    private static let yKey = "iruka_position_y"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(position: CGPoint) {
        defaults.set(Double(position.x), forKey: Self.xKey)
        defaults.set(Double(position.y), forKey: Self.yKey)
    }

    func loadPosition() -> CGPoint? {
        guard defaults.object(forKey: Self.xKey) != nil else { return nil }
        let x = defaults.double(forKey: Self.xKey)
        let y = defaults.double(forKey: Self.yKey)
        return CGPoint(x: x, y: y)
    }
}
```

**Step 4: テストをパス確認**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKunTests test 2>&1 | grep -E "(Test Case|passed|failed)"`
Expected: 全テストPASS

**Step 5: CharacterView にヒットテストとドラッグを追加**

```swift
import AppKit

@MainActor
final class CharacterView: NSView {
    private let imageLayer = CALayer()
    let animator = SpriteAnimator()
    private var isDragging = false
    private var dragOffset = CGPoint.zero

    var onClicked: (() -> Void)?
    var onDragStarted: (() -> Void)?
    var onDragEnded: ((CGPoint) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
        setupAnimator()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayer() {
        wantsLayer = true
        guard let layer else { return }
        layer.backgroundColor = NSColor.clear.cgColor

        imageLayer.contentsGravity = .resizeAspect
        imageLayer.magnificationFilter = .nearest
        layer.addSublayer(imageLayer)

        if let image = NSImage(named: "iruka_idle_0") {
            imageLayer.contents = image
        }
    }

    private func setupAnimator() {
        animator.onFrameChanged = { [weak self] image in
            self?.imageLayer.contents = image
        }
        animator.play(state: .idle)
    }

    override func layout() {
        super.layout()
        imageLayer.frame = bounds
    }

    func setSprite(_ image: NSImage) {
        imageLayer.contents = image
    }

    // MARK: - Hit Testing

    override func hitTest(_ point: NSPoint) -> NSView? {
        let localPoint = convert(point, from: superview)
        guard bounds.contains(localPoint) else { return nil }

        // Check alpha at the point
        guard let image = imageLayer.contents as? NSImage else { return nil }
        if isOpaquePixel(at: localPoint, in: image) {
            return self
        }
        return nil
    }

    private func isOpaquePixel(at point: NSPoint, in image: NSImage) -> Bool {
        let imageSize = image.size
        let scaleX = imageSize.width / bounds.width
        let scaleY = imageSize.height / bounds.height
        let imagePoint = NSPoint(x: point.x * scaleX, y: point.y * scaleY)

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let ptr = CFDataGetBytePtr(data)
        else { return false }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let ix = Int(imagePoint.x)
        // Flip Y (NSImage is bottom-up, CGImage is top-down)
        let iy = cgImage.height - 1 - Int(imagePoint.y)

        guard ix >= 0, ix < cgImage.width, iy >= 0, iy < cgImage.height else { return false }

        let offset = iy * bytesPerRow + ix * bytesPerPixel
        let alphaIndex = bytesPerPixel - 1 // RGBA: alpha is last
        let alpha = ptr[offset + alphaIndex]
        return alpha > 30 // threshold
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        isDragging = false
        guard let window else { return }
        let windowLocation = event.locationInWindow
        let windowOrigin = window.frame.origin
        dragOffset = CGPoint(
            x: windowOrigin.x - NSEvent.mouseLocation.x,
            y: windowOrigin.y - NSEvent.mouseLocation.y
        )
    }

    override func mouseDragged(with event: NSEvent) {
        if !isDragging {
            isDragging = true
            onDragStarted?()
        }
        guard let window else { return }
        let mouseLocation = NSEvent.mouseLocation
        let newOrigin = CGPoint(
            x: mouseLocation.x + dragOffset.x,
            y: mouseLocation.y + dragOffset.y
        )
        window.setFrameOrigin(newOrigin)
    }

    override func mouseUp(with event: NSEvent) {
        if isDragging {
            guard let window else { return }
            onDragEnded?(window.frame.origin)
            isDragging = false
        } else {
            onClicked?()
        }
    }
}
```

**Step 6: CharacterWindow に位置復元を追加**

CharacterWindow の `init()` を更新:

```swift
@MainActor
final class CharacterWindow: NSWindow {
    static let characterSize = CGSize(width: 128, height: 128)
    private let positionStore = PositionStore()

    init() {
        let initialFrame = NSRect(origin: .zero, size: Self.characterSize)
        super.init(
            contentRect: initialFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        isReleasedWhenClosed = false
        ignoresMouseEvents = false

        restorePosition()
    }

    override var canBecomeKey: Bool { true }

    func savePosition() {
        positionStore.save(position: frame.origin)
    }

    private func restorePosition() {
        if let saved = positionStore.loadPosition() {
            setFrameOrigin(saved)
        } else {
            setFrameOrigin(Self.defaultOrigin())
        }
    }

    private static func defaultOrigin() -> CGPoint {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        return CGPoint(
            x: screenFrame.maxX - characterSize.width - 40,
            y: screenFrame.minY + 40
        )
    }
}
```

**Step 7: ビルド + テスト**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKunTests test 2>&1 | grep -E "(passed|failed|SUCCEEDED)"`
Expected: 全テストPASS + TEST SUCCEEDED

手動確認: イルカをドラッグで移動できる。透明部分はクリックスルーされる。クリックするとログが出る。

**Step 8: コミット**

```bash
git add IrukaKun/Character/CharacterView.swift IrukaKun/Character/CharacterWindow.swift IrukaKun/Utilities/PositionStore.swift IrukaKunTests/PositionStoreTests.swift
git commit -m "feat: ヒットテスト、ドラッグ移動、位置永続化

透明ピクセルのクリックスルー（alpha閾値30）。ドラッグで移動可。UserDefaultsで位置を保存・復元。テスト2件追加。"
```

---

## Task 9: 吹き出しビュー

**Files:**
- Create: `IrukaKun/Character/BubbleView.swift`
- Modify: `IrukaKun/Character/CharacterView.swift`

**Step 1: BubbleView を作成**

```swift
import AppKit

@MainActor
final class BubbleView: NSView {
    private let label = NSTextField(labelWithString: "")
    private let padding: CGFloat = 10
    private let tailHeight: CGFloat = 8
    private var fadeTimer: Timer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        wantsLayer = true

        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        label.alignment = .center
        label.maximumNumberOfLines = 3
        label.preferredMaxLayoutWidth = 160
        addSubview(label)
    }

    func show(text: String, relativeTo characterFrame: NSRect, in parentWindow: NSWindow) {
        fadeTimer?.invalidate()
        label.stringValue = text
        label.sizeToFit()

        let bubbleWidth = label.frame.width + padding * 2
        let bubbleHeight = label.frame.height + padding * 2 + tailHeight
        let size = CGSize(width: max(bubbleWidth, 60), height: bubbleHeight)

        // Position above character
        let x = characterFrame.midX - size.width / 2
        let y = characterFrame.maxY + 4
        self.frame = NSRect(origin: CGPoint(x: x, y: y), size: size)

        label.frame = NSRect(
            x: padding,
            y: tailHeight + padding,
            width: size.width - padding * 2,
            height: label.frame.height
        )

        alphaValue = 1.0
        isHidden = false
        parentWindow.contentView?.addSubview(self)

        // Adjust window size to fit bubble
        var windowFrame = parentWindow.frame
        let requiredTop = y + size.height
        if requiredTop > windowFrame.maxY {
            let extraHeight = requiredTop - windowFrame.maxY
            windowFrame.size.height += extraHeight
            windowFrame.origin.y -= extraHeight
            parentWindow.setFrame(windowFrame, display: true)
        }

        // Auto-fade after delay
        let displayDuration = max(3.0, Double(text.count) * 0.15)
        fadeTimer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.fadeOut()
            }
        }
    }

    private func fadeOut() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            self.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.isHidden = true
            self?.removeFromSuperview()
        })
    }

    override func draw(_ dirtyRect: NSRect) {
        let bubbleRect = NSRect(
            x: 0,
            y: tailHeight,
            width: bounds.width,
            height: bounds.height - tailHeight
        )

        let path = NSBezierPath(roundedRect: bubbleRect, xRadius: 8, yRadius: 8)

        // Tail
        let tailPath = NSBezierPath()
        let tailCenterX = bounds.midX
        tailPath.move(to: NSPoint(x: tailCenterX - 6, y: tailHeight))
        tailPath.line(to: NSPoint(x: tailCenterX, y: 0))
        tailPath.line(to: NSPoint(x: tailCenterX + 6, y: tailHeight))
        tailPath.close()

        NSColor.white.withAlphaComponent(0.95).setFill()
        path.fill()
        tailPath.fill()

        NSColor.gray.withAlphaComponent(0.3).setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    // Make bubble clickable (for hit test pass-through)
    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        return bounds.contains(local) && !isHidden ? self : nil
    }
}
```

**Step 2: ビルド確認**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKun build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

**Step 3: コミット**

```bash
git add IrukaKun/Character/BubbleView.swift
git commit -m "feat: 吹き出しビュー

白背景の吹き出しUIに三角のしっぽ付き。テキスト長に応じた表示時間。自動フェードアウト。"
```

---

## Task 10: 全体統合 — トリガー接続

**Files:**
- Create: `IrukaKun/App/CharacterController.swift`
- Modify: `IrukaKun/App/AppDelegate.swift`

**Step 1: CharacterController を作成（全コンポーネントの統合制御）**

```swift
import AppKit

@MainActor
final class CharacterController {
    private let stateMachine = StateMachine()
    private let dialogueManager = DialogueManager()
    private let characterWindow = CharacterWindow()
    private let characterView: CharacterView
    private let bubbleView = BubbleView()

    private var dialogueTimer: Timer?
    private var idleTimer: Timer?
    private var stateRevertTimer: Timer?
    private var lastTimeOfDay: TimeOfDay?

    // Intervals
    private let dialogueInterval: TimeInterval = 900 // 15 minutes
    private let idleTimeout: TimeInterval = 1800     // 30 minutes
    private let temporaryStateDuration: TimeInterval = 3.0

    var isCharacterVisible: Bool { characterWindow.isVisible }
    var currentState: CharacterState { stateMachine.currentState }

    init() {
        characterView = CharacterView(frame: NSRect(origin: .zero, size: CharacterWindow.characterSize))
        characterWindow.contentView = characterView
        setupCallbacks()
        setupTimers()
    }

    func showCharacter() {
        characterWindow.orderFront(nil)
    }

    func hideCharacter() {
        characterWindow.orderOut(nil)
    }

    func toggleCharacter() {
        if characterWindow.isVisible {
            hideCharacter()
        } else {
            showCharacter()
        }
    }

    // MARK: - Setup

    private func setupCallbacks() {
        // State machine → animation
        stateMachine.onStateChanged = { [weak self] newState in
            self?.characterView.animator.play(state: newState)
        }

        // View events → state machine
        characterView.onClicked = { [weak self] in
            self?.handleClick()
        }
        characterView.onDragStarted = { [weak self] in
            self?.stateMachine.handleEvent(.dragStarted)
            self?.showDialogueForEvent(.dragStarted)
            self?.scheduleStateRevert()
        }
        characterView.onDragEnded = { [weak self] _ in
            self?.characterWindow.savePosition()
            self?.resetIdleTimer()
        }
    }

    private func setupTimers() {
        // Periodic dialogue timer
        dialogueTimer = Timer.scheduledTimer(withTimeInterval: dialogueInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.showTimeBasedDialogue()
            }
        }

        // Idle detection timer
        resetIdleTimer()

        // Time-of-day check (every minute)
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkTimeOfDay()
            }
        }

        // Initial time check
        checkTimeOfDay()
    }

    // MARK: - Event Handling

    private func handleClick() {
        stateMachine.handleEvent(.clicked)
        showDialogueForEvent(.clicked)
        scheduleStateRevert()
        resetIdleTimer()
    }

    private func scheduleStateRevert() {
        stateRevertTimer?.invalidate()
        stateRevertTimer = Timer.scheduledTimer(withTimeInterval: temporaryStateDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stateMachine.handleEvent(.temporaryStateExpired)
            }
        }
    }

    private func resetIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: idleTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stateMachine.handleEvent(.idleTimeout)
                self?.showDialogueForEvent(.idleTimeout)
            }
        }
    }

    private func checkTimeOfDay() {
        let current = TimeOfDay.current()
        guard current != lastTimeOfDay else { return }
        lastTimeOfDay = current
        if current == .night {
            stateMachine.handleEvent(.nightTime)
        } else if stateMachine.currentState == .sleeping {
            stateMachine.handleEvent(.dayTime)
        }
    }

    // MARK: - Dialogue

    private func showDialogueForEvent(_ event: CharacterEvent) {
        guard let text = dialogueManager.dialogueForEvent(event) else { return }
        showBubble(text: text)
    }

    private func showTimeBasedDialogue() {
        let hour = Calendar.current.component(.hour, from: Date())
        guard let text = dialogueManager.timeBasedDialogue(hour: hour) else { return }
        showBubble(text: text)
    }

    private func showBubble(text: String) {
        let charFrame = characterView.frame
        bubbleView.show(text: text, relativeTo: charFrame, in: characterWindow)
    }
}
```

**Step 2: AppDelegate をシンプルに更新**

```swift
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarController = StatusBarController()
    private var characterController: CharacterController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        characterController = CharacterController()
        characterController?.showCharacter()
        setupMenuBar()
    }

    private func setupMenuBar() {
        statusBarController.setup()
        statusBarController.onToggleCharacter = { [weak self] in
            self?.characterController?.toggleCharacter()
        }
        statusBarController.onQuit = {
            NSApp.terminate(nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
```

**Step 3: ビルド + テスト**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKunTests test 2>&1 | grep -E "(passed|failed|SUCCEEDED)"`
Expected: 全テストPASS

手動確認: イルカが表示される。クリックで喜ぶ + セリフ。ドラッグで驚く。しばらく放置で退屈セリフ。15分ごとに時間帯セリフ。

**Step 4: コミット**

```bash
git add IrukaKun/App/CharacterController.swift IrukaKun/App/AppDelegate.swift
git commit -m "feat: 全体統合 — CharacterController

StateMachine/DialogueManager/SpriteAnimator/BubbleViewを統合。クリック→喜ぶ、ドラッグ→驚く、放置→退屈、深夜→寝る。15分間隔の時間帯セリフ。"
```

---

## Task 11: 効果音

**Files:**
- Create: `IrukaKun/Utilities/SoundPlayer.swift`
- Modify: `IrukaKun/App/CharacterController.swift`

**Step 1: SoundPlayer を作成**

```swift
import AppKit

@MainActor
final class SoundPlayer {
    private var clickSound: NSSound?

    init() {
        if let url = Bundle.main.url(forResource: "click", withExtension: "aiff") {
            clickSound = NSSound(contentsOf: url, byReference: true)
        } else {
            // Fallback: use system sound
            clickSound = NSSound(named: "Pop")
        }
    }

    func playClick() {
        clickSound?.stop()
        clickSound?.play()
    }
}
```

**Step 2: CharacterController に SoundPlayer を追加**

`handleClick()` 内に追加:

```swift
private let soundPlayer = SoundPlayer()

private func handleClick() {
    soundPlayer.playClick()
    stateMachine.handleEvent(.clicked)
    showDialogueForEvent(.clicked)
    scheduleStateRevert()
    resetIdleTimer()
}
```

**Step 3: ビルド確認**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKun build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

手動確認: クリック時に「ポッ」という音が鳴る（システムのPop音をフォールバック使用）。

**Step 4: コミット**

```bash
git add IrukaKun/Utilities/SoundPlayer.swift IrukaKun/App/CharacterController.swift
git commit -m "feat: クリック時の効果音

NSSound でクリック音を再生。カスタム音源がなければシステムのPop音にフォールバック。"
```

---

## Task 12: マルチディスプレイ対応

**Files:**
- Create: `IrukaKun/Utilities/ScreenUtility.swift`
- Modify: `IrukaKun/Character/CharacterWindow.swift`

**Step 1: ScreenUtility を作成**

```swift
import AppKit

@MainActor
final class ScreenUtility {
    var onScreenConfigurationChanged: (() -> Void)?

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenDidChange(_ notification: Notification) {
        onScreenConfigurationChanged?()
    }

    static func isPointOnAnyScreen(_ point: CGPoint) -> Bool {
        NSScreen.screens.contains { screen in
            screen.frame.contains(point)
        }
    }

    static func nearestScreenFrame(to point: CGPoint) -> NSRect {
        let screen = NSScreen.screens.min(by: { screenA, screenB in
            let distA = distance(from: point, to: screenA.visibleFrame)
            let distB = distance(from: point, to: screenB.visibleFrame)
            return distA < distB
        })
        return screen?.visibleFrame ?? (NSScreen.main?.visibleFrame ?? .zero)
    }

    private static func distance(from point: CGPoint, to rect: NSRect) -> CGFloat {
        let cx = max(rect.minX, min(point.x, rect.maxX))
        let cy = max(rect.minY, min(point.y, rect.maxY))
        return hypot(point.x - cx, point.y - cy)
    }
}
```

**Step 2: CharacterWindow にスクリーン変更対応を追加**

`CharacterWindow` に以下を追加:

```swift
private let screenUtility = ScreenUtility()

// init() の末尾に追加:
screenUtility.onScreenConfigurationChanged = { [weak self] in
    self?.ensureOnScreen()
}

func ensureOnScreen() {
    let origin = frame.origin
    if !ScreenUtility.isPointOnAnyScreen(origin) {
        let safeFrame = ScreenUtility.nearestScreenFrame(to: origin)
        let safeOrigin = CGPoint(
            x: min(origin.x, safeFrame.maxX - frame.width),
            y: min(origin.y, safeFrame.maxY - frame.height)
        )
        setFrameOrigin(safeOrigin)
        savePosition()
    }
}
```

**Step 3: ビルド + テスト**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKunTests test 2>&1 | tail -3`
Expected: `** TEST SUCCEEDED **`

**Step 4: コミット**

```bash
git add IrukaKun/Utilities/ScreenUtility.swift IrukaKun/Character/CharacterWindow.swift
git commit -m "feat: マルチディスプレイ対応

ディスプレイ構成変更を監視。ウィンドウが画面外に出た場合は最寄りの画面にフォールバック。"
```

---

## Task 13: メニューバー拡充（状態表示 + About + 設定）

**Files:**
- Modify: `IrukaKun/MenuBar/StatusBarController.swift`
- Create: `IrukaKun/Settings/SettingsView.swift`
- Create: `IrukaKun/Settings/SettingsWindowController.swift`
- Modify: `IrukaKun/App/AppDelegate.swift`

**Step 1: StatusBarController を拡充**

```swift
import AppKit

@MainActor
final class StatusBarController {
    private var statusItem: NSStatusItem?
    private var stateMenuItem: NSMenuItem?

    var onToggleCharacter: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?
    var currentStateProvider: (() -> CharacterState)?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

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

    private func rebuildMenu() {
        let menu = NSMenu()

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

    @objc private func toggleCharacter() { onToggleCharacter?() }
    @objc private func openSettings() { onOpenSettings?() }
    @objc private func quit() { onQuit?() }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }
}
```

**Step 2: SettingsView を作成（SwiftUI）**

```swift
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Toggle("ログイン時に自動起動", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = !newValue
                        NSLog("Failed to update login item: \(error)")
                    }
                }
        }
        .formStyle(.grouped)
        .frame(width: 300, height: 100)
        .padding()
    }
}
```

**Step 3: SettingsWindowController を作成**

```swift
import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private var window: NSWindow?

    func show() {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "iruka-kun 設定"
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window

        NSApp.activate(ignoringOtherApps: true)
    }
}
```

**Step 4: AppDelegate を更新して接続**

`AppDelegate` の `setupMenuBar()` を更新:

```swift
private let settingsWindowController = SettingsWindowController()

private func setupMenuBar() {
    statusBarController.setup()
    statusBarController.currentStateProvider = { [weak self] in
        self?.characterController?.currentState ?? .idle
    }
    statusBarController.onToggleCharacter = { [weak self] in
        self?.characterController?.toggleCharacter()
    }
    statusBarController.onOpenSettings = { [weak self] in
        self?.settingsWindowController.show()
    }
    statusBarController.onQuit = {
        NSApp.terminate(nil)
    }
}
```

`CharacterController` の `stateMachine.onStateChanged` に状態表示更新を追加:

```swift
// CharacterController 内の setupCallbacks() に追加
var onStateChanged: ((CharacterState) -> Void)?

stateMachine.onStateChanged = { [weak self] newState in
    self?.characterView.animator.play(state: newState)
    self?.onStateChanged?(newState)
}
```

`AppDelegate` で接続:

```swift
characterController?.onStateChanged = { [weak self] _ in
    self?.statusBarController.updateStateDisplay()
}
```

**Step 5: ビルド + テスト**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKunTests test 2>&1 | tail -3`
Expected: `** TEST SUCCEEDED **`

手動確認: メニューバーに状態表示あり。「設定...」でSwiftUI設定ウィンドウが開く。「iruka-kunについて」でAboutパネル。

**Step 6: コミット**

```bash
git add IrukaKun/MenuBar/ IrukaKun/Settings/ IrukaKun/App/
git commit -m "feat: メニューバー拡充 + 設定画面

状態表示、About、設定メニュー追加。SwiftUI設定画面でログイン時自動起動ON/OFF（SMAppService）。"
```

---

## Task 14: .gitignore + 最終整備

**Files:**
- Create: `.gitignore`

**Step 1: .gitignore を作成**

```
# Xcode
*.xcodeproj/
!*.xcodeproj/project.pbxproj
*.xcodeproj/xcuserdata/
*.xcworkspace/xcuserdata/
xcuserdata/
build/
DerivedData/
*.moved-aside
*.pbxuser
*.mode1v3
*.mode2v3
*.perspectivev3
*.xccheckout
*.hmap
*.ipa
*.dSYM.zip
*.dSYM

# Swift
.build/
.swiftpm/

# macOS
.DS_Store
*.swp
*~

# XcodeGen (generated project should not be committed)
*.xcodeproj
```

**Step 2: コミット**

```bash
git add .gitignore
git rm -r --cached IrukaKun.xcodeproj 2>/dev/null || true
git commit -m "chore: .gitignore追加、生成されたxcodeprojを除外"
```

---

## Task 15: ビルド・配布準備

**Step 1: リリースビルド確認**

Run: `xcodegen generate && xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKun -configuration Release build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

**Step 2: 全テスト実行**

Run: `xcodebuild -project IrukaKun.xcodeproj -scheme IrukaKunTests test 2>&1 | grep -E "(Test Suite|passed|failed)"`
Expected: 全テストPASS（20件: StateMachine 11件 + DialogueManager 7件 + PositionStore 2件）

**Step 3: 手動統合テスト**

以下を確認:
- [ ] アプリ起動でDockに表示されない
- [ ] メニューバーに魚アイコンが表示される
- [ ] 画面右下にドット絵イルカが表示される
- [ ] イルカをクリック → 喜ぶアニメ + セリフ + 効果音
- [ ] イルカをドラッグ → 驚くアニメ + セリフ
- [ ] ドラッグで移動 → アプリ再起動後も位置が復元される
- [ ] 透明部分をクリック → 背面のアプリに通る
- [ ] メニューバー「表示/非表示」→ イルカが消える/出る
- [ ] メニューバーに状態表示が更新される
- [ ] 「設定」→ 設定ウィンドウが開く
- [ ] 「iruka-kunについて」→ Aboutパネル
- [ ] 「終了」→ アプリが終了する
- [ ] 15分放置 → 時間帯に応じたセリフ

**Step 4: コミット（最終タグ）**

```bash
git tag v0.1.0-mvp
```
