# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.6] - 2026-02-21

### Added

- Login detection with "Not logged in" screen and reload button
- Loading timeout — shows error with retry after 60 seconds of no data
- Persistent window position saved across launches
- Demo gif in project assets

### Changed

- Updated README to document all features, custom format variables, and build commands
- CI runner upgraded to macOS 15

## [1.0.5] - 2026-02-21

### Added

- Zoom controls for scaling the usage display
- Collapsible options panel with grouped settings (Zoom, Other, Menu bar)
- Auto-resize window when toggling the options panel
- Resizable window with manual drag support
- Chevron indicator on the options toggle button
- Retry button on error state
- Format reference popover for custom menu bar formats
- Global keyboard shortcut (Cmd+Shift+U) to toggle widget

### Changed

- Improved README with emoji styling and tmux installation guide

## [1.0.4] - 2026-02-21

### Added

- README, LICENSE (MIT), CONTRIBUTING guide, and CHANGELOG
- GitHub Actions CI workflow for build and test
- Extended `.gitignore` with macOS and Xcode entries

## [1.0.3] - 2026-02-21

### Added

- Quit menu in the status bar
- Custom status bar format configuration
- Reset date display in the widget
- Unit tests for `UsageParser` and `Config`
- `CLAUDE.md` project instructions

### Changed

- Persisted window position across launches

## [1.0.2] - 2026-02-20

### Added

- Pace-based color coding for weekly usage (compares actual vs expected usage in billing cycle)

### Changed

- Fixed blocking I/O in tmux process execution
- Eliminated force unwraps throughout codebase
- Improved task lifecycle management
- Improved Makefile with help target and cleanup

## [1.0.1] - 2026-02-20

### Added

- macOS menu bar widget for monitoring Claude Code API usage
- Session and weekly usage percentage display
- Live countdown timers to quota resets
- Fixed-threshold color coding for session usage (green/orange/red)
- Floating always-on-top panel
- Automated `/usage` CLI polling via isolated tmux sessions
