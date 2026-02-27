import Foundation

@MainActor
final class HookInstaller {
    private static let installedVersionKey = "iruka_hook_installed_version"
    private static let settingsPath = "~/.claude/settings.json"

    private static let scripts: [(resource: String, dest: String)] = [
        ("explain-command", "~/.claude/hooks/explain-command.sh"),
        ("notify-explain", "~/.claude/hooks/notify-explain.sh"),
        ("dismiss-explain", "~/.claude/hooks/dismiss-explain.sh"),
    ]

    static func installIfNeeded() {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let installedVersion = UserDefaults.standard.string(forKey: installedVersionKey)

        guard installedVersion != appVersion else {
            NSLog("[iruka-kun] HookInstaller: already installed (v\(appVersion))")
            return
        }

        NSLog("[iruka-kun] HookInstaller: installing hooks (v\(appVersion))...")

        do {
            try installScripts()
            try registerHooksInSettings()
            UserDefaults.standard.set(appVersion, forKey: installedVersionKey)
            NSLog("[iruka-kun] HookInstaller: install complete")
        } catch {
            NSLog("[iruka-kun] HookInstaller: install failed — \(error)")
        }
    }

    // MARK: - Script Install

    private static func installScripts() throws {
        let fm = FileManager.default
        for script in scripts {
            guard let sourceURL = Bundle.main.url(forResource: script.resource, withExtension: "sh") else {
                throw HookError.scriptNotInBundle(script.resource)
            }
            let expandedPath = NSString(string: script.dest).expandingTildeInPath
            let destURL = URL(fileURLWithPath: expandedPath)
            try fm.createDirectory(at: destURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try Data(contentsOf: sourceURL)
            try data.write(to: destURL)
            try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: expandedPath)
        }
    }

    // MARK: - Settings Registration

    private static func registerHooksInSettings() throws {
        let expandedPath = NSString(string: settingsPath).expandingTildeInPath
        let settingsURL = URL(fileURLWithPath: expandedPath)
        let fm = FileManager.default

        var settings: [String: Any]
        if fm.fileExists(atPath: expandedPath),
           let data = try? Data(contentsOf: settingsURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            settings = json
        } else {
            settings = [:]
        }

        var hooks = settings["hooks"] as? [String: Any] ?? [:]

        // PreToolUse: explain-command.sh
        let preCommand = NSString(string: scripts[0].dest).expandingTildeInPath
        registerHook(
            in: &hooks,
            phase: "PreToolUse",
            matcher: "Bash",
            command: preCommand,
            timeout: 60
        )

        // Notification: notify-explain.sh
        let notifyCommand = NSString(string: scripts[1].dest).expandingTildeInPath
        registerHook(
            in: &hooks,
            phase: "Notification",
            matcher: "",
            command: notifyCommand,
            timeout: 5
        )

        // PostToolUse: dismiss-explain.sh
        let postCommand = NSString(string: scripts[2].dest).expandingTildeInPath
        registerHook(
            in: &hooks,
            phase: "PostToolUse",
            matcher: "Bash",
            command: postCommand,
            timeout: 5
        )

        settings["hooks"] = hooks

        let jsonData = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted, .sortedKeys])
        try jsonData.write(to: settingsURL)
    }

    private static func registerHook(in hooks: inout [String: Any], phase: String, matcher: String, command: String, timeout: Int) {
        var phaseHooks = hooks[phase] as? [[String: Any]] ?? []

        let hookEntry: [String: Any] = [
            "type": "command",
            "command": command,
            "timeout": timeout
        ]

        if let idx = phaseHooks.firstIndex(where: { ($0["matcher"] as? String) == matcher }) {
            var entry = phaseHooks[idx]
            var entryHooks = entry["hooks"] as? [[String: Any]] ?? []
            let alreadyRegistered = entryHooks.contains { ($0["command"] as? String) == command }
            if !alreadyRegistered {
                entryHooks.append(hookEntry)
                entry["hooks"] = entryHooks
                phaseHooks[idx] = entry
            }
        } else {
            phaseHooks.append([
                "matcher": matcher,
                "hooks": [hookEntry]
            ])
        }

        hooks[phase] = phaseHooks
    }

    // MARK: - Errors

    private enum HookError: LocalizedError {
        case scriptNotInBundle(String)

        var errorDescription: String? {
            switch self {
            case .scriptNotInBundle(let name):
                return "\(name).sh not found in app bundle"
            }
        }
    }
}
