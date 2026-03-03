import XCTest
@testable import IrukaKun

@MainActor
final class AudioManagerTests: XCTestCase {
    var audioManager: AudioManager!
    
    override func setUp() async throws {
        audioManager = AudioManager.shared
    }
    
    func testSharedInstanceExists() {
        XCTAssertNotNil(AudioManager.shared)
    }
    
    func testInitialStateNotPlaying() {
        XCTAssertFalse(audioManager.isPlaying)
    }
    
    func testPlayBackgroundMusicAttempt() {
        audioManager.setAudioEnabled(true)
        // Note: actual playback requires valid audio files
        // This test just verifies the method doesn't crash
        audioManager.playBackgroundMusic()
        // isPlaying will be false if file doesn't load, but that's ok
    }
    
    func testStopBackgroundMusic() {
        audioManager.playBackgroundMusic()
        audioManager.stopBackgroundMusic()
        XCTAssertFalse(audioManager.isPlaying)
    }
    
    func testPlaySoundEffectDoesNotCrash() {
        audioManager.setAudioEnabled(true)
        audioManager.playSoundEffect(named: "test")
        // Should not crash even if sound doesn't exist
    }
    
    func testAudioDisabledPreventsPlayback() {
        audioManager.setAudioEnabled(false)
        audioManager.playBackgroundMusic()
        XCTAssertFalse(audioManager.isPlaying)
    }
    
    func testSetAudioEnabled() {
        audioManager.setAudioEnabled(true)
        XCTAssertTrue(UserDefaults.standard.object(forKey: "audioEnabled") as? Bool ?? false)
        
        audioManager.setAudioEnabled(false)
        XCTAssertFalse(UserDefaults.standard.object(forKey: "audioEnabled") as? Bool ?? true)
    }
    
    func testAudioEnabledStopsPlayback() {
        audioManager.playBackgroundMusic()
        audioManager.setAudioEnabled(false)
        XCTAssertFalse(audioManager.isPlaying)
    }
}
