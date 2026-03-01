import AppKit
import UniformTypeIdentifiers

@MainActor
final class StatusBarController {
    private var statusItem: NSStatusItem?
    private var stateMenuItem: NSMenuItem?
    private var workToggleMenuItem: NSMenuItem?
    private var todayTotalMenuItem: NSMenuItem?

    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?
    var onToggleWork: (() -> Void)?
    var currentStateProvider: (() -> CharacterState)?
    var workStateProvider: (() -> WorkTracker.State)?
    var todayTotalProvider: (() -> TimeInterval)?

    var presetsProvider: (() -> [String])?
    var currentPresetProvider: (() -> String?)?
    var todayBreakdownProvider: (() -> [String: TimeInterval])?
    var onSelectPreset: ((String) -> Void)?
    var onClearPreset: (() -> Void)?
    var onAddPreset: ((String) -> Void)?
    var onShowHistory: (() -> Void)?
    var onShowMeigenHistory: (() -> Void)?
    var onShowReport: (() -> Void)?

    var onSwitchCharacter: ((CharacterType) -> Void)?
    var currentCharacterProvider: (() -> CharacterType)?
    var onAddCustomCharacter: ((String, URL) -> Void)?
    var onRemoveCustomCharacter: ((String) -> Void)?
    var customCharacterNamesProvider: (() -> [String])?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        NSLog("[iruka-kun] statusItem created: \(statusItem != nil)")

        guard let button = statusItem?.button else {
            NSLog("[iruka-kun] button is nil!")
            return
        }
        let iconName = currentCharacterProvider?().menuBarIconName ?? "fish.fill"
        let img = NSImage(systemSymbolName: iconName, accessibilityDescription: "iruka-kun")
        NSLog("[iruka-kun] menu bar icon: \(iconName), image: \(img != nil)")
        button.image = img

        rebuildMenu()
        NSLog("[iruka-kun] menu built")
    }

    func updateMenuBarIcon(_ type: CharacterType) {
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: type.menuBarIconName, accessibilityDescription: "iruka-kun")
    }

    func updateStateDisplay() {
        guard let state = currentStateProvider?() else { return }
        let characterType = currentCharacterProvider?() ?? .iruka
        let label: String
        switch state {
        case .idle:
            if case .rakko = characterType {
                label = "🏊 浮かんでいる"
            } else if case .ono = characterType {
                label = "💼 仕事をしている"
            } else if case .syacho = characterType {
                label = "💼 仕事をしている"
            } else if characterType.isBuiltIn {
                label = "🏊 泳いでいる"
            } else {
                label = "🏊 待機中"
            }
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
            workToggleMenuItem?.title = "⏹ 作業を中止"
        case .paused:
            workToggleMenuItem?.title = "⏹ 作業を中止"
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

    private func formatTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        // Work tracker toggle
        let workState = workStateProvider?() ?? .idle
        let workTitle = workState == .idle ? "▶ 作業を開始" : "⏹ 作業を中止"
        let workItem = NSMenuItem(title: workTitle, action: #selector(toggleWork), keyEquivalent: "w")
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

        let stateItem = NSMenuItem(title: "状態: 🏊 泳いでいる", action: nil, keyEquivalent: "")
        stateItem.isEnabled = false
        stateMenuItem = stateItem
        menu.addItem(stateItem)

        menu.addItem(NSMenuItem.separator())

        let historyItem = NSMenuItem(title: "作業履歴...", action: #selector(showHistory), keyEquivalent: "h")
        historyItem.image = NSImage(systemSymbolName: "clock.arrow.circlepath", accessibilityDescription: nil)
        menu.addItem(historyItem)

        let meigenHistoryItem = NSMenuItem(title: "名言ヒストリー...", action: #selector(showMeigenHistory), keyEquivalent: "")
        meigenHistoryItem.image = NSImage(systemSymbolName: "quote.bubble", accessibilityDescription: nil)
        menu.addItem(meigenHistoryItem)

        let reportItem = NSMenuItem(title: "レポート...", action: #selector(showReport), keyEquivalent: "r")
        reportItem.image = NSImage(systemSymbolName: "chart.bar", accessibilityDescription: nil)
        menu.addItem(reportItem)

        let settingsItem = NSMenuItem(title: "設定...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        menu.addItem(settingsItem)

        let aboutItem = NSMenuItem(title: "iruka-kun について", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
        menu.addItem(aboutItem)

        // Character switch section
        menu.addItem(NSMenuItem.separator())
        buildCharacterSection(in: menu)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "iruka-kun を終了", action: #selector(quit), keyEquivalent: "q")
        quitItem.image = NSImage(systemSymbolName: "xmark.circle", accessibilityDescription: nil)
        menu.addItem(quitItem)

        for item in menu.items {
            item.target = self
        }

        statusItem?.menu = menu
    }

    private func buildCharacterSection(in menu: NSMenu) {
        let headerItem = NSMenuItem(title: "キャラクター", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        let currentType = currentCharacterProvider?() ?? .iruka

        // Built-in characters
        for type in CharacterType.builtInCases {
            let item = NSMenuItem(title: "  \(type.displayName)", action: #selector(selectCharacter(_:)), keyEquivalent: "")
            item.representedObject = type.id
            if type == currentType {
                item.state = .on
            }
            menu.addItem(item)
        }

        // Custom characters
        let customNames = customCharacterNamesProvider?() ?? []
        for name in customNames {
            let type = CharacterType.custom(name)
            let item = NSMenuItem(title: "  \(name)", action: #selector(selectCharacter(_:)), keyEquivalent: "")
            item.representedObject = type.id
            if type == currentType {
                item.state = .on
            }

            // Submenu for delete
            let submenu = NSMenu()
            let deleteItem = NSMenuItem(title: "削除", action: #selector(deleteCustomCharacter(_:)), keyEquivalent: "")
            deleteItem.representedObject = name
            deleteItem.target = self
            submenu.addItem(deleteItem)
            item.submenu = submenu

            menu.addItem(item)
        }

        // Add custom character
        let addItem = NSMenuItem(title: "＋ 画像を追加...", action: #selector(addCustomCharacter), keyEquivalent: "")
        menu.addItem(addItem)
    }

    private func buildPresetSection(in menu: NSMenu) {
        let presets = presetsProvider?() ?? []
        let current = currentPresetProvider?()

        let headerItem = NSMenuItem(title: "作業カテゴリ", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        let noneItem = NSMenuItem(title: "  なし", action: #selector(selectNonePreset), keyEquivalent: "")
        if current == nil {
            noneItem.state = .on
        }
        menu.addItem(noneItem)

        for preset in presets {
            let item = NSMenuItem(title: "  \(preset)", action: #selector(selectPreset(_:)), keyEquivalent: "")
            item.representedObject = preset
            if preset == current {
                item.state = .on
            }
            menu.addItem(item)
        }

        let addItem = NSMenuItem(title: "＋ プリセットを追加...", action: #selector(addPreset), keyEquivalent: "")
        menu.addItem(addItem)
    }

    @objc private func selectCharacter(_ sender: NSMenuItem) {
        guard let typeId = sender.representedObject as? String,
              let type = CharacterType(id: typeId) else { return }
        onSwitchCharacter?(type)
    }

    @objc private func addCustomCharacter() {
        let panel = NSOpenPanel()
        panel.title = "キャラクター画像を選択"
        panel.allowedContentTypes = [.png, .jpeg, .gif, .tiff]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        NSApp.activate(ignoringOtherApps: true)
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

        // Ask for a name
        let alert = NSAlert()
        alert.messageText = "キャラクター名を入力"
        alert.informativeText = "メニューに表示される名前です"
        alert.addButton(withTitle: "追加")
        alert.addButton(withTitle: "キャンセル")
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.placeholderString = "キャラクター名"
        textField.stringValue = url.deletingPathExtension().lastPathComponent
        alert.accessoryView = textField
        alert.window.initialFirstResponder = textField

        let nameResponse = alert.runModal()
        guard nameResponse == .alertFirstButtonReturn else { return }
        let name = textField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        onAddCustomCharacter?(name, url)
    }

    @objc private func deleteCustomCharacter(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }

        let alert = NSAlert()
        alert.messageText = "「\(name)」を削除しますか？"
        alert.informativeText = "この操作は取り消せません。"
        alert.addButton(withTitle: "削除")
        alert.addButton(withTitle: "キャンセル")
        alert.alertStyle = .warning

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        onRemoveCustomCharacter?(name)
    }

    @objc private func selectNonePreset() {
        onClearPreset?()
    }

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

    @objc private func toggleWork() { onToggleWork?() }
    @objc private func showHistory() { onShowHistory?() }
    @objc private func showMeigenHistory() { onShowMeigenHistory?() }
    @objc private func showReport() { onShowReport?() }
    @objc private func openSettings() { onOpenSettings?() }
    @objc private func quit() { onQuit?() }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }
}
