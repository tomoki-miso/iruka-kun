import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
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
        .formStyle(.grouped)
        .frame(width: 300, height: 100)
        .padding()
    }
}
