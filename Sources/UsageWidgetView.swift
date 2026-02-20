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
                Spacer()
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
                    countdown: viewModel.sessionCountdown
                )
                usageSection(
                    label: "Week",
                    pct: data.weekPct,
                    countdown: viewModel.weekCountdown
                )

                if viewModel.showLastUpdated {
                    Text(viewModel.lastUpdatedAgo)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 0)

                // Settings row
                HStack(spacing: 12) {
                    Toggle("Dark", isOn: $viewModel.forceDarkMode)
                    Toggle("Updated", isOn: $viewModel.showLastUpdated)
                }
                .toggleStyle(.switch)
                .controlSize(.mini)
                .font(.system(size: 10))
                .foregroundColor(.secondary)

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
        .frame(width: Config.windowWidth, height: Config.windowHeight)
    }

    @ViewBuilder
    private func usageSection(label: String, pct: Int?, countdown: String?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                if let pct {
                    Text("\(pct)%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Config.usageColor(for: pct))
                }
            }
            if let pct {
                ProgressBarView(percentage: pct)
            }
            if let countdown {
                Text("Resets in \(countdown)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
}
