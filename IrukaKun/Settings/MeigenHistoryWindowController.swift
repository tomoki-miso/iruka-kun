import AppKit
import SwiftUI

@MainActor
final class MeigenHistoryWindowController {
    private var window: NSWindow?

    func show(historyStore: MeigenHistoryStore) {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let view = MeigenHistoryView(historyStore: historyStore)
        let hostingController = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "名言ヒストリー"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 450, height: 500))
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window

        NSApp.activate(ignoringOtherApps: true)
    }
}
