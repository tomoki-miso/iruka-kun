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
