import Foundation

@MainActor
@Observable
final class HabitListViewModel {
    private(set) var habits: [Habit] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let service: HabitServiceProtocol

    init(service: HabitServiceProtocol) {
        self.service = service
    }

    func loadHabits() async {
        isLoading = true
        errorMessage = nil
        do {
            habits = try await service.fetchHabits()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createHabit(_ habit: Habit) async {
        do {
            let created = try await service.createHabit(habit)
            habits.append(created)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateHabit(_ habit: Habit) async {
        do {
            try await service.updateHabit(habit)
            if let index = habits.firstIndex(where: { $0.id == habit.id }) {
                habits[index] = habit
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteHabit(_ habitId: String) async {
        do {
            try await service.deleteHabit(habitId)
            habits.removeAll { $0.id == habitId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func archiveHabit(_ habit: Habit) async {
        var archived = habit
        archived.isArchived = true
        await updateHabit(archived)
        habits.removeAll { $0.id == habit.id }
    }
}
