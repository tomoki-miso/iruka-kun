import AppKit

@MainActor
final class CharacterView: NSView {
    private let imageLayer = CALayer()
    let animator = SpriteAnimator()

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

        if let image = NSImage(named: "iruka_idle_0") {
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
}
