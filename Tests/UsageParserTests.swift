import Testing
@testable import ClaudeUsageWidget

@Suite("UsageParser")
struct UsageParserTests {

    // MARK: - isUsageScreen

    @Test func isUsageScreen_withValidSessionScreen() {
        let lines = ["Session usage", "42% used", "Resets 8pm (Europe/Warsaw)"]
        #expect(UsageParser.isUsageScreen(lines))
    }

    @Test func isUsageScreen_withValidWeekScreen() {
        let lines = ["Weekly usage", "60% used", "Resets Feb 25 at 7am (Europe/Warsaw)"]
        #expect(UsageParser.isUsageScreen(lines))
    }

    @Test func isUsageScreen_withBothSections() {
        let lines = ["Session: 42% used", "Week: 60% used"]
        #expect(UsageParser.isUsageScreen(lines))
    }

    @Test func isUsageScreen_returnsFalseForEmpty() {
        #expect(!UsageParser.isUsageScreen([]))
    }

    @Test func isUsageScreen_returnsFalseForUnrelatedContent() {
        let lines = ["Hello world", "Some random text"]
        #expect(!UsageParser.isUsageScreen(lines))
    }

    @Test func isUsageScreen_returnsFalseForPartialMatch() {
        let lines = ["50% complete"]  // has % but not "used"
        #expect(!UsageParser.isUsageScreen(lines))
    }

    // MARK: - parse

    @Test func parse_fullSessionAndWeekData() {
        let lines = [
            "Session usage",
            "42% used",
            "Resets 8pm (Europe/Warsaw)",
            "",
            "Weekly usage",
            "60% used",
            "Resets Feb 25 at 7am (Europe/Warsaw)",
        ]
        let result = UsageParser.parse(lines)
        #expect(result != nil)
        #expect(result?.sessionPct == 42)
        #expect(result?.weekPct == 60)
        #expect(result?.sessionResetRaw == "8pm (Europe/Warsaw)")
        #expect(result?.weekResetRaw == "Feb 25 at 7am (Europe/Warsaw)")
    }

    @Test func parse_sessionOnly() {
        let lines = [
            "Session usage",
            "75% used",
            "Resets 10pm (UTC)",
        ]
        let result = UsageParser.parse(lines)
        #expect(result != nil)
        #expect(result?.sessionPct == 75)
        #expect(result?.weekPct == nil)
    }

    @Test func parse_weekOnly() {
        let lines = [
            "Weekly usage",
            "30% used",
            "Resets Mar 1 at 9am (US/Pacific)",
        ]
        let result = UsageParser.parse(lines)
        #expect(result != nil)
        #expect(result?.weekPct == 30)
        #expect(result?.sessionPct == nil)
    }

    @Test func parse_returnsNilForGarbage() {
        let lines = ["hello", "world", "no data here"]
        #expect(UsageParser.parse(lines) == nil)
    }

    @Test func parse_returnsNilForEmpty() {
        #expect(UsageParser.parse([]) == nil)
    }

    @Test func parse_extractsPercentageWithContextLines() {
        // Percentage line without "session"/"week" directly on it,
        // but context (previous lines) contain the keyword
        let lines = [
            "Your session limit",
            "is shown below:",
            "",
            "88% used",
        ]
        let result = UsageParser.parse(lines)
        #expect(result != nil)
        #expect(result?.sessionPct == 88)
    }

    // MARK: - weekDayLabel

    @Test func weekDayLabel_7daysLeft() {
        #expect(UsageParser.weekDayLabel(daysLeft: 7) == "1/7")
    }

    @Test func weekDayLabel_1dayLeft() {
        #expect(UsageParser.weekDayLabel(daysLeft: 1) == "7/7")
    }

    @Test func weekDayLabel_0daysLeft() {
        #expect(UsageParser.weekDayLabel(daysLeft: 0) == "8/7")
    }

    @Test func weekDayLabel_middleOfWeek() {
        #expect(UsageParser.weekDayLabel(daysLeft: 4) == "4/7")
    }

    // MARK: - timeUntilSessionReset

    @Test func timeUntilSessionReset_validInput() {
        // Can't assert exact value since it depends on current time,
        // but should return non-nil for valid format
        let result = UsageParser.timeUntilSessionReset("8pm (Europe/Warsaw)")
        #expect(result != nil)
    }

    @Test func timeUntilSessionReset_withMinutes() {
        let result = UsageParser.timeUntilSessionReset("8:30pm (UTC)")
        #expect(result != nil)
    }

    @Test func timeUntilSessionReset_amTime() {
        let result = UsageParser.timeUntilSessionReset("7am (US/Eastern)")
        #expect(result != nil)
    }

    @Test func timeUntilSessionReset_returnsNilForGarbage() {
        #expect(UsageParser.timeUntilSessionReset("not a time") == nil)
    }

    @Test func timeUntilSessionReset_returnsNilForEmpty() {
        #expect(UsageParser.timeUntilSessionReset("") == nil)
    }

    @Test func timeUntilSessionReset_formatContainsHourOrMinute() {
        let result = UsageParser.timeUntilSessionReset("8pm (UTC)")!
        // Should match pattern like "5h30m", "12h", or "45m"
        let pattern = /^\d+[hm]/
        #expect(result.firstMatch(of: pattern) != nil)
    }

    // MARK: - daysLeftUntilReset

    @Test func daysLeftUntilReset_validInput() {
        let result = UsageParser.daysLeftUntilReset("Feb 25 at 7am (Europe/Warsaw)")
        #expect(result != nil)
        #expect(result! >= 0)
    }

    @Test func daysLeftUntilReset_returnsNilForGarbage() {
        #expect(UsageParser.daysLeftUntilReset("not a date") == nil)
    }

    @Test func daysLeftUntilReset_returnsNilForEmpty() {
        #expect(UsageParser.daysLeftUntilReset("") == nil)
    }

    @Test func daysLeftUntilReset_differentMonths() {
        let result = UsageParser.daysLeftUntilReset("Mar 1 at 9am (US/Pacific)")
        #expect(result != nil)
        #expect(result! >= 0)
    }
}
