import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: UsageWidgetPanel!
    private var viewModel: UsageViewModel!
    private var statusItem: NSStatusItem!
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        viewModel = UsageViewModel()

        // Menu bar status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItemTitle(state: viewModel.state, style: viewModel.statusBarStyle, sessionCountdown: viewModel.sessionCountdown, weekCountdown: viewModel.weekCountdown)

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked)
        }

        panel = UsageWidgetPanel()

        let hostingView = NSHostingView(
            rootView: UsageWidgetView(
                viewModel: viewModel,
                onTogglePin: { [weak self] in
                    self?.viewModel.isPinned.toggle()
                }
            )
        )
        panel.contentView = hostingView
        panel.orderFrontRegardless()

        // Sync pin state to panel level
        viewModel.$isPinned.sink { [weak self] pinned in
            self?.panel.isPinned = pinned
        }.store(in: &cancellables)

        // Sync dark mode to panel appearance — sole source of truth for color scheme
        viewModel.$forceDarkMode.sink { [weak self] dark in
            guard let panel = self?.panel else { return }
            let appearance = dark ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
            panel.appearance = appearance
            panel.contentView?.appearance = appearance
            panel.invalidateShadow()
            panel.displayIfNeeded()
        }.store(in: &cancellables)

        // Update menu bar when state, style, or countdowns change
        viewModel.$state
            .combineLatest(viewModel.$statusBarStyle, viewModel.$sessionCountdown, viewModel.$weekCountdown)
            .sink { [weak self] state, style, sessionCD, weekCD in
                self?.updateStatusItemTitle(state: state, style: style, sessionCountdown: sessionCD, weekCountdown: weekCD)
            }
            .store(in: &cancellables)

        viewModel.start()
    }

    private func updateStatusItemTitle(
        state: UsageViewModel.State,
        style: UsageViewModel.StatusBarStyle,
        sessionCountdown: String?,
        weekCountdown: String?
    ) {
        guard let button = statusItem?.button else { return }
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)

        switch state {
        case .loading:
            button.title = "⏳"
        case .loaded(let data):
            let text: String
            switch style {
            case .sessionOnly:
                text = data.sessionPct.map { "\($0)%" } ?? "—"
            case .sessionAndWeek:
                let s = data.sessionPct.map { "\($0)%" } ?? "—"
                let w = data.weekPct.map { "\($0)%" } ?? "—"
                text = "S:\(s) W:\(w)"
            case .withCountdowns:
                let s = data.sessionPct.map { "\($0)%" } ?? "—"
                let sReset = sessionCountdown ?? "?"
                let w = data.weekPct.map { "\($0)%" } ?? "—"
                let wReset = weekCountdown ?? "?"
                text = "S:\(s)(\(sReset)) W:\(w)(\(wReset))"
            }
            button.attributedTitle = NSAttributedString(string: text, attributes: [.font: font])
        case .error:
            button.title = "⚠️"
        }
    }

    @objc private func statusItemClicked() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.orderFrontRegardless()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        viewModel.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
