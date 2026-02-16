import AppKit

@MainActor
final class CharacterWindow: NSWindow {
    static let characterSize = CGSize(width: 128, height: 128)
    private let positionStore = PositionStore()
    private let screenUtility = ScreenUtility()

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

        screenUtility.onScreenConfigurationChanged = { [weak self] in
            self?.ensureOnScreen()
        }
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

    func ensureOnScreen() {
        let origin = frame.origin
        if !ScreenUtility.isPointOnAnyScreen(origin) {
            let safeFrame = ScreenUtility.nearestScreenFrame(to: origin)
            let safeOrigin = CGPoint(
                x: min(origin.x, safeFrame.maxX - frame.width),
                y: min(origin.y, safeFrame.maxY - frame.height)
            )
            setFrameOrigin(safeOrigin)
            savePosition()
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
