import Foundation

enum StreakCalculator {

    /// 현재 연속 기록 (오늘 또는 어제부터 역순으로 카운트)
    static func currentStreak(from logs: [HabitLog]) -> Int {
        let dates = completedDateSet(from: logs)
        guard !dates.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // 오늘 있으면 오늘부터, 없으면 어제부터 시작
        let start: Date
        if dates.contains(today) {
            start = today
        } else {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if dates.contains(yesterday) {
                start = yesterday
            } else {
                return 0
            }
        }

        var streak = 0
        var current = start
        while dates.contains(current) {
            streak += 1
            current = calendar.date(byAdding: .day, value: -1, to: current)!
        }
        return streak
    }

    /// 역대 최장 연속 기록
    static func longestStreak(from logs: [HabitLog]) -> Int {
        let dates = completedDateSet(from: logs)
        guard !dates.isEmpty else { return 0 }

        let sorted = dates.sorted()
        let calendar = Calendar.current

        var longest = 1
        var current = 1

        for i in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[i - 1], to: sorted[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }

    // MARK: - Private

    private static func completedDateSet(from logs: [HabitLog]) -> Set<Date> {
        let calendar = Calendar.current
        return Set(
            logs
                .filter(\.isCompleted)
                .compactMap { DateFormat.date(from: $0.date) }
                .map { calendar.startOfDay(for: $0) }
        )
    }
}
