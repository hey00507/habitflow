import Foundation
import WidgetKit

struct TodayHabitItem: Identifiable {
    let habit: Habit
    var isCompleted: Bool
    var memo: String?

    var id: String { habit.id ?? UUID().uuidString }
}

@MainActor
@Observable
final class TodayViewModel {
    private(set) var todayHabits: [TodayHabitItem] = []
    private(set) var isLoading = false
    private(set) var currentStreak: Int = 0
    private(set) var longestStreak: Int = 0

    private let service: HabitServiceProtocol
    private let notificationService: NotificationServiceProtocol

    init(service: HabitServiceProtocol, notificationService: NotificationServiceProtocol = LocalNotificationService()) {
        self.service = service
        self.notificationService = notificationService
    }

    var completionRate: Double {
        guard !todayHabits.isEmpty else { return 0 }
        let completed = todayHabits.filter(\.isCompleted).count
        return Double(completed) / Double(todayHabits.count)
    }

    var completedCount: Int {
        todayHabits.filter(\.isCompleted).count
    }

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: .now)
    }

    private var todayWeekday: Int {
        Calendar.current.component(.weekday, from: .now) // 1=일 ~ 7=토
    }

    func loadToday() async {
        isLoading = true
        do {
            let allHabits = try await service.fetchHabits()
            let filtered = allHabits
                .filter { $0.schedule.contains(todayWeekday) }
                .sorted { sortByTargetTime($0, $1) }

            var items: [TodayHabitItem] = []
            for habit in filtered {
                let logs = try await service.fetchLogs(
                    habitId: habit.id ?? "",
                    from: todayString,
                    to: todayString
                )
                let log = logs.first
                items.append(TodayHabitItem(
                    habit: habit,
                    isCompleted: log?.isCompleted ?? false,
                    memo: log?.memo
                ))
            }
            todayHabits = items
            await loadStreaks()
            updateWidget()
        } catch {
            // 에러 시 빈 목록
        }
        isLoading = false
    }

    func toggleCheck(_ item: TodayHabitItem) async {
        guard let habitId = item.habit.id else { return }

        do {
            if item.isCompleted {
                // 체크 해제 → 알림 다시 스케줄링
                try await service.deleteLog(habitId: habitId, date: todayString)
                try await rescheduleNotifications(for: item.habit)
            } else {
                // 체크 완료 → 해당 습관의 오늘 알림 취소
                let log = HabitLog(date: todayString, isCompleted: true)
                try await service.createLog(log, habitId: habitId)
                try await notificationService.cancelNotifications(for: habitId)
                try await notificationService.cancelOverdueNotifications(for: habitId)
            }

            if let index = todayHabits.firstIndex(where: { $0.id == item.id }) {
                todayHabits[index].isCompleted.toggle()
            }
            updateWidget()
        } catch {
            // 에러 무시
        }
    }

    func addMemo(_ memo: String, to item: TodayHabitItem) async {
        guard let habitId = item.habit.id else { return }

        do {
            let log = HabitLog(date: todayString, isCompleted: true, memo: memo)
            try await service.createLog(log, habitId: habitId)

            if let index = todayHabits.firstIndex(where: { $0.id == item.id }) {
                todayHabits[index].isCompleted = true
                todayHabits[index].memo = memo
            }
            // 메모 추가 = 완료 → 알림 취소
            try await notificationService.cancelNotifications(for: habitId)
            try await notificationService.cancelOverdueNotifications(for: habitId)
            updateWidget()
        } catch {
            // 에러 무시
        }
    }

    private func rescheduleNotifications(for habit: Habit) async throws {
        guard habit.isNotificationEnabled else { return }
        let weekday = todayWeekday
        try await notificationService.schedulePreNotification(for: habit, weekday: weekday)
        try await notificationService.scheduleOverdueNotification(for: habit, weekday: weekday, delayMinutes: 60)
    }

    private func loadStreaks() async {
        var allLogs: [HabitLog] = []
        for item in todayHabits {
            guard let habitId = item.habit.id else { continue }
            if let logs = try? await service.fetchLogs(habitId: habitId, from: "2020-01-01", to: todayString) {
                allLogs.append(contentsOf: logs)
            }
        }
        let uniqueLogs = Dictionary(grouping: allLogs, by: \.date)
            .map { HabitLog(date: $0.key, isCompleted: true) }

        currentStreak = StreakCalculator.currentStreak(from: uniqueLogs)
        longestStreak = StreakCalculator.longestStreak(from: uniqueLogs)
    }

    private func updateWidget() {
        let widgetHabits = todayHabits.map {
            WidgetHabitItem(
                name: $0.habit.name,
                icon: $0.habit.icon,
                color: $0.habit.color,
                isCompleted: $0.isCompleted
            )
        }
        let data = WidgetHabitData(
            totalCount: widgetHabits.count,
            completedCount: widgetHabits.filter(\.isCompleted).count,
            habits: widgetHabits,
            heatmapEntries: [],
            updatedAt: .now
        )
        WidgetDataStore.save(data)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func sortByTargetTime(_ a: Habit, _ b: Habit) -> Bool {
        switch (a.targetTime, b.targetTime) {
        case let (aTime?, bTime?): return aTime < bTime
        case (_?, nil): return true
        case (nil, _?): return false
        case (nil, nil): return false
        }
    }
}
