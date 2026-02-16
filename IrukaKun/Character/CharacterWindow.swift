import AppKit

@MainActor
final class CharacterWindow: NSWindow {
    static let characterSize = CGSize(width: 128, height: 128)
    private let positionStore = PositionStore()

    init() {
        let initialFrame = NSRect(origin: .zero, size: Self.characterSize)
        super.init(
            contentRect: initialFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        isReleasedWhenClosed = false
        ignoresMouseEvents = false

        restorePosition()
    }

    override var canBecomeKey: Bool { true }

    func savePosition() {
        positionStore.save(position: frame.origin)
    }

    private func restorePosition() {
        if let saved = positionStore.loadPosition() {
            setFrameOrigin(saved)
        } else {
            setFrameOrigin(Self.defaultOrigin())
        }
    }

    private static func defaultOrigin() -> CGPoint {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        return CGPoint(
            x: screenFrame.maxX - characterSize.width - 40,
            y: screenFrame.minY + 40
        )
    }
}
