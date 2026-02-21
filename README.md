# Claude Code Usage Widget

A macOS menu bar widget that monitors your [Claude Code](https://claude.ai/code) API usage in real time. Displays session and weekly quota percentages with countdown timers in a floating always-on-top panel.

<!-- ![Screenshot](screenshot.png) -->

## Features

- **Session & weekly usage monitoring** — polls Claude Code's `/usage` command automatically
- **Pace-based color coding** — weekly usage color reflects whether you're ahead or behind expected pace in the billing cycle
- **Countdown timers** — live countdowns to session and weekly quota resets
- **Floating panel** — always-on-top window so usage stays visible while you work
- **Custom status bar formats** — configurable menu bar display
- **Menu bar integration** — quick access via macOS status bar with quit menu

## Requirements

- macOS 14.0+
- [tmux](https://github.com/tmux/tmux) installed and on your `PATH`
- [Claude Code CLI](https://claude.ai/code) installed and authenticated

## Installation

```bash
git clone https://github.com/anthropics/claude-code-usage.git
cd claude-code-usage
make build
make run
```

## How It Works

The widget uses an MVVM architecture with Swift 6 structured concurrency:

1. **TmuxManager** (actor) creates an isolated tmux session and sends `/usage` keystrokes to Claude Code CLI
2. **UsageParser** extracts usage percentages and reset times from the captured output via regex
3. **UsageViewModel** publishes state changes on a 10-second polling interval
4. **SwiftUI views** react to state updates and render the floating panel

Color coding uses fixed thresholds for session usage (green < 50%, orange 50–79%, red 80%+) and pace-based logic for weekly usage that compares actual usage against expected usage for the current day in the billing cycle.

## Build Commands

| Command      | Description                |
|-------------|----------------------------|
| `make build` | Compile the project        |
| `make run`   | Build and run the widget   |
| `make test`  | Run unit tests             |
| `make clean` | Remove build artifacts     |

## License

[MIT](LICENSE)
