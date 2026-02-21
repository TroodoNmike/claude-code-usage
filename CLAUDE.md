# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

macOS menu bar widget (Swift 6 / SwiftUI) that monitors Claude Code API usage by automating the `/usage` CLI command via tmux sessions. Displays session and weekly quota percentages with countdown timers.

## Build Commands

- `make build` — compile (`swift build`)
- `make run` — build and run the widget
- `make clean` — remove build artifacts

No test suite exists; testing is manual via `make run`.

## Architecture

MVVM with Swift 6 structured concurrency (actors, async/await) and Combine for reactive UI binding.

**Data flow:** `TmuxManager` (actor) creates an isolated tmux session → sends `/usage` keystrokes to Claude Code CLI → captures pane output → `UsageParser` extracts percentages/reset times via regex → `UsageViewModel` publishes state → SwiftUI views react.

**Key components:**
- `UsageViewModel` — central state (`loading`/`loaded`/`error`), runs two async loops: `pollLoop` (10s interval, fetches usage) and `countdownLoop` (1s interval, updates timers)
- `TmuxManager` — actor wrapping tmux process execution; handles session creation, key sending, pane capture, and cleanup
- `UsageParser` — stateless regex parsing of usage percentages and reset time strings
- `Config` — all constants: polling intervals, tmux settings, window dimensions, color thresholds
- `AppDelegate` (`@MainActor`) — sets up NSStatusItem + floating NSPanel
- `UsageWidgetPanel` — always-on-top floating panel hosting the SwiftUI view

**Color coding:** Session uses fixed thresholds (green <50%, orange 50-79%, red 80%+). Weekly uses pace-based logic comparing actual usage against expected usage for the current day in the billing cycle.

## Conventions

- Swift 6 strict concurrency: `@MainActor` for UI classes, `actor` for thread-safe managers
- Single SPM executable target, no external dependencies
- macOS 14.0+ deployment target
