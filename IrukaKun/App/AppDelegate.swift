import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarController = StatusBarController()
    private let settingsWindowController = SettingsWindowController()
    private var characterController: CharacterController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        characterController = CharacterController()
        characterController?.showCharacter()
        setupMenuBar()
    }

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

        characterController?.onStateChanged = { [weak self] _ in
            self?.statusBarController.updateStateDisplay()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
