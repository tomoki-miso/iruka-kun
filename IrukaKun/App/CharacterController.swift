import AppKit

@MainActor
final class CharacterController {
    private let stateMachine = StateMachine()
    private let dialogueManager = DialogueManager()
    private let characterWindow = CharacterWindow()
    private let characterView: CharacterView
    private let bubbleView = BubbleView()
    private let soundPlayer = SoundPlayer()
    private let workTimerOverlay = WorkTimerOverlay()
    private let cpuMonitor = CPUMonitor()

    private var dialogueTimer: Timer?
    private var idleTimer: Timer?
    private var stateRevertTimer: Timer?
    private var floatTimer: Timer?
    private var cpuTimer: Timer?
    private var lastTimeOfDay: TimeOfDay?
    private var lastCPULevel: CPUMonitor.Level = .low
    private var floatPhase: Double = 0
    private var baseWindowOrigin: CGPoint = .zero
    private var isFloating = false

    // Intervals
    private let dialogueInterval: TimeInterval = 900 // 15 minutes
    private let idleTimeout: TimeInterval = 1800     // 30 minutes
    private let temporaryStateDuration: TimeInterval = 3.0

    // Floating
    private let floatAmplitude: CGFloat = 4.0
    private let floatPeriod: Double = 2.5

    var isCharacterVisible: Bool { characterWindow.isVisible }
    var currentState: CharacterState { stateMachine.currentState }
    var onStateChanged: ((CharacterState) -> Void)?

    init() {
        characterView = CharacterView(frame: NSRect(origin: .zero, size: CharacterWindow.characterSize))
        characterWindow.contentView = characterView
        setupCallbacks()
        setupTimers()
        workTimerOverlay.attach(to: characterWindow)
        startFloating()
    }

    func updateWorkTimer(elapsed: TimeInterval, state: WorkTracker.State) {
        workTimerOverlay.update(elapsed: elapsed, state: state)
    }

    func showCharacter() {
        characterWindow.orderFront(nil)
    }

    func hideCharacter() {
        characterWindow.orderOut(nil)
    }

    func toggleCharacter() {
        if characterWindow.isVisible {
            hideCharacter()
        } else {
            showCharacter()
        }
    }

    // MARK: - Setup

    private func setupCallbacks() {
        // State machine → animation
        stateMachine.onStateChanged = { [weak self] newState in
            self?.characterView.animator.play(state: newState)
            self?.onStateChanged?(newState)
        }

        // View events → state machine
        characterView.onClicked = { [weak self] in
            self?.handleClick()
        }
        characterView.onDragStarted = { [weak self] in
            self?.pauseFloating()
            self?.stateMachine.handleEvent(.dragStarted)
            self?.showDialogueForEvent(.dragStarted)
            self?.scheduleStateRevert()
        }
        characterView.onDragEnded = { [weak self] position in
            self?.resumeFloating(from: position)
            self?.characterWindow.savePosition()
            self?.resetIdleTimer()
        }
    }

    private func setupTimers() {
        // Periodic dialogue timer
        dialogueTimer = Timer.scheduledTimer(withTimeInterval: dialogueInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.showTimeBasedDialogue()
            }
        }

        // Idle detection timer
        resetIdleTimer()

        // Time-of-day check (every minute)
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkTimeOfDay()
            }
        }

        // Initial time check
        checkTimeOfDay()

        // CPU monitoring (every 5 seconds)
        cpuTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkCPU()
            }
        }
    }

    // MARK: - CPU Monitoring

    private func checkCPU() {
        let (_, level) = cpuMonitor.sample()
        guard level != lastCPULevel else { return }
        lastCPULevel = level

        let newBaseState: CharacterState
        switch level {
        case .low:      newBaseState = .idle
        case .medium:   newBaseState = .happy
        case .high:     newBaseState = .surprised
        }

        stateMachine.baseState = newBaseState

        // If currently in a base-like state, transition immediately
        let current = stateMachine.currentState
        if current == .idle || current == .happy || current == .surprised || current == .bored {
            if current != newBaseState && current != .sleeping {
                stateMachine.handleEvent(.temporaryStateExpired)
            }
        }
    }

    // MARK: - Event Handling

    private func handleClick() {
        soundPlayer.playClick()
        stateMachine.handleEvent(.clicked)
        showDialogueForEvent(.clicked)
        scheduleStateRevert()
        resetIdleTimer()
    }

    private func scheduleStateRevert() {
        stateRevertTimer?.invalidate()
        stateRevertTimer = Timer.scheduledTimer(withTimeInterval: temporaryStateDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stateMachine.handleEvent(.temporaryStateExpired)
            }
        }
    }

    private func resetIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: idleTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stateMachine.handleEvent(.idleTimeout)
                self?.showDialogueForEvent(.idleTimeout)
            }
        }
    }

    private func checkTimeOfDay() {
        let current = TimeOfDay.current()
        guard current != lastTimeOfDay else { return }
        lastTimeOfDay = current
        if current == .night {
            stateMachine.handleEvent(.nightTime)
        } else if stateMachine.currentState == .sleeping {
            stateMachine.handleEvent(.dayTime)
        }
    }

    // MARK: - Floating Animation

    private func startFloating() {
        baseWindowOrigin = characterWindow.frame.origin
        isFloating = true
        floatTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateFloat()
            }
        }
    }

    private func updateFloat() {
        guard isFloating else { return }
        floatPhase += (2 * .pi) / (30.0 * floatPeriod)
        if floatPhase > 2 * .pi { floatPhase -= 2 * .pi }
        let offset = CGFloat(sin(floatPhase)) * floatAmplitude
        characterWindow.setFrameOrigin(CGPoint(x: baseWindowOrigin.x, y: baseWindowOrigin.y + offset))
    }

    private func pauseFloating() {
        isFloating = false
    }

    private func resumeFloating(from newOrigin: CGPoint) {
        baseWindowOrigin = newOrigin
        floatPhase = 0
        isFloating = true
    }

    // MARK: - Dialogue

    private func showDialogueForEvent(_ event: CharacterEvent) {
        guard let text = dialogueManager.dialogueForEvent(event) else { return }
        showBubble(text: text)
    }

    private func showTimeBasedDialogue() {
        let hour = Calendar.current.component(.hour, from: Date())
        guard let text = dialogueManager.timeBasedDialogue(hour: hour) else { return }
        showBubble(text: text)
    }

    private func showBubble(text: String) {
        let charFrame = NSRect(origin: .zero, size: CharacterWindow.characterSize)
        bubbleView.show(text: text, relativeTo: charFrame, in: characterWindow)
    }
}
