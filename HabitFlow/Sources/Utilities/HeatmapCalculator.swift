import Foundation

enum HeatmapCalculator {

    /// Calculate intensity level (0-4) from completion count
    static func intensity(for count: Int) -> Int {
        switch count {
        case ..<1: return 0
        case 1: return 1
        case 2: return 2
        case 3: return 3
        default: return 4
        }
    }

    /// Build heatmap entries from multiple habits' logs
    static func buildEntries(from logs: [String: [HabitLog]], startDate: String, endDate: String) -> [HeatmapEntry] {
        let dates = dateRange(from: startDate, to: endDate)

        var countByDate: [String: Int] = [:]
        for date in dates {
            countByDate[date] = 0
        }

        for (_, habitLogs) in logs {
            for log in habitLogs where log.isCompleted {
                if countByDate[log.date] != nil {
                    countByDate[log.date]! += 1
                }
            }
        }

        return dates.map { date in
            let count = countByDate[date, default: 0]
            return HeatmapEntry(date: date, count: count, intensity: intensity(for: count))
        }
    }

    /// Generate date range as array of "yyyy-MM-dd" strings
    static func dateRange(from startDate: String, to endDate: String) -> [String] {
        guard let start = DateFormat.date(from: startDate),
              let end = DateFormat.date(from: endDate),
              start <= end else {
            return []
        }

        var dates: [String] = []
        var current = start
        while current <= end {
            dates.append(DateFormat.string(from: current))
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }

    /// Calculate the start date for N weeks ago (Sunday-aligned)
    static func weeksAgoStart(weeks: Int, from referenceDate: Date) -> String {
        let calendar = Calendar.current
        let weeksAgo = calendar.date(byAdding: .day, value: -(weeks * 7), to: referenceDate)!
        let weekday = calendar.component(.weekday, from: weeksAgo)
        let sundayAligned = calendar.date(byAdding: .day, value: -(weekday - 1), to: weeksAgo)!
        return DateFormat.string(from: sundayAligned)
    }
}
