import Foundation

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

    private let service: HabitServiceProtocol

    init(service: HabitServiceProtocol) {
        self.service = service
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
        } catch {
            // 에러 시 빈 목록
        }
        isLoading = false
    }

    func toggleCheck(_ item: TodayHabitItem) async {
        guard let habitId = item.habit.id else { return }

        do {
            if item.isCompleted {
                try await service.deleteLog(habitId: habitId, date: todayString)
            } else {
                let log = HabitLog(date: todayString, isCompleted: true)
                try await service.createLog(log, habitId: habitId)
            }

            if let index = todayHabits.firstIndex(where: { $0.id == item.id }) {
                todayHabits[index].isCompleted.toggle()
            }
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
        } catch {
            // 에러 무시
        }
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
