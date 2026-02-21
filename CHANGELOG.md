# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2026-02-21

### Added

- Session and weekly API usage monitoring via automated `/usage` CLI polling
- Pace-based color coding for weekly usage (compares actual vs expected usage in billing cycle)
- Fixed-threshold color coding for session usage (green/orange/red)
- Live countdown timers to session and weekly quota resets
- Floating always-on-top panel for persistent visibility
- Custom status bar format configuration
- Menu bar integration with quit menu
- Isolated tmux session management for reliable CLI interaction
