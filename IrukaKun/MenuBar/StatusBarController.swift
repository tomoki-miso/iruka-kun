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
