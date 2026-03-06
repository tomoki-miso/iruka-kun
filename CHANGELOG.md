# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.0] - 2026-03-06

### Added
- **Calendar Integration**
  - iCalendar (RFC 5545) format support
  - Calendar event generation from work history
  - UID generation with event metadata
  - Timestamp management (ISO 8601)
  - Text escaping for special characters

### Technical
- CalendarManager.swift: iCalendar formatter
- Support for external calendar applications
- Event categorization and description

### Test Coverage
- Added 4 new tests for calendar functionality
- Total: 78/78 tests (100% pass rate)

## [0.6.0] - 2026-03-06

### Added
- **Export Features**
  - CSV export of work history
  - JSON export with nested structure
  - Automatic file naming with ISO8601 timestamps
  - File saving to Documents folder

### Technical
- ExportManager.swift: CSV and JSON formatters
- FileManager integration for persistent file operations
- Support for work data serialization

### Test Coverage
- Added 4 new tests for export functionality
- Total: 74/74 tests (100% pass rate)

## [0.5.0] - 2026-03-06

### Added
- **Multi-Monitor Support**
  - Independent window position per display
  - Screen configuration change detection
  - Automatic position migration
  - Safe position restoration after screen removal

### Changed
- PositionStore now tracks screen-specific positions
- CharacterWindow position restoration improved for multi-display environments

### Technical
- ScreenUtility.generateScreenIdentifier() for unique screen identification
- UserDefaults schema: `iruka_screen_positions` (dict of screen IDs to positions)
- Backward compatible migration from legacy single-position format

### Test Coverage
- Added 4 new tests for screen-specific position storage
- Total: 70/70 tests (100% pass rate)

## [0.2.0] - 2026-03-02

### Added
- **Report Generation System**
  - Daily report generation (`generateDailyReport(for:)`)
  - Weekly report generation (`generateWeeklyReport(for:)`)
  - Monthly report generation (`generateMonthlyReport(for:)`)
  - Range-based report generation (`generateRangeReport(from:to:)`)
  - SwiftUI-based report view with tab navigation
  - Date picker for custom date range selection
  - Statistics display with total time and category breakdown
  - Report window controller for window management

- **Enhanced Testing**
  - ReportGeneratorTests: 12 comprehensive test cases
  - Updated test suites to support new reporting functionality
  - Test coverage expanded from 46 to 58 tests (100% pass rate)

- **Release Build Improvements**
  - Added `-enable-testing` flag to project.yml for Release configuration
  - Release build now fully supports test execution
  - Verified 58/58 tests pass in Release configuration

### Changed
- Updated test coverage from 46 to 58 tests
- Enhanced WorkHistoryStore integration with report generation
- Refactored project.yml for better build configuration management

### Fixed
- Release build test execution (added missing `-enable-testing` flag)
- Improved handling of work history data in report generation

### Technical Details
- **ReportGenerator.swift**: 153 lines - Core report generation logic
- **ReportView.swift**: 251 lines - SwiftUI report interface
- **ReportWindowController.swift**: 29 lines - Window management
- **ReportGeneratorTests.swift**: 156 lines - Comprehensive test coverage

## [0.1.0] - 2026-02-28

### Initial Release
- **Core Features**
  - Menu bar application with animated character companion
  - 5-state character state machine (Idle, Happy, Sleeping, Surprised, Bored)
  - 4 built-in characters with sprite animation
  - Work session tracking with 300-second idle detection
  - Persistent work history with per-session categorization
  - Context-aware dialogue system (time-of-day aware)
  - Custom character support

- **Work Tracking**
  - Automatic idle detection and pause
  - Work preset management (categorized time tracking)
  - Daily work breakdown analytics
  - Position persistence for floating window

- **User Interface**
  - Floating transparent window with drag-and-drop repositioning
  - Menu bar status display with work controls
  - Character animation (10 FPS frame-based)
  - SwiftUI integration for modern UI components

- **Integration & Tools**
  - Meigen (motivational quotes) integration
  - Permission-based bash command execution
  - DMG packaging for distribution

- **Testing & Quality**
  - 46 comprehensive test cases (100% pass rate)
  - State Machine tests: 11
  - Dialogue System tests: 7
  - Sprite Animation tests: 8
  - Work Tracking tests: 12
  - Character Management tests: 5
  - Utility tests: 3

- **Build & Deployment**
  - XcodeGen project generation
  - Swift 6 with strict concurrency
  - DMG build automation script
  - Release build configuration

### Technical Stack
- Language: Swift 6
- Frameworks: AppKit, SwiftUI
- Storage: UserDefaults (local persistence)
- Build System: XcodeGen 2.38+
- Xcode: 26.1 (Build 17B55)
- Test Framework: XCTest

### Known Limitations
- Sprite animation: 1×N or N×1 grids only
- Dialogue: Random selection (not AI-powered)
- Work history: Local storage only
- No settings UI yet
- Menu icon size fixed by OS

### Future Roadmap
- **v0.3.0**: Settings UI
- **v0.4.0**: Export & calendar integration
- **v0.5.0**: Audio & music
- **v1.0.0**: Multi-monitor support & cloud sync

---

## Release Notes

### How to Install
1. Download the DMG from the releases page
2. Drag `iruka-kun.app` to Applications folder
3. Launch from Applications

### How to Build from Source
```bash
git clone <repository-url>
cd iruka-kun
brew install xcodegen
xcodegen generate
./scripts/build-dmg.sh
```

### Testing
```bash
# Debug configuration
xcodebuild test -scheme IrukaKun

# Release configuration
xcodebuild test -scheme IrukaKun -configuration Release
```

---

Made with ❤️ by misoshiru
