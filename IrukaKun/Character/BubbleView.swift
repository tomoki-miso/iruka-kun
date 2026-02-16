import AppKit

@MainActor
final class BubbleView: NSView {
    private let label = NSTextField(labelWithString: "")
    private let padding: CGFloat = 10
    private let tailHeight: CGFloat = 8
    private var fadeTimer: Timer?
    private var originalWindowHeight: CGFloat?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        wantsLayer = true

        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .black
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        label.alignment = .center
        label.maximumNumberOfLines = 3
        label.preferredMaxLayoutWidth = 160
        addSubview(label)
    }

    func show(text: String, relativeTo characterFrame: NSRect, in parentWindow: NSWindow) {
        fadeTimer?.invalidate()
        label.stringValue = text
        label.sizeToFit()

        let bubbleWidth = label.frame.width + padding * 2
        let bubbleHeight = label.frame.height + padding * 2 + tailHeight
        let size = CGSize(width: max(bubbleWidth, 60), height: bubbleHeight)

        // Position above character
        let x = characterFrame.midX - size.width / 2
        let y = characterFrame.maxY + 4
        self.frame = NSRect(origin: CGPoint(x: x, y: y), size: size)

        label.frame = NSRect(
            x: padding,
            y: tailHeight + padding,
            width: size.width - padding * 2,
            height: label.frame.height
        )

        alphaValue = 1.0
        isHidden = false
        parentWindow.contentView?.addSubview(self)

        // Restore window to original size before re-expanding
        if let originalHeight = originalWindowHeight {
            var windowFrame = parentWindow.frame
            windowFrame.size.height = originalHeight
            parentWindow.setFrame(windowFrame, display: false)
            originalWindowHeight = nil
        }

        // Adjust window size to fit bubble
        var windowFrame = parentWindow.frame
        let requiredTop = y + size.height
        if requiredTop > windowFrame.size.height {
            originalWindowHeight = windowFrame.size.height
            let extraHeight = requiredTop - windowFrame.size.height
            windowFrame.size.height += extraHeight
            parentWindow.setFrame(windowFrame, display: true)
        }

        // Auto-fade after delay
        let displayDuration = max(3.0, Double(text.count) * 0.15)
        fadeTimer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.fadeOut()
            }
        }
    }

    private func fadeOut() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            self.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.isHidden = true
            if let originalHeight = self?.originalWindowHeight,
               let window = self?.window {
                var frame = window.frame
                frame.size.height = originalHeight
                window.setFrame(frame, display: true)
                self?.originalWindowHeight = nil
            }
            self?.removeFromSuperview()
        })
    }

    override func draw(_ dirtyRect: NSRect) {
        let bubbleRect = NSRect(
            x: 0,
            y: tailHeight,
            width: bounds.width,
            height: bounds.height - tailHeight
        )

        let path = NSBezierPath(roundedRect: bubbleRect, xRadius: 8, yRadius: 8)

        // Tail
        let tailPath = NSBezierPath()
        let tailCenterX = bounds.midX
        tailPath.move(to: NSPoint(x: tailCenterX - 6, y: tailHeight))
        tailPath.line(to: NSPoint(x: tailCenterX, y: 0))
        tailPath.line(to: NSPoint(x: tailCenterX + 6, y: tailHeight))
        tailPath.close()

        NSColor.white.withAlphaComponent(0.95).setFill()
        path.fill()
        tailPath.fill()

        NSColor.gray.withAlphaComponent(0.3).setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    // Make bubble clickable (for hit test pass-through)
    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        return bounds.contains(local) && !isHidden ? self : nil
    }
}
