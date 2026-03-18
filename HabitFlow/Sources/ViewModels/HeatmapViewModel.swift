import Foundation

@MainActor @Observable
class HeatmapViewModel {
    var entries: [HeatmapEntry] = []
    var habits: [Habit] = []
    var selectedHabitId: String? = nil
    var weeks: Int = 12
    var errorMessage: String?

    private let service: HabitServiceProtocol

    init(service: HabitServiceProtocol) {
        self.service = service
    }

    func loadHeatmap() async {
        let today = Date()
        let startDate = HeatmapCalculator.weeksAgoStart(weeks: weeks, from: today)
        let endDate = DateFormat.string(from: today)

        do {
            habits = try await service.fetchHabits()
        } catch {
            errorMessage = error.localizedDescription
            entries = []
            return
        }

        let targetHabits: [Habit]
        if let selectedId = selectedHabitId {
            targetHabits = habits.filter { $0.id == selectedId }
        } else {
            targetHabits = habits
        }

        var allLogs: [String: [HabitLog]] = [:]
        for habit in targetHabits {
            guard let habitId = habit.id else { continue }
            if let logs = try? await service.fetchLogs(habitId: habitId, from: startDate, to: endDate) {
                allLogs[habitId] = logs
            }
        }

        entries = HeatmapCalculator.buildEntries(from: allLogs, startDate: startDate, endDate: endDate)
    }
}
