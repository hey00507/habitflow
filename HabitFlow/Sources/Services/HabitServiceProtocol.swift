import Foundation

protocol HabitServiceProtocol {
    // MARK: - Habits
    func createHabit(_ habit: Habit) async throws -> Habit
    func fetchHabits() async throws -> [Habit]
    func updateHabit(_ habit: Habit) async throws
    func deleteHabit(_ habitId: String) async throws

    // MARK: - Logs
    func createLog(_ log: HabitLog, habitId: String) async throws
    func fetchLogs(habitId: String, from: String, to: String) async throws -> [HabitLog]
    func deleteLog(habitId: String, date: String) async throws
}
