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
