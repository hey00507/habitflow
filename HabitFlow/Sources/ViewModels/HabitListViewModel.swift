import Foundation

@MainActor
@Observable
final class HabitListViewModel {
    private(set) var habits: [Habit] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let service: HabitServiceProtocol
    private let notificationService: NotificationServiceProtocol?

    init(service: HabitServiceProtocol, notificationService: NotificationServiceProtocol? = nil) {
        self.service = service
        self.notificationService = notificationService
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
            await scheduleNotifications(for: created)
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
            // 기존 알림 취소 후 재등록
            if let habitId = habit.id {
                try? await notificationService?.cancelNotifications(for: habitId)
            }
            await scheduleNotifications(for: habit)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteHabit(_ habitId: String) async {
        do {
            try await service.deleteHabit(habitId)
            habits.removeAll { $0.id == habitId }
            try? await notificationService?.cancelNotifications(for: habitId)
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

    private func scheduleNotifications(for habit: Habit) async {
        guard let notificationService else { return }
        let entries = NotificationScheduler.notificationsForHabit(habit)
        for entry in entries {
            try? await notificationService.schedulePreNotification(for: habit, weekday: entry.weekday)
        }
        let overdueEntries = NotificationScheduler.overdueNotificationsForHabit(habit, delayMinutes: 60)
        for entry in overdueEntries {
            try? await notificationService.scheduleOverdueNotification(for: habit, weekday: entry.weekday, delayMinutes: 60)
        }
    }
}
