import Foundation

final class PositionStore: Sendable {
    private nonisolated(unsafe) let defaults: UserDefaults
    private static let xKey = "iruka_position_x"
    private static let yKey = "iruka_position_y"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

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
}
