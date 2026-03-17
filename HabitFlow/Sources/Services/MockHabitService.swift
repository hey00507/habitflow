import Foundation

final class MockHabitService: HabitServiceProtocol, @unchecked Sendable {
    private var habits: [Habit] = []
    private var logs: [String: [HabitLog]] = [:] // habitId: [HabitLog]

    // MARK: - Habits

    func createHabit(_ habit: Habit) async throws -> Habit {
        var newHabit = habit
        newHabit.id = UUID().uuidString
        habits.append(newHabit)
        return newHabit
    }

    func fetchHabits() async throws -> [Habit] {
        habits.filter { !$0.isArchived }
    }

    func updateHabit(_ habit: Habit) async throws {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else {
            throw HabitServiceError.notFound
        }
        habits[index] = habit
    }

    func deleteHabit(_ habitId: String) async throws {
        habits.removeAll { $0.id == habitId }
        logs.removeValue(forKey: habitId)
    }

    // MARK: - Logs

    func createLog(_ log: HabitLog, habitId: String) async throws {
        var existingLogs = logs[habitId, default: []]
        // date를 문서 ID로 사용 — 같은 날짜면 덮어쓰기
        existingLogs.removeAll { $0.date == log.date }
        var newLog = log
        newLog.id = log.date
        existingLogs.append(newLog)
        logs[habitId] = existingLogs
    }

    func fetchLogs(habitId: String, from: String, to: String) async throws -> [HabitLog] {
        let habitLogs = logs[habitId, default: []]
        return habitLogs.filter { $0.date >= from && $0.date <= to }
    }

    func deleteLog(habitId: String, date: String) async throws {
        logs[habitId]?.removeAll { $0.date == date }
    }
}

enum HabitServiceError: Error {
    case notFound
    case unauthorized
}
