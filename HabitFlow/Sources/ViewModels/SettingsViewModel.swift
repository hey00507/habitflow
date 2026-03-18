import Foundation

@MainActor
@Observable
class SettingsViewModel {
    var settings: NotificationSettings = .default

    private let defaults: UserDefaults
    private let notificationService: NotificationServiceProtocol
    private let habitService: HabitServiceProtocol

    init(
        defaults: UserDefaults = .standard,
        notificationService: NotificationServiceProtocol,
        habitService: HabitServiceProtocol
    ) {
        self.defaults = defaults
        self.notificationService = notificationService
        self.habitService = habitService
    }

    func loadSettings() {
        let masterKey = NotificationSettings.masterEnabledKey
        let delayKey = NotificationSettings.overdueDelayKey
        let summaryKey = NotificationSettings.dailySummaryTimeKey

        settings.masterEnabled = defaults.object(forKey: masterKey) != nil
            ? defaults.bool(forKey: masterKey)
            : NotificationSettings.default.masterEnabled

        let delay = defaults.integer(forKey: delayKey)
        settings.overdueDelay = delay > 0 ? delay : NotificationSettings.default.overdueDelay

        settings.dailySummaryTime = defaults.string(forKey: summaryKey)
            ?? NotificationSettings.default.dailySummaryTime
    }

    func saveMasterEnabled(_ enabled: Bool) async {
        settings.masterEnabled = enabled
        defaults.set(enabled, forKey: NotificationSettings.masterEnabledKey)

        if enabled {
            await rescheduleAll()
        } else {
            try? await notificationService.cancelAllNotifications()
        }
    }

    func saveOverdueDelay(_ minutes: Int) async {
        settings.overdueDelay = minutes
        defaults.set(minutes, forKey: NotificationSettings.overdueDelayKey)
        await rescheduleAll()
    }

    func saveDailySummaryTime(_ time: String) async {
        settings.dailySummaryTime = time
        defaults.set(time, forKey: NotificationSettings.dailySummaryTimeKey)
        await rescheduleAll()
    }

    private func rescheduleAll() async {
        guard let habits = try? await habitService.fetchHabits() else { return }
        try? await notificationService.rescheduleAll(habits: habits)
    }
}
