import Foundation

final class CommandExplainWatcher: @unchecked Sendable {
    private let filePath = "/tmp/iruka-kun-command-explain.json"
    private let queue = DispatchQueue(label: "com.iruka-kun.command-explain-watcher")
    private var source: DispatchSourceFileSystemObject?
    private var pendingTimer: DispatchWorkItem?

    private let responsePath = "/tmp/iruka-kun-command-response.json"

    var onCommandExplain: ((String, String) -> Void)?
    var onCommandDismiss: (() -> Void)?

    func respond(decision: String) {
        let json: [String: String] = ["decision": decision]
        if let data = try? JSONSerialization.data(withJSONObject: json) {
            try? data.write(to: URL(fileURLWithPath: responsePath))
        }
    }

    func start() {
        createSource()
    }

    func stop() {
        source?.cancel()
        source = nil
        pendingTimer?.cancel()
    }

    private func createSource() {
        source?.cancel()
        source = nil

        let path = filePath
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil)
        }

        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename],
            queue: queue
        )

        src.setEventHandler { [weak self] in
            guard let self else { return }
            let flags = src.data
            if flags.contains(.delete) || flags.contains(.rename) {
                src.cancel()
                close(fd)
                Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .milliseconds(500))
                    self?.createSource()
                    self?.handleFileChange(path: path)
                }
                return
            }
            self.handleFileChange(path: path)
        }

        src.setCancelHandler {
            close(fd)
        }

        src.resume()
        self.source = src
    }

    private func handleFileChange(path: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              !data.isEmpty,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        let status = json["status"] as? String ?? ""

        switch status {
        case "pending":
            // 500ms 後もまだ pending なら許可要求中と判断して表示
            pendingTimer?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.checkAndShow(path: path)
            }
            pendingTimer = work
            queue.asyncAfter(deadline: .now() + 0.5, execute: work)
        case "show":
            pendingTimer?.cancel()
            showExplanation(from: json)
        case "dismiss":
            pendingTimer?.cancel()
            Task { @MainActor [weak self] in
                self?.onCommandDismiss?()
            }
        default:
            break
        }
    }

    private func checkAndShow(path: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              !data.isEmpty,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        let status = json["status"] as? String ?? ""
        if status == "pending" || status == "show" {
            showExplanation(from: json)
        }
    }

    private func showExplanation(from json: [String: Any]) {
        guard let command = json["command"] as? String,
              let explanation = json["explanation"] as? String else { return }
        let cmd = command
        let exp = explanation
        Task { @MainActor [weak self] in
            self?.onCommandExplain?(cmd, exp)
        }
    }
}
