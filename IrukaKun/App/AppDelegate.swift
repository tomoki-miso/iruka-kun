import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarController = StatusBarController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController.setup()
        statusBarController.onToggleCharacter = { [weak self] in
            NSLog("Toggle character")
        }
        statusBarController.onQuit = {
            NSApp.terminate(nil)
        }
        NSLog("iruka-kun launched")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
