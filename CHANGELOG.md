# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
