import AppKit

@MainActor
final class SoundPlayer {
    init() {
        // SoundPlayer now delegates to AudioManager
    }

    func playClick() {
        AudioManager.shared.playSoundEffect(named: "click")
    }
}
