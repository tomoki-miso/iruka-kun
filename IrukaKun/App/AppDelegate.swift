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
