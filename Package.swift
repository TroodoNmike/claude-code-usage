// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClaudeUsageWidget",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ClaudeUsageWidget",
            path: "Sources"
        ),
        .testTarget(
            name: "ClaudeUsageWidgetTests",
            dependencies: ["ClaudeUsageWidget"],
            path: "Tests"
        ),
    ]
)
