# iruka-kun

A charming macOS menu bar application featuring an animated character companion that tracks your work sessions and provides motivational dialogue.

## Features

### Core Features
- **Customizable Character Companion**: Switch between built-in characters (iruka/dolphin, rakko/sea otter, ono, syacho) or add your own custom characters
- **Smart Work Tracking**: Monitor work sessions with automatic idle detection (300-second threshold)
- **Dialogue System**: Context-aware character responses based on time of day
- **Sprite Animation**: Frame-based character animation (10 FPS) with pixel-art quality
- **Interactive Floating Window**: Drag-and-drop repositioning with automatic position saving

### Advanced Features
- **Work Breakdown Analytics**: Daily breakdown of work time by category
- **Work History**: Persistent storage with per-session categorization
- **Meigen Integration**: Displays motivational quotes
- **Permission-based Command Execution**: Secure bash command integration

## Installation

### From DMG
1. Download DMG from releases page
2. Drag `iruka-kun.app` to Applications
3. Launch from Applications

### Build from Source
```bash
git clone <repository-url>
cd iruka-kun
brew install xcodegen
xcodegen generate
./scripts/build-dmg.sh
```

## Usage

### Menu Bar Control
- **Work Toggle**: Click "▶ 作業を開始" to start, "⏹ 作業を中止" to stop
- **Category Selection**: Choose category to tag sessions
- **Status Display**: View character state and work time
- **History**: Access past sessions and reports

### Character Interaction
- **Click**: Triggers animations and dialogue
- **Drag**: Move window (position saved automatically)
- **Menu**: Switch characters or customize

### Work Tracking
1. Select category (optional)
2. Click "▶ 作業を開始" to start
3. Auto-pauses after 5 minutes inactivity
4. Resume with interaction or manual click
5. Click "⏹ 作業を中止" to end (time recorded)

## Project Structure

```
iruka-kun/
├── IrukaKun/               # Main application source
│   ├── Character/          # Character display & animation
│   ├── Dialog/             # Dialogue system
│   ├── Meigen/             # Wise saying integration
│   ├── MenuBar/            # Status bar & menu UI
│   ├── State/              # Character state management
│   ├── WorkTracker/        # Work session tracking
│   └── Utilities/          # Helper modules
├── IrukaKunTests/          # Test suite (46/46 passing)
├── Resources/              # Application assets
├── docs/                   # Documentation
├── scripts/                # Build automation
└── project.yml             # XcodeGen configuration
```

## Architecture

### State Machine (5 States)
- **Idle**: Default state
- **Happy**: Positive events
- **Sleeping**: Sticky state (requires wake-up)
- **Surprised**: Sudden interactions
- **Bored**: Extended inactivity

### Dialogue System
- **TimeOfDay**: Morning/Afternoon/Evening/Night
- **7 Categories**: Greeting, encouragement, reaction, state-specific, work-related, character-specific, meigen
- **Context-Aware**: Responds based on time, state, and events

### Sprite Animation
- **10 FPS** frame-based animation
- **CALayer rendering** with nearest-neighbor filtering
- **Per-state sequences** for smooth transitions

### Work Tracking
- **Global event monitoring** for activity detection
- **300-second idle timeout** before auto-pause
- **Day boundary handling** across midnight
- **Category tracking** for time organization

## Development

### Building
```bash
xcodegen generate
xcodebuild -scheme IrukaKun -configuration Debug build
./scripts/build-dmg.sh  # Release build
```

### Testing
```bash
xcodebuild test -scheme IrukaKun
```

### Test Coverage (v0.3.0)
- Total: 58/58 tests passing
- State Machine: 11 tests
- Dialogue System: 7 tests
- Sprite Animation: 8 tests
- Work Tracking: 12 tests
- Work History: 11 tests
- Report Generator: 12 tests
- Character Management: 5 tests
- Position Store: 2 tests

### Code Guidelines
- **Naming**: PascalCase (classes), camelCase (functions)
- **Concurrency**: `@MainActor` for UI, `Sendable` for APIs
- **Error Handling**: Guard early, log with context
- **Testing**: TDD for core logic
- **Style**: 4-space indentation, Swift 6 strict concurrency

## Troubleshooting

### Character Not Animating
```bash
# Verify sprite files
ls -la Resources/Sprites/
```

### Work Tracking Not Starting
- Grant event monitoring: System Settings → Privacy & Security → Input Monitoring
- Restart application

### DMG Build Fails
```bash
xcodegen --version
xcodebuild --version
rm -rf build/ && ./scripts/build-dmg.sh
```

### Window Disappears on Launch
```bash
defaults delete com.misoshiru.iruka-kun window_position_x
defaults delete com.misoshiru.iruka-kun window_position_y
```

### High CPU Usage
- Verify animation FPS: `SpriteAnimator.swift` should use 0.1 (10 FPS)
- Restart: `pkill iruka-kun`

## Version History

### v0.1.0 (2026-03-02) — Initial Release
**Features:**
- Menu bar application
- 5-state character state machine
- 4 built-in characters with animation
- Work session tracking with idle detection
- Work history and breakdown analytics
- Dialogue system with time awareness
- Custom character support
- Work preset management
- Position persistence
- Floating transparent window
- Meigen integration
- DMG packaging

**Test Coverage:** 46/46 tests (100%)

**Build:** XcodeGen + Swift 6 + AppKit + SwiftUI

**Known Limitations:**
- Sprite animation: 1×N or N×1 grids only
- Dialogue: Random selection (not AI)
- Work history: Local storage only
- Menu icon: OS-fixed size

### v0.2.0 (2026-03-02) — Reports & Analytics
**Features:**
- Daily work breakdown by category
- Weekly, monthly, and date-range reports
- Category-wise time analytics
- Report window with tab-based navigation
- Statistics and summaries

**Test Coverage:** 58/58 tests (100%)

**Improvements:**
- ReportGenerator: Daily/Weekly/Monthly/Range report generation
- ReportView: SwiftUI-based report UI with date picker
- Enhanced work history analytics


### v0.4.0 (2026-03-06) — Audio & Music
**Features:**
- Background music playback with looping
- Sound effects system with automatic cleanup
- Audio enable/disable toggle in Settings
- UserDefaults persistence
- Graceful handling of missing audio files

**Test Coverage:** 58/58 tests (100%)

**Technical Details:**
- AudioManager singleton for centralized audio management
- AVFoundation integration with @MainActor concurrency
- SoundPlayer delegation wrapper
- Persistent audio preferences via UserDefaults


**Features:**
- Customizable idle threshold (1-30 minutes, default 5 minutes)
- Character animation toggle (enable/disable)
- Settings UI with grouped sections
- UserDefaults persistence
- Backward compatible defaults

**Test Coverage:** 58/58 tests (100%)

**Technical Details:**
- UserDefaults keys: `idleThresholdSeconds`, `enableAnimations`
- Settings window with 3 sections: Application, Work Tracking, Display
- Dynamic animation control via SpriteAnimator

**Future Roadmap:**
- v0.5.0: Multi-monitor
- v1.0.0: Cloud sync


### v0.5.0 (2026-03-06) — Multi-Monitor Support

**Features:**
- Independent window position per display
- Automatic screen-safe position restoration
- Legacy position format migration
- Screen configuration change handling

**Test Coverage:** 70/70 tests (100%)

**Technical Details:**
- Screen identification via frame geometry (format: "screen_<width>x<height>_<x>_<y>")
- Per-screen UserDefaults storage (`iruka_screen_positions`)
- Backward compatible with v0.4.0 legacy position format
- Auto-migration on first launch in multi-monitor environment


### v0.6.0 (2026-03-06) — Export Features

**Features:**
- CSV export of work history
- JSON export for data analysis
- Automatic file naming with timestamps
- Documents folder integration

**Test Coverage:** 74/74 tests (100%)

**Technical Details:**
- ExportManager with JSON/CSV converters
- FileManager integration for file operations
- Format: Documents/iruka-work-{type}-{timestamp}.{format}


### v0.7.0 (2026-03-06) — Calendar Integration

**Features:**
- iCalendar format export of work history
- Calendar event generation with metadata
- Support for external calendar applications
- Automatic event naming and timestamping

**Test Coverage:** 78/78 tests (100%)

**Technical Details:**
- CalendarManager with iCalendar (RFC 5545) compliance
- UID generation and timestamp management
- Text escaping for special characters

## Contributing

1. Fork repository
2. Feature branch: `git checkout -b feature/your-feature`
3. Add tests and changes
4. Test: `xcodebuild test -scheme IrukaKun`
5. Commit with description
6. Push and create PR

### Code Review Requirements
- ✅ All tests passing
- ✅ No warnings
- ✅ Style guidelines followed
- ✅ Documentation updated

## License

MIT License — See LICENSE file

## Support

- 🐛 Found a bug? Open an issue
- 💡 Feature idea? Start discussion
- 📚 Need help? Check troubleshooting

## Acknowledgments

- Character concept from Japanese mascot culture
- Sprite animation from pixel-art techniques
- Work tracking from Pomodoro Technique
- Dialogue from virtual pet interactions

---

**Made with ❤️ by misoshiru**

Current Version: 0.7.0
