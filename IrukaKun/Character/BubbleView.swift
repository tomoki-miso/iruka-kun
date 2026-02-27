import AppKit

@MainActor
final class BubbleView: NSView {
    private let label = NSTextField(labelWithString: "")
    private let copyButton = NSButton()
    private let closeButton = NSButton()
    private let padding: CGFloat = 10
    private let tailHeight: CGFloat = 8
    private let collapseThreshold = 20
    private let collapsedMaxWidth: CGFloat = 120
    private let expandedMaxWidth: CGFloat = 280

    private let allowButton = NSButton()
    private let allowAlwaysButton = NSButton()
    private let denyButton = NSButton()

    private var hoverCheckTimer: Timer?
    private var bubbleWindow: NSWindow?
    private var fullText = ""
    private var lastCharacterFrame: NSRect = .zero
    private var isLongText = false
    private var isExpanded = false
    private var isCopyable = false

    var onDismissCopyMode: (() -> Void)?
    var onAllowCommand: (() -> Void)?
    var onAllowAlwaysCommand: (() -> Void)?
    var onDenyCommand: (() -> Void)?

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

        copyButton.bezelStyle = .inline
        copyButton.title = "📋 コピー"
        copyButton.font = NSFont.systemFont(ofSize: 11)
        copyButton.target = self
        copyButton.action = #selector(copyText)
        copyButton.isHidden = true
        addSubview(copyButton)

        closeButton.bezelStyle = .inline
        closeButton.title = "✕"
        closeButton.font = NSFont.systemFont(ofSize: 11)
        closeButton.target = self
        closeButton.action = #selector(dismissCopyMode)
        closeButton.isHidden = true
        addSubview(closeButton)

        allowButton.bezelStyle = .inline
        allowButton.title = "✅ 許可"
        allowButton.font = NSFont.systemFont(ofSize: 11)
        allowButton.target = self
        allowButton.action = #selector(allowCommand)
        allowButton.isHidden = true
        addSubview(allowButton)

        allowAlwaysButton.bezelStyle = .inline
        allowAlwaysButton.title = "✅ ずっと許可"
        allowAlwaysButton.font = NSFont.systemFont(ofSize: 11)
        allowAlwaysButton.target = self
        allowAlwaysButton.action = #selector(allowAlwaysCommand)
        allowAlwaysButton.isHidden = true
        addSubview(allowAlwaysButton)

        denyButton.bezelStyle = .inline
        denyButton.title = "❌ 拒否"
        denyButton.font = NSFont.systemFont(ofSize: 11)
        denyButton.target = self
        denyButton.action = #selector(denyCommand)
        denyButton.isHidden = true
        addSubview(denyButton)
    }

    func show(text: String, copyable: Bool = false, relativeTo characterFrame: NSRect, in parentWindow: NSWindow) {
        hoverCheckTimer?.invalidate()

        fullText = text
        lastCharacterFrame = characterFrame
        isCopyable = copyable
        isLongText = !copyable && text.count > collapseThreshold
        isExpanded = copyable
        copyButton.isHidden = !copyable
        closeButton.isHidden = !copyable

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

        window.ignoresMouseEvents = !isCopyable
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
    }

    func dismissToNormal() {
        guard isCopyable else { return }
        onDismissCopyMode?()
    }

    // MARK: - Actions

    @objc private func copyText() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(fullText, forType: .string)

        let original = copyButton.title
        copyButton.title = "✅ コピー済み"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.copyButton.title = original
        }
    }

    @objc private func dismissCopyMode() {
        onDismissCopyMode?()
    }

    @objc private func allowCommand() {
        onAllowCommand?()
    }

    @objc private func allowAlwaysCommand() {
        onAllowAlwaysCommand?()
    }

    @objc private func denyCommand() {
        onDenyCommand?()
    }

    // MARK: - Label & Layout

    private func applyLabelStyle() {
        label.alignment = isCopyable ? .left : .center
        let collapsed = isLongText && !isExpanded
        if collapsed {
            label.maximumNumberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            label.preferredMaxLayoutWidth = collapsedMaxWidth
            label.stringValue = fullText.replacingOccurrences(of: "\n", with: " ")
        } else {
            label.maximumNumberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.preferredMaxLayoutWidth = expandedMaxWidth
            let alignment: NSTextAlignment = isCopyable ? .left : .center
            label.attributedStringValue = Self.renderMarkdown(fullText, alignment: alignment)
        }
        label.sizeToFit()
        if collapsed {
            label.frame.size.width = min(label.frame.size.width, collapsedMaxWidth)
        }
    }

    // MARK: - Markdown Rendering

    private static func renderMarkdown(_ text: String, alignment: NSTextAlignment) -> NSAttributedString {
        let baseFont = NSFont.systemFont(ofSize: 13, weight: .medium)
        let boldFont = NSFont.systemFont(ofSize: 13, weight: .bold)
        let headerFont = NSFont.systemFont(ofSize: 14, weight: .bold)
        let monoFont = NSFont.monospacedSystemFont(ofSize: 11.5, weight: .regular)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineSpacing = 2

        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle
        ]

        let result = NSMutableAttributedString()
        let lines = text.components(separatedBy: .newlines)

        for (i, rawLine) in lines.enumerated() {
            if i > 0 { result.append(NSAttributedString(string: "\n")) }
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("# ") {
                let content = String(trimmed.dropFirst(2))
                result.append(NSAttributedString(string: content, attributes: [
                    .font: headerFont,
                    .foregroundColor: NSColor.black,
                    .paragraphStyle: paragraphStyle
                ]))
            } else if trimmed.hasPrefix("> ") {
                let content = String(trimmed.dropFirst(2))
                result.append(NSAttributedString(string: content, attributes: [
                    .font: baseFont,
                    .foregroundColor: NSColor.darkGray,
                    .paragraphStyle: paragraphStyle
                ]))
            } else if trimmed.hasPrefix("- ") {
                let content = "• " + String(trimmed.dropFirst(2))
                result.append(applyInlineStyles(content, baseAttrs: baseAttrs, boldFont: boldFont, monoFont: monoFont))
            } else if trimmed.hasPrefix("`") && trimmed.hasSuffix("`") && trimmed.count > 2 {
                var code = String(trimmed.dropFirst().dropLast())
                code = code.replacingOccurrences(of: "{{", with: "").replacingOccurrences(of: "}}", with: "")
                result.append(NSAttributedString(string: "  \(code)", attributes: [
                    .font: monoFont,
                    .foregroundColor: NSColor.systemIndigo,
                    .paragraphStyle: paragraphStyle
                ]))
            } else {
                result.append(applyInlineStyles(trimmed, baseAttrs: baseAttrs, boldFont: boldFont, monoFont: monoFont))
            }
        }

        return result
    }

    private static func applyInlineStyles(
        _ text: String,
        baseAttrs: [NSAttributedString.Key: Any],
        boldFont: NSFont,
        monoFont: NSFont
    ) -> NSAttributedString {
        let cleaned = text
            .replacingOccurrences(of: "{{", with: "")
            .replacingOccurrences(of: "}}", with: "")

        let result = NSMutableAttributedString(string: cleaned, attributes: baseAttrs)

        // Inline code: `text`
        applyPattern(to: result, pattern: "`([^`]+)`", attributes: [
            .font: monoFont,
            .foregroundColor: NSColor.systemIndigo
        ])

        // Bold: **text**
        applyPattern(to: result, pattern: "\\*\\*([^*]+)\\*\\*", attributes: [
            .font: boldFont,
            .foregroundColor: NSColor.black
        ])

        return result
    }

    private static func applyPattern(
        to attrStr: NSMutableAttributedString,
        pattern: String,
        attributes: [NSAttributedString.Key: Any]
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let nsString = attrStr.string as NSString
        let matches = regex.matches(in: attrStr.string, range: NSRange(location: 0, length: nsString.length))

        for match in matches.reversed() {
            let capturedText = nsString.substring(with: match.range(at: 1))
            var merged = attributes
            // Preserve existing paragraph style
            if let existing = attrStr.attributes(at: match.range.location, effectiveRange: nil)[.paragraphStyle] {
                merged[.paragraphStyle] = existing
            }
            attrStr.replaceCharacters(in: match.range, with: NSAttributedString(string: capturedText, attributes: merged))
        }
    }

    private func layoutBubble(parentWindow: NSWindow) {
        let showActions = isCopyable
        let actionsHeight: CGFloat = showActions ? 52 : 0

        let bubbleWidth = label.frame.width + padding * 2
        let bubbleHeight = label.frame.height + padding * 2 + tailHeight + actionsHeight
        let size = CGSize(width: max(bubbleWidth, 160), height: bubbleHeight)

        self.frame = NSRect(origin: .zero, size: size)

        let labelY = tailHeight + padding + actionsHeight
        label.frame = NSRect(
            x: padding,
            y: labelY,
            width: size.width - padding * 2,
            height: label.frame.height
        )

        if showActions {
            // Close button (top-right)
            closeButton.isHidden = false
            closeButton.sizeToFit()
            closeButton.frame = NSRect(
                x: size.width - padding - closeButton.frame.width - 4,
                y: size.height - 22,
                width: closeButton.frame.width + 8,
                height: 18
            )

            // Action buttons: 2 rows
            // Row 1 (upper): [✅ 許可] [✅ ずっと許可] [❌ 拒否]
            // Row 2 (lower): [📋 コピー]
            copyButton.isHidden = false
            allowButton.isHidden = false
            allowAlwaysButton.isHidden = false
            denyButton.isHidden = false
            copyButton.sizeToFit()
            allowButton.sizeToFit()
            allowAlwaysButton.sizeToFit()
            denyButton.sizeToFit()

            let row1Y = tailHeight + 26
            let row2Y = tailHeight + 4

            // Row 1: Allow / AlwaysAllow / Deny
            let allowWidth = allowButton.frame.width + 12
            let alwaysWidth = allowAlwaysButton.frame.width + 12
            let denyWidth = denyButton.frame.width + 12
            let spacing: CGFloat = 4
            let row1Width = allowWidth + spacing + alwaysWidth + spacing + denyWidth
            let row1X = (size.width - row1Width) / 2

            allowButton.frame = NSRect(
                x: row1X,
                y: row1Y,
                width: allowWidth,
                height: 22
            )
            allowAlwaysButton.frame = NSRect(
                x: row1X + allowWidth + spacing,
                y: row1Y,
                width: alwaysWidth,
                height: 22
            )
            denyButton.frame = NSRect(
                x: row1X + allowWidth + spacing + alwaysWidth + spacing,
                y: row1Y,
                width: denyWidth,
                height: 22
            )

            // Row 2: Copy
            let copyWidth = copyButton.frame.width + 8
            copyButton.frame = NSRect(
                x: (size.width - copyWidth) / 2,
                y: row2Y,
                width: copyWidth,
                height: 22
            )
        } else {
            copyButton.isHidden = true
            closeButton.isHidden = true
            allowButton.isHidden = true
            allowAlwaysButton.isHidden = true
            denyButton.isHidden = true
        }

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
            window.ignoresMouseEvents = !isCopyable
            applyLabelStyle()
            guard let parentWindow = window.parent else { return }
            layoutBubble(parentWindow: parentWindow)
        } else if !isInside && isExpanded {
            isExpanded = false
            window.ignoresMouseEvents = true
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
