import SwiftUI

@MainActor
final class UsageViewModel: ObservableObject {
    enum State: Sendable {
        case loading(String)
        case loaded(UsageData)
        case error(String)
    }

    @Published var state: State = .loading("Starting Claude...")
    @Published var sessionCountdown: String?
    @Published var weekCountdown: String?
    @Published var lastUpdatedAgo: String = ""
    @Published var isPinned = true

    enum StatusBarStyle: Int, CaseIterable, Sendable {
        case sessionOnly = 0
        case sessionAndWeek = 1
        case withCountdowns = 2

        var label: String {
            switch self {
            case .sessionOnly: "Session %"
            case .sessionAndWeek: "Session + Week %"
            case .withCountdowns: "% + Countdowns"
            }
        }
    }

    @Published var forceDarkMode: Bool {
        didSet { UserDefaults.standard.set(forceDarkMode, forKey: "forceDarkMode") }
    }
    @Published var showLastUpdated: Bool {
        didSet { UserDefaults.standard.set(showLastUpdated, forKey: "showLastUpdated") }
    }
    @Published var statusBarStyle: StatusBarStyle {
        didSet { UserDefaults.standard.set(statusBarStyle.rawValue, forKey: "statusBarStyle") }
    }

    init() {
        let defaults = UserDefaults.standard
        self.forceDarkMode = defaults.object(forKey: "forceDarkMode") as? Bool ?? true
        self.showLastUpdated = defaults.object(forKey: "showLastUpdated") as? Bool ?? true
        self.statusBarStyle = StatusBarStyle(rawValue: defaults.integer(forKey: "statusBarStyle")) ?? .sessionOnly
    }

    @Published var isRefreshing = false

    private let tmux = TmuxManager()
    private var pollTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var lastUpdateTime: Date?
    private var cachedData: UsageData?

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        cachedData = nil
        state = .loading("Restarting Claude...")
        Task {
            pollTask?.cancel()
            await pollTask?.value
            pollTask = nil
            countdownTask?.cancel()
            await countdownTask?.value
            countdownTask = nil

            await tmux.killSession()
            try? await Task.sleep(for: .seconds(0.5))
            pollTask = Task { await self.pollLoop() }
            countdownTask = Task { await self.countdownLoop() }
        }
    }

    func start() {
        guard TmuxManager.findTmuxPath() != nil else {
            state = .error("tmux not found. Install with:\nbrew install tmux")
            return
        }
        pollTask = Task { await pollLoop() }
        countdownTask = Task { await countdownLoop() }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
        countdownTask?.cancel()
        countdownTask = nil
        let tmux = self.tmux
        Task { await tmux.killSession() }
    }

    // MARK: - Polling

    private func pollLoop() async {
        let exists = await tmux.sessionExists()
        if !exists {
            state = .loading("Starting Claude...")
            await tmux.createUsageSession()
        }

        await refreshAndCapture()
        if isRefreshing { isRefreshing = false }

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Config.usagePollInterval))
            if Task.isCancelled { break }
            await refreshAndCapture()
        }
    }

    private func refreshAndCapture() async {
        await tmux.sendRefreshKeys()
        try? await Task.sleep(for: .seconds(Config.usageRefreshDelay))
        let lines = await tmux.capturePane()

        if UsageParser.isUsageScreen(lines), let data = UsageParser.parse(lines) {
            cachedData = data
            lastUpdateTime = Date()
            state = .loaded(data)
            updateCountdowns(from: data)
        } else if cachedData == nil {
            state = .loading("Waiting for usage data...")
        }
    }

    // MARK: - Countdowns

    private func countdownLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { break }

            if let data = cachedData {
                updateCountdowns(from: data)
            }
            updateLastUpdatedAgo()
        }
    }

    private func updateCountdowns(from data: UsageData) {
        if let raw = data.sessionResetRaw {
            sessionCountdown = UsageParser.timeUntilSessionReset(raw)
        }
        if let raw = data.weekResetRaw {
            weekCountdown = UsageParser.daysUntilReset(raw)
        }
    }

    private func updateLastUpdatedAgo() {
        guard let t = lastUpdateTime else { return }
        let seconds = Int(Date().timeIntervalSince(t))
        if seconds < 5 {
            lastUpdatedAgo = "Updated just now"
        } else {
            lastUpdatedAgo = "Updated \(seconds)s ago"
        }
    }
}
