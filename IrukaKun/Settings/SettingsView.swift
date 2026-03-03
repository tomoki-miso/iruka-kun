import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var idleThresholdMinutes: Int = {
        let seconds = UserDefaults.standard.integer(forKey: "idleThresholdSeconds")
        return seconds > 0 ? seconds / 60 : 5
    }()
    @State private var enableAnimations: Bool = {
        UserDefaults.standard.object(forKey: "enableAnimations") as? Bool ?? true
    }()

    var body: some View {
        Form {
            Section("アプリケーション") {
                Toggle("ログイン時に自動起動", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                            NSLog("Failed to update login item: \(error)")
                        }
                    }
            }

            Section("作業トラッキング") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("待機タイムアウト")
                        Spacer()
                        Text("\(idleThresholdMinutes) 分")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(idleThresholdMinutes) },
                        set: { idleThresholdMinutes = Int($0) }
                    ), in: 1...30, step: 1)
                    .onChange(of: idleThresholdMinutes) { _, newValue in
                        UserDefaults.standard.set(newValue * 60, forKey: "idleThresholdSeconds")
                    }
                }
            }

            Section("表示") {
                Toggle("キャラクターアニメーション", isOn: $enableAnimations)
                    .onChange(of: enableAnimations) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "enableAnimations")
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 280)
        .padding()
    }
}
