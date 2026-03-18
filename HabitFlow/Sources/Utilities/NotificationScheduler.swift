import Foundation

enum NotificationScheduler {

    /// "HH:mm" 문자열을 파싱하여 (hour, minute)를 반환한다.
    private static func parseTime(_ targetTime: String) -> (hour: Int, minute: Int)? {
        let parts = targetTime.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute) else {
            return nil
        }
        return (hour, minute)
    }

    /// targetTime("HH:mm")의 10분 전 시각을 반환한다.
    /// 자정을 넘어가는 경우 전날 23:5x로 래핑한다.
    static func preNotificationTime(targetTime: String) -> (hour: Int, minute: Int)? {
        guard let time = parseTime(targetTime) else { return nil }

        var newMinute = time.minute - 10
        var newHour = time.hour

        if newMinute < 0 {
            newMinute += 60
            newHour -= 1
            if newHour < 0 {
                newHour = 23
            }
        }

        return (hour: newHour, minute: newMinute)
    }

    /// 사전 알림 식별자: "{habitId}-pre-{weekday}"
    static func preNotificationIdentifier(habitId: String, weekday: Int) -> String {
        "\(habitId)-pre-\(weekday)"
    }

    /// 해당 습관이 주어진 요일에 알림을 받아야 하는지 판단한다.
    static func shouldScheduleNotification(for habit: Habit, weekday: Int) -> Bool {
        guard !habit.isArchived else { return false }
        guard habit.isNotificationEnabled else { return false }
        guard habit.targetTime != nil else { return false }
        guard habit.schedule.contains(weekday) else { return false }
        return true
    }

    /// 습관에 대한 모든 사전 알림 엔트리를 생성한다.
    static func notificationsForHabit(_ habit: Habit) -> [(identifier: String, weekday: Int, hour: Int, minute: Int)] {
        guard let habitId = habit.id,
              let targetTime = habit.targetTime,
              let time = preNotificationTime(targetTime: targetTime),
              habit.isNotificationEnabled,
              !habit.isArchived else {
            return []
        }

        return habit.schedule.compactMap { weekday in
            (identifier: preNotificationIdentifier(habitId: habitId, weekday: weekday),
             weekday: weekday,
             hour: time.hour,
             minute: time.minute)
        }
    }

    // MARK: - M9b: 미완료 리마인드

    /// 미완료 알림 식별자: "{habitId}-overdue-{weekday}"
    static func overdueNotificationIdentifier(habitId: String, weekday: Int) -> String {
        "\(habitId)-overdue-\(weekday)"
    }

    /// 종합 알림 식별자
    static func summaryNotificationIdentifier() -> String {
        "daily-summary"
    }

    /// targetTime + delayMinutes 후의 시각을 계산한다.
    static func overdueNotificationTime(targetTime: String, delayMinutes: Int) -> (hour: Int, minute: Int)? {
        guard let time = parseTime(targetTime),
              delayMinutes >= 0 else { return nil }

        let totalMinutes = time.hour * 60 + time.minute + delayMinutes
        let newHour = (totalMinutes / 60) % 24
        let newMinute = totalMinutes % 60

        return (hour: newHour, minute: newMinute)
    }

    /// 습관에 대한 모든 미완료 알림 엔트리를 생성한다.
    static func overdueNotificationsForHabit(_ habit: Habit, delayMinutes: Int) -> [(identifier: String, weekday: Int, hour: Int, minute: Int)] {
        guard let habitId = habit.id,
              let targetTime = habit.targetTime,
              let time = overdueNotificationTime(targetTime: targetTime, delayMinutes: delayMinutes),
              habit.isNotificationEnabled,
              !habit.isArchived else {
            return []
        }

        return habit.schedule.compactMap { weekday in
            (identifier: overdueNotificationIdentifier(habitId: habitId, weekday: weekday),
             weekday: weekday,
             hour: time.hour,
             minute: time.minute)
        }
    }

    /// 종합 알림 메시지를 생성한다. "오늘 아직 N개 습관을 완료하지 않았습니다 (독서, 러닝, 영어)"
    static func summaryMessage(habitNames: [String]) -> String {
        guard !habitNames.isEmpty else { return "" }
        let joined = habitNames.joined(separator: ", ")
        return "오늘 아직 \(habitNames.count)개 습관을 완료하지 않았습니다 (\(joined))"
    }
}
