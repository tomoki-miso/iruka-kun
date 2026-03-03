import AppKit
import AVFoundation

@MainActor
final class AudioManager {
    static let shared = AudioManager()
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var soundEffectPlayers: [AVAudioPlayer] = []
    
    private(set) var isPlaying: Bool = false
    private var isAudioEnabled: Bool = true
    
    private init() {
        let defaults = UserDefaults.standard
        isAudioEnabled = defaults.object(forKey: "audioEnabled") as? Bool ?? true
    }
    
    func playBackgroundMusic() {
        guard isAudioEnabled else { return }
        guard backgroundMusicPlayer == nil else { return }
        
        // Try to load background_music.mp3 from bundle
        guard let soundURL = Bundle.main.url(forResource: "background_music", withExtension: "mp3") else {
            NSLog("Warning: background_music.mp3 not found in bundle")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: soundURL)
            backgroundMusicPlayer?.numberOfLoops = -1
            backgroundMusicPlayer?.play()
            isPlaying = true
        } catch {
            NSLog("Failed to play background music: \(error)")
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
        isPlaying = false
    }
    
    func playSoundEffect(named: String) {
        guard isAudioEnabled else { return }
        
        guard let soundURL = Bundle.main.url(forResource: named, withExtension: "mp3") else {
            // Silently fail if sound file not found (for testing)
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            soundEffectPlayers.append(player)
            player.play()
            
            // Remove completed players after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + (player.duration + 0.1)) { [weak self] in
                self?.soundEffectPlayers.removeAll { $0 === player }
            }
        } catch {
            NSLog("Failed to play sound effect \(named): \(error)")
        }
    }
    
    func setAudioEnabled(_ enabled: Bool) {
        isAudioEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "audioEnabled")
        
        if !enabled {
            stopBackgroundMusic()
        }
    }
}
