import AppKit

@MainActor
final class WorkTimerOverlay {
    private let window: NSWindow
    private let backgroundView: NSView
    private let label: NSTextField
    private static let height: CGFloat = 20
    private var isActive = false

    init() {
        let frame = NSRect(x: 0, y: 0, width: 80, height: Self.height)

        window = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = true

        backgroundView = NSView(frame: NSRect(origin: .zero, size: frame.size))
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.55).cgColor
        backgroundView.layer?.cornerRadius = 6

        label = NSTextField(labelWithString: "")
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        label.textColor = .white
        label.backgroundColor = .clear
        label.alignment = .center
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false

        backgroundView.addSubview(label)
        window.contentView = backgroundView
    }

    func attach(to parentWindow: NSWindow) {
        parentWindow.addChildWindow(window, ordered: .below)
        window.orderOut(nil)
    }

    /// 親ウィンドウ表示時に呼び出し、idle なら非表示を維持する
    func syncVisibility() {
        if !isActive {
            window.orderOut(nil)
        }
    }

    func update(elapsed: TimeInterval, state: WorkTracker.State, preset: String? = nil) {
        switch state {
        case .tracking:
            isActive = true
            if let preset {
                label.stringValue = "\(preset) \(formatTime(elapsed))"
            } else {
                label.stringValue = formatTime(elapsed)
            }
        case .paused:
            isActive = true
            if let preset {
                label.stringValue = "\(preset) \(formatTime(elapsed)) ⏸"
            } else {
                label.stringValue = "\(formatTime(elapsed)) ⏸"
            }
        case .idle:
            isActive = false
            window.orderOut(nil)
            return
        }

        layoutAndPosition()

        if !window.isVisible {
            window.orderFront(nil)
        }
    }

    // MARK: - Private

    private func layoutAndPosition() {
        guard let parent = window.parent else { return }

        label.sizeToFit()
        let contentWidth = max(label.frame.width + 16, 70)
        let height = Self.height

        let parentFrame = parent.frame
        let x = parentFrame.midX - contentWidth / 2
        let y = parentFrame.minY - height - 2

        window.setFrame(NSRect(x: x, y: y, width: contentWidth, height: height), display: false)
        backgroundView.frame = NSRect(x: 0, y: 0, width: contentWidth, height: height)
        label.frame = NSRect(x: 4, y: 1, width: contentWidth - 8, height: height - 2)
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }
}
