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
