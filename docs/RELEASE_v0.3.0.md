## v0.3.0 — Settings & Configuration

### Features
- **Customizable idle threshold** (1-30 minutes, default 5 minutes)
- **Character animation toggle** (enable/disable)
- **Settings UI** with grouped sections
- **UserDefaults persistence** for all settings
- **Backward compatible** defaults

### Technical Details
- UserDefaults keys: `idleThresholdSeconds`, `enableAnimations`
- Settings window with 3 sections: Application, Work Tracking, Display
- Dynamic animation control via SpriteAnimator
- Full Swift 6 strict concurrency compliance

### Test Coverage
- 58/58 tests passing (100%)
- All existing tests remain passing
- Backward compatibility verified

### Files Modified
- `IrukaKun/Settings/SettingsView.swift` (27 → 63 lines)
- `IrukaKun/WorkTracker/WorkTracker.swift` (init method)
- `IrukaKun/Character/SpriteAnimator.swift` (play method)

### Installation
Download `IrukaKun-0.3.0.dmg` and drag `iruka-kun.app` to Applications.
