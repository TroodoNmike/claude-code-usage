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
        updateStatusItemTitle(state: viewModel.state, style: viewModel.statusBarStyle, sessionCountdown: viewModel.sessionCountdown, weekCountdown: viewModel.weekCountdown, customFormat: viewModel.customFormat, weekDaysLeft: viewModel.weekDaysLeft, sessionResetDateTime: viewModel.sessionResetDateTime, weekResetDateTime: viewModel.weekResetDateTime)

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Widget", action: #selector(statusItemClicked), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu

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
            panel.appearance = dark ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
        }.store(in: &cancellables)

        // Update menu bar when state, style, countdowns, or custom format change
        viewModel.$state
            .combineLatest(viewModel.$statusBarStyle, viewModel.$sessionCountdown, viewModel.$weekCountdown)
            .combineLatest(viewModel.$customFormat, viewModel.$weekDaysLeft)
            .combineLatest(viewModel.$sessionResetDateTime, viewModel.$weekResetDateTime)
            .sink { [weak self] combo in
                let ((inner, customFormat, weekDaysLeft), sessionRT, weekRT) = combo
                let (state, style, sessionCD, weekCD) = inner
                self?.updateStatusItemTitle(state: state, style: style, sessionCountdown: sessionCD, weekCountdown: weekCD, customFormat: customFormat, weekDaysLeft: weekDaysLeft, sessionResetDateTime: sessionRT, weekResetDateTime: weekRT)
            }
            .store(in: &cancellables)

        viewModel.start()
    }

    private func updateStatusItemTitle(
        state: UsageViewModel.State,
        style: UsageViewModel.StatusBarStyle,
        sessionCountdown: String?,
        weekCountdown: String?,
        customFormat: String,
        weekDaysLeft: Int?,
        sessionResetDateTime: String? = nil,
        weekResetDateTime: String? = nil
    ) {
        guard let button = statusItem?.button else { return }
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)

        switch state {
        case .loading:
            button.title = "⏳"
        case .loaded(let data):
            let format = style == .custom ? customFormat : style.formatString
            let text = UsageViewModel.formatMenuBar(format, data: data, sessionCountdown: sessionCountdown, weekCountdown: weekCountdown, weekDaysLeft: weekDaysLeft, sessionResetDateTime: sessionResetDateTime, weekResetDateTime: weekResetDateTime)
            button.attributedTitle = NSAttributedString(string: text, attributes: [.font: font])
        case .error:
            button.title = "⚠️"
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
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
