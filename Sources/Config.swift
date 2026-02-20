import SwiftUI

enum Config {
    static let tmuxSessionName = "claude-usage-widget"
    static let tmuxPaneWidth = 120
    static let tmuxPaneHeight = 40

    static let usagePollInterval: TimeInterval = 10
    static let usageRefreshDelay: TimeInterval = 2.0
    static let usageKeyDelay: TimeInterval = 0.3

    static let windowWidth: CGFloat = 220
    static let windowHeight: CGFloat = 200

    static func usageColor(for pct: Int) -> Color {
        if pct >= 80 { return Color(red: 1.0, green: 0.24, blue: 0.24) }
        if pct >= 50 { return Color(red: 1.0, green: 0.78, blue: 0.0) }
        return Color(red: 0.0, green: 0.78, blue: 0.39)
    }
}
