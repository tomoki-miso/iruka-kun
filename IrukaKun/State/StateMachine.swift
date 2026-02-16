@MainActor
final class StateMachine {
    private(set) var currentState: CharacterState = .idle
    var baseState: CharacterState = .idle
    var onStateChanged: ((CharacterState) -> Void)?

    func handleEvent(_ event: CharacterEvent) {
        let newState = nextState(for: event)
        guard newState != currentState else { return }
        currentState = newState
        onStateChanged?(newState)
    }

    private func nextState(for event: CharacterEvent) -> CharacterState {
        switch (currentState, event) {
        // Sleeping state is sticky — only dayTime exits it
        case (.sleeping, .dayTime):
            return .idle
        case (.sleeping, _):
            return .sleeping

        // Night time always transitions to sleeping
        case (_, .nightTime):
            return .sleeping

        // Click transitions to happy from any non-sleeping state
        case (_, .clicked):
            return .happy

        // Drag transitions to surprised
        case (_, .dragStarted):
            return .surprised

        // Idle timeout from idle
        case (.idle, .idleTimeout):
            return .bored

        // Temporary states expire back to base state
        case (.happy, .temporaryStateExpired),
             (.surprised, .temporaryStateExpired),
             (.bored, .temporaryStateExpired):
            return baseState

        default:
            return currentState
        }
    }
}
