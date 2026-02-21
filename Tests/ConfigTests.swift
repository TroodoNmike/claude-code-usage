import SwiftUI
import Testing
@testable import ClaudeUsageWidget

@Suite("Config")
struct ConfigTests {

    // MARK: - usageColor

    @Test func usageColor_green_below50() {
        #expect(Config.usageColor(for: 0) == Color(red: 0.0, green: 0.78, blue: 0.39))
        #expect(Config.usageColor(for: 49) == Color(red: 0.0, green: 0.78, blue: 0.39))
    }

    @Test func usageColor_orange_50to79() {
        #expect(Config.usageColor(for: 50) == Color(red: 1.0, green: 0.78, blue: 0.0))
        #expect(Config.usageColor(for: 79) == Color(red: 1.0, green: 0.78, blue: 0.0))
    }

    @Test func usageColor_red_80plus() {
        #expect(Config.usageColor(for: 80) == Color(red: 1.0, green: 0.24, blue: 0.24))
        #expect(Config.usageColor(for: 100) == Color(red: 1.0, green: 0.24, blue: 0.24))
    }

    // MARK: - weeklyUsageColor

    @Test func weeklyUsageColor_nilDaysLeft_fallsBackToFixed() {
        // With nil daysLeft, should use fixed thresholds (same as usageColor)
        #expect(Config.weeklyUsageColor(pct: 30, daysLeft: nil) == Color(red: 0.0, green: 0.78, blue: 0.39))
        #expect(Config.weeklyUsageColor(pct: 60, daysLeft: nil) == Color(red: 1.0, green: 0.78, blue: 0.0))
        #expect(Config.weeklyUsageColor(pct: 90, daysLeft: nil) == Color(red: 1.0, green: 0.24, blue: 0.24))
    }

    @Test func weeklyUsageColor_belowPace_green() {
        // Day 1 of 7 (daysLeft=7), expected = 1/7*100 ≈ 14.3%
        // 10% is below expected → green
        #expect(Config.weeklyUsageColor(pct: 10, daysLeft: 7) == Color(red: 0.0, green: 0.78, blue: 0.39))
    }

    @Test func weeklyUsageColor_atPace_orange() {
        // Day 4 of 7 (daysLeft=4), expected = 4/7*100 ≈ 57.1%
        // 60% is >= expected but < expected+20 → orange
        #expect(Config.weeklyUsageColor(pct: 60, daysLeft: 4) == Color(red: 1.0, green: 0.78, blue: 0.0))
    }

    @Test func weeklyUsageColor_aheadOfPace_red() {
        // Day 1 of 7 (daysLeft=7), expected = 1/7*100 ≈ 14.3%
        // 50% is >= expected+20 → red
        #expect(Config.weeklyUsageColor(pct: 50, daysLeft: 7) == Color(red: 1.0, green: 0.24, blue: 0.24))
    }

    @Test func weeklyUsageColor_lastDay_highUsageStillGreen() {
        // Day 7 of 7 (daysLeft=1), expected = 7/7*100 = 100%
        // 90% is below expected → green
        #expect(Config.weeklyUsageColor(pct: 90, daysLeft: 1) == Color(red: 0.0, green: 0.78, blue: 0.39))
    }
}
