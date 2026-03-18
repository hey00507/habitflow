import Foundation

struct NotificationSettings: Equatable, Sendable {
    var masterEnabled: Bool
    var overdueDelay: Int        // minutes
    var dailySummaryTime: String // "HH:mm"

    static let `default` = NotificationSettings(
        masterEnabled: true,
        overdueDelay: 60,
        dailySummaryTime: "21:00"
    )

    // UserDefaults keys
    static let masterEnabledKey = "notification_master_enabled"
    static let overdueDelayKey = "notification_overdue_delay"
    static let dailySummaryTimeKey = "notification_daily_summary_time"
}
