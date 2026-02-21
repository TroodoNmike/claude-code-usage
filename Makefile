.PHONY: help build run clean test reset

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-10s %s\n", $$1, $$2}'

build: ## Build the project
	swift build

run: build ## Build and run the widget
	@trap 'tmux kill-session -t claude-usage-widget 2>/dev/null; exit' INT TERM EXIT; \
	.build/debug/ClaudeUsageWidget

test: ## Run unit tests
	swift test

clean: ## Remove build artifacts
	swift package clean

reset: ## Reset all saved preferences (window position, size, settings)
	defaults delete ClaudeUsageWidget 2>/dev/null || true
	@echo "All preferences reset. Next launch will be like a fresh install."
