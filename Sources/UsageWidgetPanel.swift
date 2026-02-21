import AppKit

@MainActor
final class UsageWidgetPanel: NSPanel {
    var isPinned = true {
        didSet {
            level = isPinned ? .floating : .normal
        }
    }

    init() {
        super.init(
            contentRect: NSRect(
                x: 0, y: 0,
                width: Config.windowWidth,
                height: Config.windowHeight
            ),
            styleMask: [.titled, .closable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        title = "Claude Usage"
        level = .floating
        isFloatingPanel = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isOpaque = false
        backgroundColor = .windowBackgroundColor

        // Restore last known position, or default to top-right corner
        if !setFrameAutosaveName("ClaudeUsagePanel") || !setFrameUsingName("ClaudeUsagePanel") {
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let origin = NSPoint(
                    x: screenFrame.maxX - Config.windowWidth - 20,
                    y: screenFrame.maxY - Config.windowHeight - 20
                )
                setFrameOrigin(origin)
            }
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
