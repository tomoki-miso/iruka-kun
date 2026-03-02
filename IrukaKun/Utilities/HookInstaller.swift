import Foundation

@MainActor
final class HookInstaller {
    private static let installedVersionKey = "iruka_hook_installed_version"
    private static let settingsPath = "~/.claude/settings.json"

    private static let scripts: [(resource: String, dest: String)] = [
        ("explain-command", "~/.claude/hooks/explain-command.sh"),
        ("dismiss-explain", "~/.claude/hooks/dismiss-explain.sh"),
    ]

    /// 期待するフック設定。毎回起動時に検証される。
    private static let expectedHooks: [(phase: String, matcher: String, scriptIndex: Int, timeout: Int)] = [
        ("PreToolUse", "Bash", 0, 60),
        ("PostToolUse", "Bash", 1, 5),
    ]

    static func installIfNeeded() {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let installedVersion = UserDefaults.standard.string(forKey: installedVersionKey)
        let isNewVersion = installedVersion != appVersion

        do {
            // スクリプトファイル: バージョン更新時 or ファイル欠損時にインストール
            if isNewVersion || !allScriptsExist() {
                NSLog("[iruka-kun] HookInstaller: installing scripts (v\(appVersion))...")
                try installScripts()
                try cleanupOldScripts()
                UserDefaults.standard.set(appVersion, forKey: installedVersionKey)
            }

            // settings.json: 毎回起動時に検証・修正
            try ensureHooksRegistered()
        } catch {
            NSLog("[iruka-kun] HookInstaller: install failed — \(error)")
        }
    }

    // MARK: - Script Install

    private static func allScriptsExist() -> Bool {
        let fm = FileManager.default
        return scripts.allSatisfy { script in
            let path = NSString(string: script.dest).expandingTildeInPath
            return fm.fileExists(atPath: path)
        }
    }

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

    // MARK: - Cleanup Old Scripts

    private static func cleanupOldScripts() throws {
        let fm = FileManager.default
        let oldScript = NSString(string: "~/.claude/hooks/notify-explain.sh").expandingTildeInPath
        if fm.fileExists(atPath: oldScript) {
            try fm.removeItem(atPath: oldScript)
            NSLog("[iruka-kun] HookInstaller: removed old notify-explain.sh")
        }
    }

    // MARK: - Settings Registration (毎回検証)

    private static func ensureHooksRegistered() throws {
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

        // 古い Notification フックを削除
        cleanupOldHooks(in: &hooks)

        // 期待するフックがすべて登録されているか検証
        var needsWrite = false

        for expected in expectedHooks {
            let command = NSString(string: scripts[expected.scriptIndex].dest).expandingTildeInPath
            if !isHookRegistered(in: hooks, phase: expected.phase, matcher: expected.matcher, command: command) {
                registerHook(in: &hooks, phase: expected.phase, matcher: expected.matcher, command: command, timeout: expected.timeout)
                needsWrite = true
                NSLog("[iruka-kun] HookInstaller: registered \(expected.phase) hook for \(expected.matcher)")
            }
        }

        if needsWrite {
            settings["hooks"] = hooks
            let jsonData = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted, .sortedKeys])
            try jsonData.write(to: settingsURL)
            NSLog("[iruka-kun] HookInstaller: settings.json updated")
        }
    }

    private static func cleanupOldHooks(in hooks: inout [String: Any]) {
        if var notificationHooks = hooks["Notification"] as? [[String: Any]] {
            notificationHooks.removeAll { entry in
                guard let entryHooks = entry["hooks"] as? [[String: Any]] else { return false }
                return entryHooks.allSatisfy { hook in
                    (hook["command"] as? String)?.contains("notify-explain") == true
                }
            }
            if notificationHooks.isEmpty {
                hooks.removeValue(forKey: "Notification")
            } else {
                hooks["Notification"] = notificationHooks
            }
        }
    }

    private static func isHookRegistered(in hooks: [String: Any], phase: String, matcher: String, command: String) -> Bool {
        guard let phaseHooks = hooks[phase] as? [[String: Any]] else { return false }
        guard let entry = phaseHooks.first(where: { ($0["matcher"] as? String) == matcher }) else { return false }
        guard let entryHooks = entry["hooks"] as? [[String: Any]] else { return false }
        return entryHooks.contains { ($0["command"] as? String) == command }
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
            entryHooks.append(hookEntry)
            entry["hooks"] = entryHooks
            phaseHooks[idx] = entry
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
