import Foundation
import UserNotifications

final class LocalNotificationService: NotificationServiceProtocol, @unchecked Sendable {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func schedulePreNotification(for habit: Habit, weekday: Int) async throws {
        guard let habitId = habit.id,
              let targetTime = habit.targetTime,
              let time = NotificationScheduler.preNotificationTime(targetTime: targetTime) else { return }

        let identifier = NotificationScheduler.preNotificationIdentifier(habitId: habitId, weekday: weekday)

        let content = UNMutableNotificationContent()
        content.title = "HabitFlow"
        content.body = "\(habit.name) 할 시간입니다"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = time.hour
        dateComponents.minute = time.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)
    }

    func scheduleOverdueNotification(for habit: Habit, weekday: Int, delayMinutes: Int) async throws {
        guard let habitId = habit.id,
              let targetTime = habit.targetTime,
              let time = NotificationScheduler.overdueNotificationTime(targetTime: targetTime, delayMinutes: delayMinutes) else { return }

        let identifier = NotificationScheduler.overdueNotificationIdentifier(habitId: habitId, weekday: weekday)

        let content = UNMutableNotificationContent()
        content.title = "HabitFlow"
        content.body = "아직 \(habit.name)을(를) 하지 않았습니다"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = time.hour
        dateComponents.minute = time.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)
    }

    func scheduleSummaryNotification(hour: Int, minute: Int) async throws {
        let identifier = NotificationScheduler.summaryNotificationIdentifier()

        let content = UNMutableNotificationContent()
        content.title = "HabitFlow"
        content.body = "오늘의 습관을 확인해보세요"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)
    }

    func cancelNotifications(for habitId: String) async throws {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix("\(habitId)-") }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func cancelOverdueNotifications(for habitId: String) async throws {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix("\(habitId)-overdue-") }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func cancelAllNotifications() async throws {
        center.removeAllPendingNotificationRequests()
    }

    func pendingNotificationCount() async -> Int {
        await center.pendingNotificationRequests().count
    }

    func rescheduleAll(habits: [Habit]) async throws {
        center.removeAllPendingNotificationRequests()

        for habit in habits {
            let preEntries = NotificationScheduler.notificationsForHabit(habit)
            for entry in preEntries {
                try await schedulePreNotification(for: habit, weekday: entry.weekday)
            }

            let overdueEntries = NotificationScheduler.overdueNotificationsForHabit(habit, delayMinutes: 60)
            for entry in overdueEntries {
                try await scheduleOverdueNotification(for: habit, weekday: entry.weekday, delayMinutes: 60)
            }
        }
    }
}
