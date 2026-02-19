import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarController = StatusBarController()
    private let settingsWindowController = SettingsWindowController()
    private let workHistoryWindowController = WorkHistoryWindowController()
    private let workHistoryStore = WorkHistoryStore()
    private var workTracker: WorkTracker?
    private var characterController: CharacterController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[iruka-kun] applicationDidFinishLaunching called")
        characterController = CharacterController()
        characterController?.showCharacter()

        workTracker = WorkTracker(historyStore: workHistoryStore)
        setupMenuBar()
        setupWorkTracker()
        NSLog("[iruka-kun] setup complete")
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
        statusBarController.onToggleWork = { [weak self] in
            self?.toggleWork()
        }
        statusBarController.onOpenSettings = { [weak self] in
            self?.settingsWindowController.show()
        }
        statusBarController.onShowHistory = { [weak self] in
            guard let self else { return }
            self.workHistoryWindowController.show(historyStore: self.workHistoryStore)
        }
        statusBarController.presetsProvider = { [weak self] in
            self?.workHistoryStore.presets ?? []
        }
        statusBarController.currentPresetProvider = { [weak self] in
            self?.workTracker?.currentPreset
        }
        statusBarController.todayBreakdownProvider = { [weak self] in
            self?.workHistoryStore.todayBreakdown() ?? [:]
        }
        statusBarController.onSelectPreset = { [weak self] name in
            self?.workTracker?.switchPreset(to: name)
        }
        statusBarController.onAddPreset = { [weak self] name in
            self?.workHistoryStore.addPreset(name)
            self?.workTracker?.switchPreset(to: name)
            self?.statusBarController.updateWorkMenu()
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
            self?.characterController?.updateWorkTimer(
                elapsed: elapsed,
                state: self?.workTracker?.state ?? .idle,
                preset: self?.workTracker?.currentPreset
            )
        }
        workTracker?.onStateChanged = { [weak self] _ in
            self?.statusBarController.updateWorkMenu()
            let elapsed = self?.workTracker?.elapsedTime ?? 0
            self?.statusBarController.updateTimerDisplay(elapsed: elapsed)
            self?.characterController?.updateWorkTimer(
                elapsed: elapsed,
                state: self?.workTracker?.state ?? .idle,
                preset: self?.workTracker?.currentPreset
            )
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
