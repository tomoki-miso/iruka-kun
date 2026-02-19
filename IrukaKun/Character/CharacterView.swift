import AppKit

@MainActor
final class CharacterView: NSView {
    private let imageLayer = CALayer()
    let animator = SpriteAnimator()
    private var isDragging = false
    private var dragOffset = CGPoint.zero

    var onClicked: (() -> Void)?
    var onDragStarted: (() -> Void)?
    var onDragEnded: ((CGPoint) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
        setupAnimator()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayer() {
        wantsLayer = true
        guard let layer else { return }
        layer.backgroundColor = NSColor.clear.cgColor

        imageLayer.contentsGravity = .resizeAspect
        imageLayer.magnificationFilter = .nearest
        layer.addSublayer(imageLayer)

        if let image = animator.currentFallbackImage() {
            imageLayer.contents = image
        }
    }

    private func setupAnimator() {
        animator.onFrameChanged = { [weak self] image in
            self?.imageLayer.contents = image
        }
        animator.play(state: .idle)
    }

    override func layout() {
        super.layout()
        imageLayer.frame = bounds
    }

    func setSprite(_ image: NSImage) {
        imageLayer.contents = image
    }

    func switchCharacter(_ type: CharacterType) {
        animator.switchCharacter(type)
        if let image = animator.currentFallbackImage() {
            imageLayer.contents = image
        }
        animator.play(state: .idle)
    }

    // MARK: - Hit Testing

    override func hitTest(_ point: NSPoint) -> NSView? {
        let localPoint = convert(point, from: superview)
        guard bounds.contains(localPoint) else { return nil }

        // Check alpha at the point
        guard let image = imageLayer.contents as? NSImage else { return nil }
        if isOpaquePixel(at: localPoint, in: image) {
            return self
        }
        return nil
    }

    private func isOpaquePixel(at point: NSPoint, in image: NSImage) -> Bool {
        let imageSize = image.size
        let scaleX = imageSize.width / bounds.width
        let scaleY = imageSize.height / bounds.height
        let imagePoint = NSPoint(x: point.x * scaleX, y: point.y * scaleY)

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let ptr = CFDataGetBytePtr(data)
        else { return false }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let ix = Int(imagePoint.x)
        // Flip Y (NSImage is bottom-up, CGImage is top-down)
        let iy = cgImage.height - 1 - Int(imagePoint.y)

        guard ix >= 0, ix < cgImage.width, iy >= 0, iy < cgImage.height else { return false }

        let offset = iy * bytesPerRow + ix * bytesPerPixel
        let alphaIndex = bytesPerPixel - 1 // RGBA: alpha is last
        let alpha = ptr[offset + alphaIndex]
        return alpha > 30 // threshold
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        isDragging = false
        guard let window else { return }
        let windowOrigin = window.frame.origin
        dragOffset = CGPoint(
            x: windowOrigin.x - NSEvent.mouseLocation.x,
            y: windowOrigin.y - NSEvent.mouseLocation.y
        )
    }

    override func mouseDragged(with event: NSEvent) {
        if !isDragging {
            isDragging = true
            onDragStarted?()
        }
        guard let window else { return }
        let mouseLocation = NSEvent.mouseLocation
        let newOrigin = CGPoint(
            x: mouseLocation.x + dragOffset.x,
            y: mouseLocation.y + dragOffset.y
        )
        window.setFrameOrigin(newOrigin)
    }

    override func mouseUp(with event: NSEvent) {
        if isDragging {
            guard let window else { return }
            onDragEnded?(window.frame.origin)
            isDragging = false
        } else {
            onClicked?()
        }
    }
}
