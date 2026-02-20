import Foundation

struct UsageData: Sendable {
    var sessionPct: Int?
    var weekPct: Int?
    var sessionResetRaw: String?
    var weekResetRaw: String?
}

enum UsageParser {
    nonisolated(unsafe) private static let pctPattern = /(\d+)%\s*used/
    nonisolated(unsafe) private static let resetPattern = /Resets\s+(.+?)$/

    static func isUsageScreen(_ lines: [String]) -> Bool {
        let text = lines.joined(separator: " ")
        return text.contains("% used") && (text.lowercased().contains("session") || text.lowercased().contains("week"))
    }

    static func parse(_ lines: [String]) -> UsageData? {
        var result = UsageData()
        var sectionOrder: [String] = []

        for (i, line) in lines.enumerated() {
            if let match = line.firstMatch(of: pctPattern) {
                guard let pct = Int(match.1) else { continue }
                let contextRange = max(0, i - 3)...i
                let context = lines[contextRange].joined(separator: " ").lowercased()
                if context.contains("session") && result.sessionPct == nil {
                    result.sessionPct = pct
                    sectionOrder.append("session")
                } else if context.contains("week") && result.weekPct == nil {
                    result.weekPct = pct
                    sectionOrder.append("week")
                }
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let resetMatch = trimmed.firstMatch(of: resetPattern), !sectionOrder.isEmpty {
                let section = sectionOrder.last!
                let resetValue = String(resetMatch.1).trimmingCharacters(in: .whitespaces)
                switch section {
                case "session" where result.sessionResetRaw == nil:
                    result.sessionResetRaw = resetValue
                case "week" where result.weekResetRaw == nil:
                    result.weekResetRaw = resetValue
                default:
                    break
                }
            }
        }

        if result.sessionPct != nil || result.weekPct != nil {
            return result
        }
        return nil
    }

    /// Parse "8pm (Europe/Warsaw)" -> "1h30m" countdown
    static func timeUntilSessionReset(_ resetStr: String) -> String? {
        let tzPattern = /\(([^)]+)\)/
        let tzMatch = resetStr.firstMatch(of: tzPattern)

        let clean = resetStr.replacing(/\s*\(.*?\)\s*$/, with: "").trimmingCharacters(in: .whitespaces)

        let timePattern = /(\d{1,2})(?::(\d{2}))?\s*(am|pm)/
        guard let match = clean.firstMatch(of: timePattern) else { return nil }

        guard let parsedHour = Int(match.1) else { return nil }
        var hour = parsedHour
        let minute = match.2.flatMap { Int($0) } ?? 0
        let ampm = String(match.3).lowercased()

        if ampm == "pm" && hour != 12 { hour += 12 }
        else if ampm == "am" && hour == 12 { hour = 0 }

        let tz: TimeZone?
        if let tzMatch {
            tz = TimeZone(identifier: String(tzMatch.1))
        } else {
            tz = nil
        }

        var cal = Calendar.current
        if let tz { cal.timeZone = tz }

        let now = Date()
        var components = cal.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard var resetTime = cal.date(from: components) else { return nil }
        if resetTime <= now {
            guard let next = cal.date(byAdding: .day, value: 1, to: resetTime) else { return nil }
            resetTime = next
        }

        let diff = resetTime.timeIntervalSince(now)
        let totalMinutes = Int(diff) / 60
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            return mins > 0 ? "\(hours)h\(String(format: "%02d", mins))m" : "\(hours)h"
        }
        return "\(totalMinutes)m"
    }

    /// Parse "Feb 25 at 7am (Europe/Warsaw)" -> "5d"
    static func daysUntilReset(_ resetStr: String) -> String? {
        let clean = resetStr.replacing(/\s*\(.*?\)\s*$/, with: "")
        let datePattern = /([A-Z][a-z]{2}\s+\d{1,2})/
        guard let match = clean.firstMatch(of: datePattern) else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        guard var resetDate = formatter.date(from: String(match.1)) else { return nil }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var comps = cal.dateComponents([.month, .day], from: resetDate)
        comps.year = cal.component(.year, from: today)
        guard let dated = cal.date(from: comps) else { return nil }
        resetDate = dated

        if resetDate < today {
            comps.year = cal.component(.year, from: today) + 1
            guard let nextYear = cal.date(from: comps) else { return nil }
            resetDate = nextYear
        }

        let days = cal.dateComponents([.day], from: today, to: resetDate).day ?? 0
        return "\(days)d"
    }
}
