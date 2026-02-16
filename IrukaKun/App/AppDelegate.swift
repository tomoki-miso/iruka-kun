import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarController = StatusBarController()
    private let settingsWindowController = SettingsWindowController()
    private let workHistoryStore = WorkHistoryStore()
    private var workTracker: WorkTracker?
    private var characterController: CharacterController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        characterController = CharacterController()
        characterController?.showCharacter()

        workTracker = WorkTracker(historyStore: workHistoryStore)
        setupMenuBar()
        setupWorkTracker()
    }

    func applicationWillTerminate(_ notification: Notification) {
        workTracker?.stop()
    }

    private func setupMenuBar() {
        statusBarController.setup()
        statusBarController.currentStateProvider = { [weak self] in
            self?.characterController?.currentState ?? .idle
        }
        statusBarController.workStateProvider = { [weak self] in
            self?.workTracker?.state ?? .idle
        }
        statusBarController.todayTotalProvider = { [weak self] in
            self?.workTracker?.todayTotal ?? 0
        }
        statusBarController.onToggleCharacter = { [weak self] in
            self?.characterController?.toggleCharacter()
        }
        statusBarController.onToggleWork = { [weak self] in
            self?.toggleWork()
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

        statusBarController.updateWorkMenu()
    }

    private func setupWorkTracker() {
        workTracker?.onTick = { [weak self] elapsed in
            self?.statusBarController.updateTimerDisplay(elapsed: elapsed)
        }
        workTracker?.onStateChanged = { [weak self] _ in
            self?.statusBarController.updateWorkMenu()
            self?.statusBarController.updateTimerDisplay(elapsed: self?.workTracker?.elapsedTime ?? 0)
        }
    }

    private func toggleWork() {
        guard let tracker = workTracker else { return }
        if tracker.state == .idle {
            tracker.start()
        } else {
            tracker.stop()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
