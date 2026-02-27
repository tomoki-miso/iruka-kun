import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarController = StatusBarController()
    private let settingsWindowController = SettingsWindowController()
    private let workHistoryWindowController = WorkHistoryWindowController()
    private let meigenHistoryWindowController = MeigenHistoryWindowController()
    private let workHistoryStore = WorkHistoryStore()
    private let meigenHistoryStore = MeigenHistoryStore()
    private var workTracker: WorkTracker?
    private var characterController: CharacterController?
    private var commandExplainWatcher: CommandExplainWatcher?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[iruka-kun] applicationDidFinishLaunching called")
        HookInstaller.installIfNeeded()
        characterController = CharacterController()
        characterController?.meigenHistoryStore = meigenHistoryStore
        characterController?.showCharacter()

        workTracker = WorkTracker(historyStore: workHistoryStore)
        setupMenuBar()
        setupWorkTracker()
        setupCommandExplainWatcher()
        NSLog("[iruka-kun] setup complete")
    }

    func applicationWillTerminate(_ notification: Notification) {
        workTracker?.stop()
        commandExplainWatcher?.stop()
    }

    private func setupMenuBar() {
        statusBarController.currentCharacterProvider = { [weak self] in
            self?.characterController?.currentCharacterType ?? .iruka
        }
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
        statusBarController.onShowMeigenHistory = { [weak self] in
            guard let self else { return }
            self.meigenHistoryWindowController.show(historyStore: self.meigenHistoryStore)
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
            self?.statusBarController.updateWorkMenu()
        }
        statusBarController.onClearPreset = { [weak self] in
            self?.workTracker?.clearPreset()
            self?.statusBarController.updateWorkMenu()
        }
        statusBarController.onAddPreset = { [weak self] name in
            self?.workHistoryStore.addPreset(name)
            self?.workTracker?.switchPreset(to: name)
            self?.statusBarController.updateWorkMenu()
        }
        statusBarController.onSwitchCharacter = { [weak self] type in
            self?.characterController?.switchCharacter(to: type)
        }
        statusBarController.customCharacterNamesProvider = {
            CustomCharacterManager.shared.customCharacterNames()
        }
        statusBarController.onAddCustomCharacter = { [weak self] name, url in
            _ = self?.characterController?.addCustomCharacter(name: name, imageURL: url)
            self?.statusBarController.updateWorkMenu()
        }
        statusBarController.onRemoveCustomCharacter = { [weak self] id in
            self?.characterController?.removeCustomCharacter(id)
            self?.statusBarController.updateWorkMenu()
        }
        statusBarController.onQuit = {
            NSApp.terminate(nil)
        }

        characterController?.onStateChanged = { [weak self] _ in
            self?.statusBarController.updateStateDisplay()
        }
        characterController?.onCharacterChanged = { [weak self] type in
            self?.statusBarController.updateMenuBarIcon(type)
            self?.statusBarController.updateWorkMenu()
            self?.statusBarController.updateStateDisplay()
        }

        statusBarController.updateWorkMenu()
    }

    private func setupCommandExplainWatcher() {
        let watcher = CommandExplainWatcher()
        watcher.onCommandExplain = { [weak self] command, explanation in
            Task { @MainActor in
                self?.characterController?.showCommandExplanation(command: command, explanation: explanation)
            }
        }
        watcher.onCommandDismiss = { [weak self] in
            Task { @MainActor in
                self?.characterController?.dismissCommandExplanation()
            }
        }
        watcher.start()

        characterController?.onAllowCommand = { [weak self] in
            self?.commandExplainWatcher?.respond(decision: "allow")
        }
        characterController?.onAllowAlwaysCommand = { [weak self] in
            self?.commandExplainWatcher?.respond(decision: "allowAlways")
        }
        characterController?.onDenyCommand = { [weak self] in
            self?.commandExplainWatcher?.respond(decision: "deny")
        }
        commandExplainWatcher = watcher
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
