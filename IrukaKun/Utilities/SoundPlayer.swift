import AppKit

@MainActor
final class SoundPlayer {
    private var clickSound: NSSound?

    init() {
        if let url = Bundle.main.url(forResource: "click", withExtension: "aiff") {
            clickSound = NSSound(contentsOf: url, byReference: true)
        } else {
            // Fallback: use system sound
            clickSound = NSSound(named: "Pop")
        }
    }

    func playClick() {
        clickSound?.stop()
        clickSound?.play()
    }
}
