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
        let currentScreen = NSScreen.main ?? NSScreen.screens[0]
        let screenId = ScreenUtility.generateScreenIdentifier(for: currentScreen)
        positionStore.save(position: frame.origin, for: screenId)
    }

    private func restorePosition() {
        let currentScreen = NSScreen.main ?? NSScreen.screens[0]
        let screenId = ScreenUtility.generateScreenIdentifier(for: currentScreen)

        if let saved = positionStore.loadPosition(for: screenId) {
            setFrameOrigin(saved)
        } else if let legacyPos = positionStore.loadLegacyPosition() {
            // Migrate legacy position to new format
            positionStore.migrateToScreenSpecific(for: screenId)
            setFrameOrigin(legacyPos)
        } else {
            setFrameOrigin(Self.defaultOrigin())
        }
    }

    func ensureOnScreen() {
        let origin = frame.origin

        if !ScreenUtility.isPointOnAnyScreen(origin) {
            let safeFrame = ScreenUtility.nearestScreenFrame(to: origin)
            let safeOrigin = CGPoint(
                x: max(safeFrame.minX, min(origin.x, safeFrame.maxX - frame.width)),
                y: max(safeFrame.minY, min(origin.y, safeFrame.maxY - frame.height))
            )
            setFrameOrigin(safeOrigin)

            // Update stored position for current screen
            let currentScreen = NSScreen.screens.first(where: { $0.frame.contains(safeOrigin) }) ?? NSScreen.main!
            let screenId = ScreenUtility.generateScreenIdentifier(for: currentScreen)
            positionStore.save(position: safeOrigin, for: screenId)
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
