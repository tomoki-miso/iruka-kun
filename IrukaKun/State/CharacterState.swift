enum CharacterState: Equatable, Sendable {
    case idle
    case happy
    case sleeping
    case surprised
    case bored
}

enum CharacterEvent: Sendable {
    case clicked
    case dragStarted
    case nightTime
    case dayTime
    case idleTimeout
    case temporaryStateExpired
}
