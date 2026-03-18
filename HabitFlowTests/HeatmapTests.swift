import Foundation
import Testing
@testable import HabitFlow

// MARK: - HeatmapCalculator Tests

@Suite("HeatmapCalculator Tests")
struct HeatmapCalculatorTests {

    // MARK: - Intensity

    @Test("count 0이면 intensity 0을 반환한다")
    func intensity_zero_returns0() {
        #expect(HeatmapCalculator.intensity(for: 0) == 0)
    }

    @Test("count 1이면 intensity 1을 반환한다")
    func intensity_one_returns1() {
        #expect(HeatmapCalculator.intensity(for: 1) == 1)
    }

    @Test("count 2이면 intensity 2를 반환한다")
    func intensity_two_returns2() {
        #expect(HeatmapCalculator.intensity(for: 2) == 2)
    }

    @Test("count 3이면 intensity 3을 반환한다")
    func intensity_three_returns3() {
        #expect(HeatmapCalculator.intensity(for: 3) == 3)
    }

    @Test("count 4 이상이면 intensity 4를 반환한다")
    func intensity_fourOrMore_returns4() {
        #expect(HeatmapCalculator.intensity(for: 5) == 4)
    }

    @Test("음수 count이면 intensity 0을 반환한다")
    func intensity_negative_returns0() {
        #expect(HeatmapCalculator.intensity(for: -1) == 0)
    }

    // MARK: - Date Range

    @Test("같은 날짜면 1개 엔트리를 반환한다")
    func dateRange_sameDay_returns1() {
        let result = HeatmapCalculator.dateRange(from: "2026-03-18", to: "2026-03-18")
        #expect(result.count == 1)
        #expect(result.first == "2026-03-18")
    }

    @Test("3일 범위면 3개 엔트리를 반환한다")
    func dateRange_threeDays_returns3() {
        let result = HeatmapCalculator.dateRange(from: "2026-03-16", to: "2026-03-18")
        #expect(result.count == 3)
        #expect(result == ["2026-03-16", "2026-03-17", "2026-03-18"])
    }

    @Test("종료일이 시작일보다 이전이면 빈 배열을 반환한다")
    func dateRange_invalidRange_returnsEmpty() {
        let result = HeatmapCalculator.dateRange(from: "2026-03-18", to: "2026-03-16")
        #expect(result.isEmpty)
    }

    // MARK: - Build Entries

    @Test("로그가 없으면 모든 엔트리가 count 0, intensity 0이다")
    func buildEntries_noLogs_allZero() {
        let entries = HeatmapCalculator.buildEntries(
            from: [:],
            startDate: "2026-03-16",
            endDate: "2026-03-18"
        )
        #expect(entries.count == 3)
        #expect(entries.allSatisfy { $0.count == 0 && $0.intensity == 0 })
    }

    @Test("단일 습관 로그가 올바른 count를 반환한다")
    func buildEntries_singleHabitLogs_correctCounts() {
        let logs: [String: [HabitLog]] = [
            "habit1": [
                makeLog(date: "2026-03-16", isCompleted: true),
                makeLog(date: "2026-03-18", isCompleted: true),
            ]
        ]
        let entries = HeatmapCalculator.buildEntries(
            from: logs,
            startDate: "2026-03-16",
            endDate: "2026-03-18"
        )
        #expect(entries.count == 3)

        let day16 = entries.first { $0.date == "2026-03-16" }
        let day17 = entries.first { $0.date == "2026-03-17" }
        let day18 = entries.first { $0.date == "2026-03-18" }

        #expect(day16?.count == 1)
        #expect(day17?.count == 0)
        #expect(day18?.count == 1)
    }

    @Test("여러 습관이 같은 날 완료되면 합산된다")
    func buildEntries_multipleHabitsLogs_sumsPerDay() {
        let logs: [String: [HabitLog]] = [
            "habit1": [
                makeLog(date: "2026-03-17", isCompleted: true),
            ],
            "habit2": [
                makeLog(date: "2026-03-17", isCompleted: true),
            ]
        ]
        let entries = HeatmapCalculator.buildEntries(
            from: logs,
            startDate: "2026-03-16",
            endDate: "2026-03-18"
        )
        let day17 = entries.first { $0.date == "2026-03-17" }
        #expect(day17?.count == 2)
        #expect(day17?.intensity == 2)
    }

    @Test("isCompleted가 false인 로그는 카운트되지 않는다")
    func buildEntries_incompleteLog_notCounted() {
        let logs: [String: [HabitLog]] = [
            "habit1": [
                makeLog(date: "2026-03-17", isCompleted: false),
            ]
        ]
        let entries = HeatmapCalculator.buildEntries(
            from: logs,
            startDate: "2026-03-16",
            endDate: "2026-03-18"
        )
        let day17 = entries.first { $0.date == "2026-03-17" }
        #expect(day17?.count == 0)
    }

    @Test("날짜 범위 밖의 로그는 무시된다")
    func buildEntries_outsideDateRange_ignored() {
        let logs: [String: [HabitLog]] = [
            "habit1": [
                makeLog(date: "2026-03-15", isCompleted: true), // before range
                makeLog(date: "2026-03-17", isCompleted: true), // in range
                makeLog(date: "2026-03-20", isCompleted: true), // after range
            ]
        ]
        let entries = HeatmapCalculator.buildEntries(
            from: logs,
            startDate: "2026-03-16",
            endDate: "2026-03-18"
        )
        #expect(entries.count == 3)
        let day17 = entries.first { $0.date == "2026-03-17" }
        #expect(day17?.count == 1)

        // Outside dates should not appear
        #expect(entries.first { $0.date == "2026-03-15" } == nil)
        #expect(entries.first { $0.date == "2026-03-20" } == nil)
    }

    // MARK: - Weeks Ago Start

    @Test("12주 전 시작일이 일요일에 정렬된다")
    func weeksAgoStart_12weeks() {
        // Reference: 2026-03-18 (Wednesday)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let refDate = formatter.date(from: "2026-03-18")!

        let result = HeatmapCalculator.weeksAgoStart(weeks: 12, from: refDate)

        // 12 weeks = 84 days before 2026-03-18 is ~2025-12-24
        // Must be Sunday-aligned (Sunday on or before that date)
        let resultDate = formatter.date(from: result)!
        let weekday = Calendar.current.component(.weekday, from: resultDate)
        #expect(weekday == 1) // 1 = Sunday

        // Should be roughly 84 days before reference
        let daysBetween = Calendar.current.dateComponents([.day], from: resultDate, to: refDate).day!
        #expect(daysBetween >= 84)
        #expect(daysBetween < 91) // at most 6 extra days for Sunday alignment
    }

    // MARK: - Helper

    private func makeLog(date: String, isCompleted: Bool) -> HabitLog {
        HabitLog(id: date, date: date, isCompleted: isCompleted, memo: nil, completedAt: nil)
    }
}

// MARK: - HeatmapViewModel Tests

@Suite("HeatmapViewModel Tests")
@MainActor
struct HeatmapViewModelTests {
    let service = MockHabitService()

    private func makeViewModel() -> HeatmapViewModel {
        HeatmapViewModel(service: service)
    }

    @Test("습관이 없으면 entries가 비어있거나 모두 0이다")
    func loadHeatmap_noHabits_emptyEntries() async {
        let vm = makeViewModel()
        await vm.loadHeatmap()
        #expect(vm.entries.allSatisfy { $0.count == 0 })
    }

    @Test("로그가 있으면 entries에 올바른 count가 반영된다")
    func loadHeatmap_withLogs_populatesEntries() async throws {
        let habit = try await service.createHabit(Habit(name: "러닝"))

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: .now)

        try await service.createLog(
            HabitLog(date: todayStr, isCompleted: true),
            habitId: habit.id!
        )

        let vm = makeViewModel()
        await vm.loadHeatmap()

        let todayEntry = vm.entries.first { $0.date == todayStr }
        #expect(todayEntry != nil)
        #expect(todayEntry?.count == 1)
    }

    @Test("selectedHabitId 설정 시 해당 습관만 카운트된다")
    func loadHeatmap_filteredByHabit_onlyShowsOne() async throws {
        let habit1 = try await service.createHabit(Habit(name: "러닝"))
        let habit2 = try await service.createHabit(Habit(name: "독서"))

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: .now)

        try await service.createLog(
            HabitLog(date: todayStr, isCompleted: true),
            habitId: habit1.id!
        )
        try await service.createLog(
            HabitLog(date: todayStr, isCompleted: true),
            habitId: habit2.id!
        )

        let vm = makeViewModel()
        vm.selectedHabitId = habit1.id
        await vm.loadHeatmap()

        let todayEntry = vm.entries.first { $0.date == todayStr }
        #expect(todayEntry?.count == 1) // only habit1 counted
    }
}
