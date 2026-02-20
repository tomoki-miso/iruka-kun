import AppKit

@MainActor
final class SpriteAnimator {
    private var framesByState: [CharacterState: [NSImage]] = [:]
    private var currentFrames: [NSImage] = []
    private var currentFrameIndex = 0
    private var timer: Timer?
    private let fps: Double = 10.0

    private(set) var characterType: CharacterType

    var onFrameChanged: ((NSImage) -> Void)?

    init(characterType: CharacterType = .iruka) {
        self.characterType = characterType
        loadSprites()
    }

    private func loadSprites() {
        framesByState = [:]

        switch characterType {
        case .iruka, .rakko, .ono, .syacho:
            loadBuiltInSprites()
        case .custom(let id):
            loadCustomSprite(id: id)
        }
    }

    private func loadBuiltInSprites() {
        for state in [CharacterState.idle, .happy, .sleeping, .surprised, .bored] {
            let prefix = characterType.spritePrefix(for: state)
            var frames: [NSImage] = []
            for i in 0..<10 {
                let name = "\(prefix)_\(i)"
                if let image = NSImage(named: name) {
                    frames.append(image)
                }
            }
            if frames.isEmpty, let fallback = NSImage(named: characterType.fallbackSpriteName) {
                frames.append(fallback)
            }
            framesByState[state] = frames
        }
    }

    private func loadCustomSprite(id: String) {
        guard let image = CustomCharacterManager.shared.loadImage(for: id) else { return }
        for state in [CharacterState.idle, .happy, .sleeping, .surprised, .bored] {
            framesByState[state] = [image]
        }
    }

    func switchCharacter(_ type: CharacterType) {
        stop()
        characterType = type
        loadSprites()
    }

    func currentFallbackImage() -> NSImage? {
        switch characterType {
        case .iruka, .rakko, .ono, .syacho:
            return NSImage(named: characterType.fallbackSpriteName)
        case .custom(let id):
            return CustomCharacterManager.shared.loadImage(for: id)
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
