import AppKit

@MainActor
final class BubbleView: NSView {
    private let label = NSTextField(labelWithString: "")
    private let padding: CGFloat = 10
    private let tailHeight: CGFloat = 8
    private let collapseThreshold = 20
    private let collapsedMaxWidth: CGFloat = 120

    private var hoverCheckTimer: Timer?
    private var bubbleWindow: NSWindow?
    private var fullText = ""
    private var lastCharacterFrame: NSRect = .zero
    private var isLongText = false
    private var isExpanded = false

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
        addSubview(label)
    }

    func show(text: String, relativeTo characterFrame: NSRect, in parentWindow: NSWindow) {
        hoverCheckTimer?.invalidate()

        fullText = text
        lastCharacterFrame = characterFrame
        isLongText = text.count > collapseThreshold
        isExpanded = false

        applyLabelStyle()

        if bubbleWindow == nil {
            let window = NSWindow(
                contentRect: .zero,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.level = .floating
            window.ignoresMouseEvents = true
            window.contentView = self
            bubbleWindow = window
        }

        guard let window = bubbleWindow else { return }

        layoutBubble(parentWindow: parentWindow)

        window.alphaValue = 1.0
        if window.parent !== parentWindow {
            window.parent?.removeChildWindow(window)
            parentWindow.addChildWindow(window, ordered: .above)
        }
        window.orderFront(nil)

        if isLongText {
            startHoverCheck()
        }

        // No auto-fade; CharacterController drives text rotation
    }

    // MARK: - Label & Layout

    private func applyLabelStyle() {
        let collapsed = isLongText && !isExpanded
        if collapsed {
            label.maximumNumberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            label.preferredMaxLayoutWidth = collapsedMaxWidth
            label.stringValue = fullText.replacingOccurrences(of: "\n", with: " ")
        } else {
            label.maximumNumberOfLines = 5
            label.lineBreakMode = .byWordWrapping
            label.preferredMaxLayoutWidth = 200
            label.stringValue = fullText
        }
        label.sizeToFit()
        if collapsed {
            label.frame.size.width = min(label.frame.size.width, collapsedMaxWidth)
        }
    }

    private func layoutBubble(parentWindow: NSWindow) {
        let bubbleWidth = label.frame.width + padding * 2
        let bubbleHeight = label.frame.height + padding * 2 + tailHeight
        let size = CGSize(width: max(bubbleWidth, 60), height: bubbleHeight)

        self.frame = NSRect(origin: .zero, size: size)
        label.frame = NSRect(
            x: padding,
            y: tailHeight + padding,
            width: size.width - padding * 2,
            height: label.frame.height
        )

        guard let window = bubbleWindow else { return }
        let parentFrame = parentWindow.frame
        let windowX = parentFrame.origin.x + lastCharacterFrame.midX - size.width / 2
        let windowY = parentFrame.origin.y + lastCharacterFrame.maxY + 4
        window.setFrame(
            NSRect(origin: CGPoint(x: windowX, y: windowY), size: size),
            display: true
        )
        needsDisplay = true
    }

    // MARK: - Hover Detection

    private func startHoverCheck() {
        hoverCheckTimer?.invalidate()
        hoverCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkHover()
            }
        }
    }

    private func checkHover() {
        guard isLongText, let window = bubbleWindow, window.alphaValue > 0 else {
            hoverCheckTimer?.invalidate()
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        let isInside = window.frame.contains(mouseLocation)

        if isInside && !isExpanded {
            isExpanded = true
            applyLabelStyle()
            guard let parentWindow = window.parent else { return }
            layoutBubble(parentWindow: parentWindow)
        } else if !isInside && isExpanded {
            isExpanded = false
            applyLabelStyle()
            guard let parentWindow = window.parent else { return }
            layoutBubble(parentWindow: parentWindow)
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        let bubbleRect = NSRect(
            x: 0,
            y: tailHeight,
            width: bounds.width,
            height: bounds.height - tailHeight
        )

        let path = NSBezierPath(roundedRect: bubbleRect, xRadius: 8, yRadius: 8)

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
}
