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
        NSLog("[iruka-kun] statusItem created: \(statusItem != nil)")

        guard let button = statusItem?.button else {
            NSLog("[iruka-kun] button is nil!")
            return
        }
        let img = NSImage(systemSymbolName: "fish.fill", accessibilityDescription: "iruka-kun")
        NSLog("[iruka-kun] fish.fill image: \(img != nil)")
        button.image = img

        rebuildMenu()
        NSLog("[iruka-kun] menu built")
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
