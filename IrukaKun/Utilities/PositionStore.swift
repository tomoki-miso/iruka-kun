import Foundation

/// Position persistence with multi-monitor support
///
/// Stores character window positions per screen using screen geometry as identifier.
/// Format: "screen_<width>x<height>_<x>_<y>"
///
/// Backward compatible with legacy single-position format (iruka_position_x/y).
/// Automatic migration on first load in new environment.
final class PositionStore: Sendable {
    private nonisolated(unsafe) let defaults: UserDefaults
    private static let xKey = "iruka_position_x"
    private static let yKey = "iruka_position_y"
    private static let screenPositionsKey = "iruka_screen_positions"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Screen-specific positions

    func save(position: CGPoint, for screenId: String) {
        var positions = loadAllScreenPositions()
        positions[screenId] = ["x": position.x, "y": position.y]
        defaults.set(positions, forKey: Self.screenPositionsKey)
    }

    func loadPosition(for screenId: String) -> CGPoint? {
        let positions = loadAllScreenPositions()
        guard let pos = positions[screenId] as? [String: CGFloat],
              let x = pos["x"],
              let y = pos["y"] else { return nil }
        return CGPoint(x: x, y: y)
    }

    private func loadAllScreenPositions() -> [String: Any] {
        defaults.object(forKey: Self.screenPositionsKey) as? [String: Any] ?? [:]
    }

    // MARK: - Backward compatibility (Legacy single position)

    func save(position: CGPoint) {
        defaults.set(Double(position.x), forKey: Self.xKey)
        defaults.set(Double(position.y), forKey: Self.yKey)
    }

    func loadPosition() -> CGPoint? {
        guard defaults.object(forKey: Self.xKey) != nil else { return nil }
        let x = defaults.double(forKey: Self.xKey)
        let y = defaults.double(forKey: Self.yKey)
        return CGPoint(x: x, y: y)
    }

    func loadLegacyPosition() -> CGPoint? {
        loadPosition()
    }

    // MARK: - Migration utility

    func migrateToScreenSpecific(for screenId: String) {
        if let legacyPos = loadLegacyPosition() {
            save(position: legacyPos, for: screenId)
        }
    }
}
