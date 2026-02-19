import AppKit

@MainActor
final class WorkTracker {
    enum State: Equatable, Sendable {
        case idle
        case tracking
        case paused
    }

    private(set) var state: State = .idle
    private(set) var elapsedTime: TimeInterval = 0
    var currentPreset: String?

    var onTick: ((TimeInterval) -> Void)?
    var onStateChanged: ((State) -> Void)?

    private let historyStore: WorkHistoryStore
    private let idleThreshold: TimeInterval

    private var tickTimer: Timer?
    private var sessionStartDate: Date?
    private var lastActivityDate: Date?
    private var eventMonitor: Any?

    init(historyStore: WorkHistoryStore, idleThreshold: TimeInterval = 300) {
        self.historyStore = historyStore
        self.idleThreshold = idleThreshold
    }

    var todayTotal: TimeInterval {
        historyStore.todayTotal() + (state != .idle ? elapsedTime : 0)
    }

    func switchPreset(to preset: String) {
        if state != .idle, elapsedTime > 0 {
            historyStore.addDuration(elapsedTime, for: sessionStartDate ?? Date(), preset: currentPreset)
            elapsedTime = 0
            sessionStartDate = Date()
        }
        currentPreset = preset
    }

    func clearPreset() {
        if state != .idle, elapsedTime > 0 {
            historyStore.addDuration(elapsedTime, for: sessionStartDate ?? Date(), preset: currentPreset)
            elapsedTime = 0
            sessionStartDate = Date()
        }
        currentPreset = nil
    }

    func start() {
        guard state == .idle else { return }
        elapsedTime = 0
        sessionStartDate = Date()
        lastActivityDate = Date()
        transition(to: .tracking)
        startTickTimer()
        startEventMonitor()
    }

    func stop() {
        guard state != .idle else { return }
        stopTickTimer()
        stopEventMonitor()
        if elapsedTime > 0 {
            historyStore.addDuration(elapsedTime, for: sessionStartDate ?? Date(), preset: currentPreset)
        }
        elapsedTime = 0
        sessionStartDate = nil
        transition(to: .idle)
    }

    // MARK: - Private

    private func transition(to newState: State) {
        guard newState != state else { return }
        state = newState
        onStateChanged?(newState)
    }

    private func startTickTimer() {
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopTickTimer() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func tick() {
        guard state != .idle else { return }

        // Check for day change
        if let startDate = sessionStartDate {
            let startDay = Calendar.current.startOfDay(for: startDate)
            let today = Calendar.current.startOfDay(for: Date())
            if startDay != today {
                // Day changed — save previous day and reset
                historyStore.addDuration(elapsedTime, for: startDate, preset: currentPreset)
                elapsedTime = 0
                sessionStartDate = Date()
            }
        }

        // Check for idle timeout
        if state == .tracking, let lastActivity = lastActivityDate {
            if Date().timeIntervalSince(lastActivity) >= idleThreshold {
                transition(to: .paused)
            }
        }

        // Only count time when tracking (not paused)
        if state == .tracking {
            elapsedTime += 1
            onTick?(elapsedTime)
        } else if state == .paused {
            // Still fire onTick so UI can update the "(休止中)" display
            onTick?(elapsedTime)
        }
    }

    private func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .keyDown, .leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleUserActivity()
            }
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func handleUserActivity() {
        lastActivityDate = Date()
        if state == .paused {
            transition(to: .tracking)
        }
    }
}
