.PHONY: build run clean

build:
	swift build

run: build
	.build/debug/ClaudeUsageWidget

clean:
	swift package clean
