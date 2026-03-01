import AppKit
import SwiftUI

@MainActor
final class ReportWindowController: NSWindowController {
    private let historyStore: WorkHistoryStore

    init(historyStore: WorkHistoryStore) {
        self.historyStore = historyStore
        
        let contentView = ReportView(historyStore: historyStore)
        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "作業レポート"
        window.setFrame(NSRect(x: 100, y: 100, width: 700, height: 600), display: true)
        
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
