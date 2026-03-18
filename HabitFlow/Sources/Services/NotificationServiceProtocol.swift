import Foundation

protocol NotificationServiceProtocol: Sendable {
    func requestAuthorization() async throws -> Bool
    func schedulePreNotification(for habit: Habit, weekday: Int) async throws
    func cancelNotifications(for habitId: String) async throws
    func cancelAllNotifications() async throws
    func pendingNotificationCount() async -> Int
    func rescheduleAll(habits: [Habit]) async throws
    func scheduleOverdueNotification(for habit: Habit, weekday: Int, delayMinutes: Int) async throws
    func scheduleSummaryNotification(hour: Int, minute: Int) async throws
    func cancelOverdueNotifications(for habitId: String) async throws
}
