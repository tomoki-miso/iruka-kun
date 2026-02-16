import AppKit

@MainActor
final class SpriteAnimator {
    private var framesByState: [CharacterState: [NSImage]] = [:]
    private var currentFrames: [NSImage] = []
    private var currentFrameIndex = 0
    private var timer: Timer?
    private let fps: Double = 10.0

    var onFrameChanged: ((NSImage) -> Void)?

    init() {
        loadSprites()
    }

    private func loadSprites() {
        for state in [CharacterState.idle, .happy, .sleeping, .surprised, .bored] {
            let prefix = spritePrefix(for: state)
            var frames: [NSImage] = []
            for i in 0..<10 {
                let name = "\(prefix)_\(i)"
                if let image = NSImage(named: name) {
                    frames.append(image)
                }
            }
            // If no specific frames, fall back to idle frame 0
            if frames.isEmpty, let fallback = NSImage(named: "iruka_idle_0") {
                frames.append(fallback)
            }
            framesByState[state] = frames
        }
    }

    private func spritePrefix(for state: CharacterState) -> String {
        switch state {
        case .idle: return "iruka_idle"
        case .happy: return "iruka_happy"
        case .sleeping: return "iruka_sleeping"
        case .surprised: return "iruka_surprised"
        case .bored: return "iruka_bored"
        }
    }

    func play(state: CharacterState) {
        stop()
        currentFrames = framesByState[state] ?? []
        currentFrameIndex = 0
        guard !currentFrames.isEmpty else { return }
        onFrameChanged?(currentFrames[0])

        guard currentFrames.count > 1 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceFrame()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func advanceFrame() {
        guard !currentFrames.isEmpty else { return }
        currentFrameIndex = (currentFrameIndex + 1) % currentFrames.count
        onFrameChanged?(currentFrames[currentFrameIndex])
    }
}
