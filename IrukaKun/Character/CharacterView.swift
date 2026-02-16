import AppKit

@MainActor
final class CharacterView: NSView {
    private let imageLayer = CALayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
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

    override func layout() {
        super.layout()
        imageLayer.frame = bounds
    }

    func setSprite(_ image: NSImage) {
        imageLayer.contents = image
    }
}
