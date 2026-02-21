import SwiftUI

@MainActor
final class UsageViewModel: ObservableObject {
    enum State: Sendable {
        case loading(String)
        case loaded(UsageData)
        case notAuthenticated
        case error(String)
    }

    @Published var state: State = .loading("Starting Claude...")
    @Published var sessionCountdown: String?
    @Published var weekCountdown: String?
    @Published var weekDaysLeft: Int?
    @Published var sessionResetDateTime: String?
    @Published var weekResetDateTime: String?
    @Published var lastUpdatedAgo: String = ""
    @Published var isPinned = true

    enum StatusBarStyle: Equatable, Hashable, Sendable {
        case sessionOnly
        case sessionAndWeek
        case withCountdowns
        case compact
        case detailed
        case custom

        var label: String {
            switch self {
            case .sessionOnly: "Session only"
            case .sessionAndWeek: "Session + Week"
            case .withCountdowns: "With timers"
            case .compact: "Compact"
            case .detailed: "Detailed"
            case .custom: "Custom..."
            }
        }

        static let allCases: [StatusBarStyle] = [.sessionOnly, .sessionAndWeek, .withCountdowns, .compact, .detailed, .custom]

        var intValue: Int {
            switch self {
            case .sessionOnly: 0
            case .sessionAndWeek: 1
            case .withCountdowns: 2
            case .custom: 3
            case .compact: 4
            case .detailed: 5
            }
        }

        init(intValue: Int) {
            switch intValue {
            case 0: self = .sessionOnly
            case 1: self = .sessionAndWeek
            case 2: self = .withCountdowns
            case 3: self = .custom
            case 4: self = .compact
            case 5: self = .detailed
            default: self = .sessionOnly
            }
        }

        var preview: String {
            switch self {
            case .sessionOnly: "50%"
            case .sessionAndWeek: "S:50% W:75%"
            case .withCountdowns: "S:50%(2h) W:75%(3/7)"
            case .compact: "50%|75% (4/7)"
            case .detailed: "Session:50% resets 2h | Week:75% day 3/7"
            case .custom: ""
            }
        }

        var formatString: String {
            switch self {
            case .sessionOnly: "{s}%"
            case .sessionAndWeek: "S:{s}% W:{w}%"
            case .withCountdowns: "S:{s}%({sr}) W:{w}%({wr})"
            case .compact: "{s}%|{w}% ({wd}/7)"
            case .detailed: "Session:{s}% resets {sr} | Week:{w}% day {wr}"
            case .custom: ""
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
        didSet { UserDefaults.standard.set(statusBarStyle.intValue, forKey: "statusBarStyle") }
    }
    @Published var customFormat: String {
        didSet { UserDefaults.standard.set(customFormat, forKey: "customFormat") }
    }
    @Published var zoomLevel: CGFloat {
        didSet { UserDefaults.standard.set(Double(zoomLevel), forKey: "zoomLevel") }
    }
    @Published var showOptions: Bool {
        didSet { UserDefaults.standard.set(showOptions, forKey: "showOptions") }
    }

    static let zoomMin: CGFloat = 1.0
    static let zoomMax: CGFloat = 2.0
    static let zoomStep: CGFloat = 0.25

    init() {
        let defaults = UserDefaults.standard
        self.forceDarkMode = defaults.object(forKey: "forceDarkMode") as? Bool ?? true
        self.showLastUpdated = defaults.object(forKey: "showLastUpdated") as? Bool ?? true
        self.statusBarStyle = StatusBarStyle(intValue: defaults.integer(forKey: "statusBarStyle"))
        self.customFormat = defaults.string(forKey: "customFormat") ?? "S:{s}% W:{w}%"
        let stored = defaults.object(forKey: "zoomLevel") as? Double ?? 1.0
        self.zoomLevel = min(max(CGFloat(stored), Self.zoomMin), Self.zoomMax)
        self.showOptions = defaults.object(forKey: "showOptions") as? Bool ?? false
    }

    static func formatMenuBar(
        _ format: String,
        data: UsageData,
        sessionCountdown: String?,
        weekCountdown: String?,
        weekDaysLeft: Int?,
        sessionResetDateTime: String? = nil,
        weekResetDateTime: String? = nil
    ) -> String {
        var result = format
        result = result.replacingOccurrences(of: "{s}", with: data.sessionPct.map { "\($0)" } ?? "—")
        result = result.replacingOccurrences(of: "{w}", with: data.weekPct.map { "\($0)" } ?? "—")
        result = result.replacingOccurrences(of: "{sr}", with: sessionCountdown ?? "?")
        result = result.replacingOccurrences(of: "{wr}", with: weekCountdown ?? "?")
        let daysGone = weekDaysLeft.map { 7 - $0 + 1 }
        result = result.replacingOccurrences(of: "{wd}", with: daysGone.map { "\($0)" } ?? "?")
        result = result.replacingOccurrences(of: "{wl}", with: weekDaysLeft.map { "\($0)" } ?? "?")
        result = result.replacingOccurrences(of: "{srt}", with: sessionResetDateTime ?? "?")
        result = result.replacingOccurrences(of: "{wrt}", with: weekResetDateTime ?? "?")
        return result
    }

    @Published var isRefreshing = false

    private let tmux = TmuxManager()
    private var pollTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var lastUpdateTime: Date?
    private var cachedData: UsageData?
    private var loadingStartTime: Date?

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        cachedData = nil
        loadingStartTime = nil
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

        if UsageParser.isLoginScreen(lines) {
            state = .notAuthenticated
            loadingStartTime = nil
            return
        }

        if UsageParser.isUsageScreen(lines), let data = UsageParser.parse(lines) {
            cachedData = data
            lastUpdateTime = Date()
            loadingStartTime = nil
            state = .loaded(data)
            updateCountdowns(from: data)
        } else if cachedData == nil {
            if loadingStartTime == nil {
                loadingStartTime = Date()
            }
            if let start = loadingStartTime, Date().timeIntervalSince(start) > 60 {
                state = .error("Usage data not available.\nTap Reload to retry.")
            } else {
                state = .loading("Waiting for usage data...")
            }
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

    private static let resetDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mma"
        f.amSymbol = "am"
        f.pmSymbol = "pm"
        return f
    }()

    private func updateCountdowns(from data: UsageData) {
        if let raw = data.sessionResetRaw {
            sessionCountdown = UsageParser.timeUntilSessionReset(raw)
            if let date = UsageParser.sessionResetDate(raw) {
                sessionResetDateTime = Self.resetDateFormatter.string(from: date)
            }
        }
        if let raw = data.weekResetRaw {
            if let days = UsageParser.daysLeftUntilReset(raw) {
                weekDaysLeft = days
                weekCountdown = UsageParser.weekDayLabel(daysLeft: days)
            }
            if let date = UsageParser.weekResetDate(raw) {
                weekResetDateTime = Self.resetDateFormatter.string(from: date)
            }
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
