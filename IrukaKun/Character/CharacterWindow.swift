import AppKit

@MainActor
final class CharacterWindow: NSWindow {
    static let characterSize = CGSize(width: 128, height: 128)

    init() {
        let initialFrame = Self.defaultFrame()
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
    }

    override var canBecomeKey: Bool { true }

    private static func defaultFrame() -> NSRect {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let x = screenFrame.maxX - characterSize.width - 40
        let y = screenFrame.minY + 40
        return NSRect(origin: CGPoint(x: x, y: y), size: characterSize)
    }
}
