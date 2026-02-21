import SwiftUI

struct UsageWidgetView: View {
    @ObservedObject var viewModel: UsageViewModel
    let onTogglePin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Claude Usage")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Button(action: { viewModel.refresh() }) {
                    if viewModel.isRefreshing {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 11, height: 11)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isRefreshing)
                .help("Restart tmux session")
                Spacer()
                Button(action: onTogglePin) {
                    Image(systemName: viewModel.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 11))
                        .foregroundColor(viewModel.isPinned ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help(viewModel.isPinned ? "Unpin from top" : "Pin on top")
            }

            switch viewModel.state {
            case .loading(let message):
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text(message)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                Spacer()

            case .loaded(let data):
                usageSection(
                    label: "Session",
                    pct: data.sessionPct,
                    countdown: viewModel.sessionCountdown,
                    resetDateTime: viewModel.sessionResetDateTime
                )
                usageSection(
                    label: "Week",
                    pct: data.weekPct,
                    countdown: viewModel.weekCountdown,
                    daysLeft: viewModel.weekDaysLeft,
                    resetDateTime: viewModel.weekResetDateTime
                )

                if viewModel.showLastUpdated {
                    Text(viewModel.lastUpdatedAgo)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 0)

                Button(action: { viewModel.showOptions.toggle() }) {
                    Text(viewModel.showOptions ? "Hide options" : "Show options")
                        .font(.system(size: 10))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)

                if viewModel.showOptions {
                    optionsSection
                }

            case .error(let message):
                Spacer()
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .padding(12)
        .frame(minWidth: Config.windowWidth, minHeight: Config.windowHeight)
    }

    @ViewBuilder
    private func usageSection(label: String, pct: Int?, countdown: String?, daysLeft: Int? = nil, resetDateTime: String? = nil) -> some View {
        let z = viewModel.zoomLevel
        VStack(alignment: .leading, spacing: 3 * z) {
            HStack {
                Text(label)
                    .font(.system(size: 11 * z, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                if let pct {
                    let color = daysLeft != nil
                        ? Config.weeklyUsageColor(pct: pct, daysLeft: daysLeft)
                        : Config.usageColor(for: pct)
                    Text("\(pct)%")
                        .font(.system(size: 11 * z, weight: .bold, design: .monospaced))
                        .foregroundColor(color)
                }
            }
            if let pct {
                ProgressBarView(percentage: pct, daysLeft: daysLeft)
                    .frame(height: 6 * z)
            }
            if let countdown {
                let prefix = daysLeft != nil ? "Day" : "Resets in"
                HStack(spacing: 4) {
                    Text("\(prefix) \(countdown)")
                        .font(.system(size: 10 * z))
                        .foregroundColor(.secondary)
                    if let resetDateTime {
                        Text("(\(resetDateTime))")
                            .font(.system(size: 10 * z))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var optionsSection: some View {
        // Zoom controls
        HStack(spacing: 8) {
            Button(action: {
                viewModel.zoomLevel = max(viewModel.zoomLevel - UsageViewModel.zoomStep, UsageViewModel.zoomMin)
            }) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(viewModel.zoomLevel <= UsageViewModel.zoomMin ? .secondary.opacity(0.3) : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.zoomLevel <= UsageViewModel.zoomMin)
            .help("Zoom out")
            Button(action: {
                viewModel.zoomLevel = min(viewModel.zoomLevel + UsageViewModel.zoomStep, UsageViewModel.zoomMax)
            }) {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(viewModel.zoomLevel >= UsageViewModel.zoomMax ? .secondary.opacity(0.3) : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.zoomLevel >= UsageViewModel.zoomMax)
            .help("Zoom in")
            Spacer()
        }

        // Settings row
        HStack(spacing: 12) {
            Toggle("Dark", isOn: $viewModel.forceDarkMode)
            Toggle("Updated", isOn: $viewModel.showLastUpdated)
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
        .font(.system(size: 10))
        .foregroundColor(.secondary)

        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text("Menu bar:")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Picker("", selection: $viewModel.statusBarStyle) {
                    ForEach(UsageViewModel.StatusBarStyle.allCases, id: \.self) { style in
                        Text(style.label).tag(style)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.mini)
                .font(.system(size: 10))
            }
            if viewModel.statusBarStyle != .custom {
                HStack(spacing: 4) {
                    Text(viewModel.statusBarStyle.preview)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Customize") {
                        viewModel.customFormat = viewModel.statusBarStyle.formatString
                        viewModel.statusBarStyle = .custom
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 9))
                    .foregroundColor(.accentColor)
                }
            }
            if viewModel.statusBarStyle == .custom {
                TextField("Format", text: $viewModel.customFormat)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, design: .monospaced))
                    .padding(5)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    )
                Text("{s} session %  {w} week %\n{sr} session reset  {wr} week day\n{wd} days elapsed  {wl} days left\n{srt} session reset date  {wrt} week reset date")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}
