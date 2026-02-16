import AppKit

@MainActor
final class CharacterController {
    private let stateMachine = StateMachine()
    private let dialogueManager = DialogueManager()
    private let characterWindow = CharacterWindow()
    private let characterView: CharacterView
    private let bubbleView = BubbleView()

    private var dialogueTimer: Timer?
    private var idleTimer: Timer?
    private var stateRevertTimer: Timer?
    private var lastTimeOfDay: TimeOfDay?

    // Intervals
    private let dialogueInterval: TimeInterval = 900 // 15 minutes
    private let idleTimeout: TimeInterval = 1800     // 30 minutes
    private let temporaryStateDuration: TimeInterval = 3.0

    var isCharacterVisible: Bool { characterWindow.isVisible }
    var currentState: CharacterState { stateMachine.currentState }
    var onStateChanged: ((CharacterState) -> Void)?

    init() {
        characterView = CharacterView(frame: NSRect(origin: .zero, size: CharacterWindow.characterSize))
        characterWindow.contentView = characterView
        setupCallbacks()
        setupTimers()
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
            self?.stateMachine.handleEvent(.dragStarted)
            self?.showDialogueForEvent(.dragStarted)
            self?.scheduleStateRevert()
        }
        characterView.onDragEnded = { [weak self] _ in
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
    }

    // MARK: - Event Handling

    private func handleClick() {
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
        let charFrame = characterView.frame
        bubbleView.show(text: text, relativeTo: charFrame, in: characterWindow)
    }
}
