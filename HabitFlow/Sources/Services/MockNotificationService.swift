import Foundation

final class MockNotificationService: NotificationServiceProtocol, @unchecked Sendable {
    private(set) var scheduledIdentifiers: Set<String> = []
    private(set) var authorizationGranted: Bool = true

    // MARK: - NotificationServiceProtocol

    func requestAuthorization() async throws -> Bool {
        authorizationGranted
    }

    func schedulePreNotification(for habit: Habit, weekday: Int) async throws {
        guard let habitId = habit.id else { return }
        let identifier = NotificationScheduler.preNotificationIdentifier(habitId: habitId, weekday: weekday)
        scheduledIdentifiers.insert(identifier)
    }

    func cancelNotifications(for habitId: String) async throws {
        scheduledIdentifiers = scheduledIdentifiers.filter { !$0.hasPrefix("\(habitId)-") }
    }

    func cancelAllNotifications() async throws {
        scheduledIdentifiers.removeAll()
    }

    func pendingNotificationCount() async -> Int {
        scheduledIdentifiers.count
    }

    func rescheduleAll(habits: [Habit]) async throws {
        scheduledIdentifiers.removeAll()
        for habit in habits {
            let entries = NotificationScheduler.notificationsForHabit(habit)
            for entry in entries {
                scheduledIdentifiers.insert(entry.identifier)
            }
        }
    }

    // MARK: - M9b: 미완료 리마인드

    func scheduleOverdueNotification(for habit: Habit, weekday: Int, delayMinutes: Int) async throws {
        guard let habitId = habit.id else { return }
        let identifier = NotificationScheduler.overdueNotificationIdentifier(habitId: habitId, weekday: weekday)
        scheduledIdentifiers.insert(identifier)
    }

    func scheduleSummaryNotification(hour: Int, minute: Int) async throws {
        let identifier = NotificationScheduler.summaryNotificationIdentifier()
        scheduledIdentifiers.insert(identifier)
    }

    func cancelOverdueNotifications(for habitId: String) async throws {
        scheduledIdentifiers = scheduledIdentifiers.filter { !$0.contains("\(habitId)-overdue-") }
    }
}
