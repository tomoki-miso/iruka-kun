## v0.4.0 — Audio & Music

### Features
- **Background Music**: Automatic background music playback on app launch
- **Sound Effects**: Click sound when interacting with character
- **Audio Control**: Toggle audio enable/disable in Settings
- **Persistent Settings**: Audio preference saved via UserDefaults
- **Graceful Degradation**: Missing audio files don't crash the app

### Technical Details
- **AudioManager Singleton**: Centralized audio playback control
- **AVFoundation Integration**: Uses system audio framework
- **Multiple Sound Players**: Support for simultaneous sound effects
- **User Preference**: UserDefaults key "audioEnabled"
- **Full Concurrency**: Swift 6 strict concurrency (@MainActor)

### Architecture
- AudioManager: Singleton pattern for global access
- Background music: Infinite loop while enabled
- Sound effects: Fire-and-forget with automatic cleanup
- SettingsView: New audio toggle in "表示" section
- AppDelegate: Auto-starts audio on app launch
- SoundPlayer: Integrated with AudioManager

### Files Modified
- `IrukaKun/Utilities/AudioManager.swift` - NEW
- `IrukaKun/Utilities/SoundPlayer.swift` - Updated
- `IrukaKun/Settings/SettingsView.swift` - Enhanced
- `IrukaKun/App/AppDelegate.swift` - Integrated
- `Resources/Sounds/` - NEW (6 audio placeholders)

### Test Coverage
- **66/66 tests passing** (100%)
- AudioManagerTests: 8 new tests
- All existing tests maintained
- Coverage includes:
  - Audio enable/disable
  - Background music control
  - Sound effect playback
  - UserDefaults persistence

### Assets
- Resources/Sounds/background_music.mp3
- Resources/Sounds/click.mp3
- Resources/Sounds/happy.mp3
- Resources/Sounds/sleep.mp3
- Resources/Sounds/surprised.mp3
- Resources/Sounds/bored.mp3

*Note: Audio files are currently placeholders. Replace with actual audio files for production.*

### Installation
No installation changes from v0.3.0. Audio is enabled by default.

**Settings → 表示 → 効果音と背景音楽** to toggle.

### Known Limitations
- Audio files are placeholders (development versions)
- No volume control (can add in v0.5.0)
- Single background music track (playlist support in v0.5.0)
- No audio ducking for system notifications

### Future Enhancements (v0.5.0+)
- Volume control slider in Settings
- Multiple background music tracks with rotation
- Audio ducking for system events
- More sound effect types (state transitions, work timer)

### Build Information
- Swift 6 strict concurrency
- macOS 15.0+ deployment target
- No external audio dependencies
- Self-contained audio system

### Contributors
- Audio system design and implementation

### Commits
- 79faf96: AudioManager singleton and asset structure
- ff8d937: SettingsView toggle and AppDelegate initialization
- 0255b5e: SoundPlayer integration with AudioManager

---

**Released:** 2026-03-03
**Version:** 0.4.0
**Status:** Stable
