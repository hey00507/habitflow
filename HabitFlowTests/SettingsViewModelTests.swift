import Foundation
import Testing
@testable import HabitFlow

@Suite("SettingsViewModel Tests")
struct SettingsViewModelTests {

    // Helper: create a fresh UserDefaults for each test (in-memory)
    private func makeDefaults() -> UserDefaults {
        let suiteName = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return defaults
    }

    // Helper: create ViewModel with test dependencies
    @MainActor
    private func makeViewModel(defaults: UserDefaults? = nil) -> SettingsViewModel {
        let d = defaults ?? makeDefaults()
        return SettingsViewModel(
            defaults: d,
            notificationService: MockNotificationService(),
            habitService: MockHabitService()
        )
    }

    // MARK: - Default values

    @Test("초기 설정은 기본값이다")
    @MainActor
    func loadSettings_defaults() {
        let vm = makeViewModel()
        vm.loadSettings()
        #expect(vm.settings.masterEnabled == true)
        #expect(vm.settings.overdueDelay == 60)
        #expect(vm.settings.dailySummaryTime == "21:00")
    }

    // MARK: - Load from UserDefaults

    @Test("저장된 설정을 불러온다")
    @MainActor
    func loadSettings_fromDefaults() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: NotificationSettings.masterEnabledKey)
        defaults.set(30, forKey: NotificationSettings.overdueDelayKey)
        defaults.set("22:00", forKey: NotificationSettings.dailySummaryTimeKey)

        let vm = makeViewModel(defaults: defaults)
        vm.loadSettings()
        #expect(vm.settings.masterEnabled == false)
        #expect(vm.settings.overdueDelay == 30)
        #expect(vm.settings.dailySummaryTime == "22:00")
    }

    // MARK: - Save masterEnabled

    @Test("마스터 스위치 변경 시 UserDefaults에 저장된다")
    @MainActor
    func saveMasterEnabled_updatesDefaults() async {
        let defaults = makeDefaults()
        let vm = makeViewModel(defaults: defaults)
        vm.loadSettings()

        await vm.saveMasterEnabled(false)
        #expect(defaults.bool(forKey: NotificationSettings.masterEnabledKey) == false)
        #expect(vm.settings.masterEnabled == false)
    }

    // MARK: - Save overdueDelay

    @Test("미완료 지연 시간 변경 시 UserDefaults에 저장된다")
    @MainActor
    func saveOverdueDelay_updatesDefaults() async {
        let defaults = makeDefaults()
        let vm = makeViewModel(defaults: defaults)
        vm.loadSettings()

        await vm.saveOverdueDelay(120)
        #expect(defaults.integer(forKey: NotificationSettings.overdueDelayKey) == 120)
        #expect(vm.settings.overdueDelay == 120)
    }

    // MARK: - Save dailySummaryTime

    @Test("종합 알림 시간 변경 시 UserDefaults에 저장된다")
    @MainActor
    func saveDailySummaryTime_updatesDefaults() async {
        let defaults = makeDefaults()
        let vm = makeViewModel(defaults: defaults)
        vm.loadSettings()

        await vm.saveDailySummaryTime("20:00")
        #expect(defaults.string(forKey: NotificationSettings.dailySummaryTimeKey) == "20:00")
        #expect(vm.settings.dailySummaryTime == "20:00")
    }

    // MARK: - Reschedule trigger

    @Test("마스터 비활성화 시 모든 알림이 취소된다")
    @MainActor
    func saveMasterEnabled_false_cancelsAll() async {
        let notifService = MockNotificationService()
        let defaults = makeDefaults()
        let vm = SettingsViewModel(
            defaults: defaults,
            notificationService: notifService,
            habitService: MockHabitService()
        )
        vm.loadSettings()

        // 먼저 알림 하나 등록
        let habit = Habit(id: "h1", name: "test", targetTime: "09:00")
        try? await notifService.schedulePreNotification(for: habit, weekday: 2)
        let before = await notifService.pendingNotificationCount()
        #expect(before == 1)

        // 마스터 비활성화
        await vm.saveMasterEnabled(false)
        let after = await notifService.pendingNotificationCount()
        #expect(after == 0)
    }

    @Test("마스터 활성화 시 알림이 재스케줄링된다")
    @MainActor
    func saveMasterEnabled_true_reschedulesAll() async {
        let notifService = MockNotificationService()
        let habitService = MockHabitService()
        let defaults = makeDefaults()

        // 습관 하나 등록
        _ = try? await habitService.createHabit(
            Habit(name: "러닝", schedule: [1, 2, 3, 4, 5, 6, 7], targetTime: "07:00")
        )

        let vm = SettingsViewModel(
            defaults: defaults,
            notificationService: notifService,
            habitService: habitService
        )
        vm.loadSettings()

        // 마스터 활성화
        await vm.saveMasterEnabled(true)
        let count = await notifService.pendingNotificationCount()
        #expect(count > 0)
    }
}
