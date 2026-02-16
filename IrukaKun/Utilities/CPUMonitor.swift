import Foundation

final class CPUMonitor: @unchecked Sendable {
    enum Level: Equatable, Sendable {
        case low      // < 30%
        case medium   // 30–70%
        case high     // > 70%
    }

    private var prevTicks: (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64) = (0, 0, 0, 0)

    init() {
        // Warm up: first sample establishes baseline
        _ = sample()
    }

    func sample() -> (usage: Double, level: Level) {
        var loadInfo = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &loadInfo) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return (0, .low) }

        let ticks = (
            user: UInt64(loadInfo.cpu_ticks.0),
            system: UInt64(loadInfo.cpu_ticks.1),
            idle: UInt64(loadInfo.cpu_ticks.2),
            nice: UInt64(loadInfo.cpu_ticks.3)
        )

        let delta = (
            user: ticks.user - prevTicks.user,
            system: ticks.system - prevTicks.system,
            idle: ticks.idle - prevTicks.idle,
            nice: ticks.nice - prevTicks.nice
        )

        prevTicks = ticks

        let total = delta.user + delta.system + delta.idle + delta.nice
        guard total > 0 else { return (0, .low) }

        let used = delta.user + delta.system + delta.nice
        let usage = Double(used) / Double(total) * 100.0

        let level: Level
        if usage > 70 { level = .high }
        else if usage > 30 { level = .medium }
        else { level = .low }

        return (usage, level)
    }
}
