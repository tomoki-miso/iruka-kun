import AppKit

@MainActor
final class ScreenUtility {
    var onScreenConfigurationChanged: (() -> Void)?

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenDidChange(_ notification: Notification) {
        onScreenConfigurationChanged?()
    }

    static func isPointOnAnyScreen(_ point: CGPoint) -> Bool {
        NSScreen.screens.contains { screen in
            screen.frame.contains(point)
        }
    }

    static func nearestScreenFrame(to point: CGPoint) -> NSRect {
        let screen = NSScreen.screens.min(by: { screenA, screenB in
            let distA = distance(from: point, to: screenA.visibleFrame)
            let distB = distance(from: point, to: screenB.visibleFrame)
            return distA < distB
        })
        return screen?.visibleFrame ?? (NSScreen.main?.visibleFrame ?? .zero)
    }

    private static func distance(from point: CGPoint, to rect: NSRect) -> CGFloat {
        let cx = max(rect.minX, min(point.x, rect.maxX))
        let cy = max(rect.minY, min(point.y, rect.maxY))
        return hypot(point.x - cx, point.y - cy)
    }
}
