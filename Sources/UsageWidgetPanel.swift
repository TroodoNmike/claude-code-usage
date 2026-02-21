import AppKit

@MainActor
final class UsageWidgetPanel: NSPanel {
    var isPinned = true {
        didSet {
            level = isPinned ? .floating : .normal
        }
    }

    private static let frameSaveKey = "ClaudeUsagePanelFrame"

    init() {
        super.init(
            contentRect: NSRect(
                x: 0, y: 0,
                width: Config.windowWidth,
                height: Config.windowHeight
            ),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .utilityWindow],
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

        minSize = NSSize(width: Config.windowWidth, height: 100)
        maxSize = NSSize(width: 500, height: 600)

        // Restore saved position or default to top-right corner
        if let frameString = UserDefaults.standard.string(forKey: Self.frameSaveKey) {
            let saved = NSRectFromString(frameString)
            if saved.width > 0 && saved.height > 0 {
                setFrame(saved, display: false)
            } else {
                moveToDefaultPosition()
            }
        } else {
            moveToDefaultPosition()
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(windowDidMoveOrResize),
            name: NSWindow.didMoveNotification, object: self
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(windowDidMoveOrResize),
            name: NSWindow.didResizeNotification, object: self
        )
    }

    private func moveToDefaultPosition() {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let origin = NSPoint(
                x: screenFrame.maxX - Config.windowWidth - 20,
                y: screenFrame.maxY - Config.windowHeight - 20
            )
            setFrameOrigin(origin)
        }
    }

    @objc private func windowDidMoveOrResize() {
        UserDefaults.standard.set(NSStringFromRect(frame), forKey: Self.frameSaveKey)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
