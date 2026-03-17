import Foundation
import Testing
@testable import HabitFlow

@Suite("StreakCalculator Tests")
struct StreakCalculatorTests {

    // MARK: - 현재 Streak

    @Test("연속된 날짜들의 streak을 반환한다")
    func test_streak_consecutiveDays_returnsCount() {
        let logs = makeLogs(daysAgo: [0, 1, 2, 3, 4])
        let streak = StreakCalculator.currentStreak(from: logs)
        #expect(streak == 5)
    }

    @Test("중간에 빈 날이 있으면 최근 연속만 카운트한다")
    func test_streak_gapInMiddle_resetsToRecent() {
        let logs = makeLogs(daysAgo: [0, 1, 2, 5, 6]) // 3~4일 전 빠짐
        let streak = StreakCalculator.currentStreak(from: logs)
        #expect(streak == 3)
    }

    @Test("오늘 완료 안 했으면 어제부터 카운트한다")
    func test_streak_todayNotCompleted_countsFromYesterday() {
        let logs = makeLogs(daysAgo: [1, 2, 3])
        let streak = StreakCalculator.currentStreak(from: logs)
        #expect(streak == 3)
    }

    @Test("오늘도 어제도 없으면 streak은 0이다")
    func test_streak_noRecentLogs_returnsZero() {
        let logs = makeLogs(daysAgo: [5, 6, 7])
        let streak = StreakCalculator.currentStreak(from: logs)
        #expect(streak == 0)
    }

    @Test("로그가 없으면 streak은 0이다")
    func test_streak_noLogs_returnsZero() {
        let streak = StreakCalculator.currentStreak(from: [])
        #expect(streak == 0)
    }

    @Test("오늘 하루만 있으면 streak은 1이다")
    func test_streak_onlyToday_returnsOne() {
        let logs = makeLogs(daysAgo: [0])
        let streak = StreakCalculator.currentStreak(from: logs)
        #expect(streak == 1)
    }

    // MARK: - 최장 Streak

    @Test("최장 연속 기록을 반환한다")
    func test_longestStreak_returnsMax() {
        // 7~3일 전 (5일 연속) + 1~0일 전 (2일 연속)
        let logs = makeLogs(daysAgo: [0, 1, 3, 4, 5, 6, 7])
        let longest = StreakCalculator.longestStreak(from: logs)
        #expect(longest == 5)
    }

    @Test("모두 연속이면 전체 길이가 최장이다")
    func test_longestStreak_allConsecutive_returnsTotal() {
        let logs = makeLogs(daysAgo: [0, 1, 2, 3, 4, 5, 6])
        let longest = StreakCalculator.longestStreak(from: logs)
        #expect(longest == 7)
    }

    @Test("로그가 없으면 최장 streak은 0이다")
    func test_longestStreak_noLogs_returnsZero() {
        let longest = StreakCalculator.longestStreak(from: [])
        #expect(longest == 0)
    }

    @Test("모두 띄엄띄엄이면 최장 streak은 1이다")
    func test_longestStreak_allSeparated_returnsOne() {
        let logs = makeLogs(daysAgo: [0, 2, 4, 6])
        let longest = StreakCalculator.longestStreak(from: logs)
        #expect(longest == 1)
    }

    // MARK: - Helper

    private func makeLogs(daysAgo: [Int]) -> [HabitLog] {
        let calendar = Calendar.current
        return daysAgo.map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: .now)!
            let dateStr = DateFormatter.yyyyMMdd.string(from: date)
            return HabitLog(date: dateStr, isCompleted: true)
        }
    }
}

private extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
