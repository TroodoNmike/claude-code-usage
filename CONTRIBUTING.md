# Contributing

## Setup

```bash
git clone https://github.com/anthropics/claude-code-usage.git
cd claude-code-usage
make build
make run
```

Requires macOS 14.0+, tmux, and Claude Code CLI.

## Development

- `make build` — compile
- `make run` — build and run
- `make test` — run unit tests
- `make clean` — remove build artifacts

## Code Style

- Swift 6 strict concurrency throughout
- `@MainActor` for UI classes, `actor` for thread-safe managers
- No external dependencies — pure SPM executable target

## Pull Requests

1. Fork the repo and create a feature branch
2. Make your changes
3. Ensure `make build` and `make test` pass
4. Open a PR with a clear description of the change
