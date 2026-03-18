import Testing
@testable import HabitFlow

// MARK: - Test Helpers

private func makeHabit(
    id: String? = "test-habit-1",
    name: String = "테스트 습관",
    schedule: [Int] = [2, 3, 4, 5, 6],
    targetTime: String? = "09:00",
    isArchived: Bool = false,
    isNotificationEnabled: Bool = true
) -> Habit {
    Habit(
        id: id,
        name: name,
        schedule: schedule,
        targetTime: targetTime,
        isArchived: isArchived,
        isNotificationEnabled: isNotificationEnabled
    )
}

// MARK: - NotificationScheduler Tests

@Suite("NotificationScheduler Tests")
struct NotificationSchedulerTests {

    // MARK: - preNotificationTime

    @Test("유효한 시각의 10분 전을 반환한다")
    func preNotificationTime_validTime_returns10MinBefore() {
        let result = NotificationScheduler.preNotificationTime(targetTime: "09:00")
        #expect(result != nil)
        #expect(result?.hour == 8)
        #expect(result?.minute == 50)
    }

    @Test("자정 근처 시각은 전날로 래핑된다")
    func preNotificationTime_earlyMorning_returns10MinBefore() {
        let result = NotificationScheduler.preNotificationTime(targetTime: "00:05")
        #expect(result != nil)
        #expect(result?.hour == 23)
        #expect(result?.minute == 55)
    }

    @Test("잘못된 형식은 nil을 반환한다")
    func preNotificationTime_invalidFormat_returnsNil() {
        let result = NotificationScheduler.preNotificationTime(targetTime: "invalid")
        #expect(result == nil)
    }

    @Test("00:10의 10분 전은 00:00이다")
    func preNotificationTime_midnight_wrapsCorrectly() {
        let result = NotificationScheduler.preNotificationTime(targetTime: "00:10")
        #expect(result != nil)
        #expect(result?.hour == 0)
        #expect(result?.minute == 0)
    }

    // MARK: - preNotificationIdentifier

    @Test("식별자 형식이 '{habitId}-pre-{weekday}'이다")
    func preNotificationIdentifier_format() {
        let identifier = NotificationScheduler.preNotificationIdentifier(habitId: "abc", weekday: 2)
        #expect(identifier == "abc-pre-2")
    }

    // MARK: - shouldScheduleNotification

    @Test("targetTime + 알림 활성화 시 true를 반환한다")
    func shouldSchedule_enabledWithTargetTime_returnsTrue() {
        let habit = makeHabit(schedule: [2, 3, 4, 5, 6], targetTime: "09:00", isNotificationEnabled: true)
        #expect(NotificationScheduler.shouldScheduleNotification(for: habit, weekday: 2) == true)
    }

    @Test("알림 비활성화 시 false를 반환한다")
    func shouldSchedule_disabledNotification_returnsFalse() {
        let habit = makeHabit(targetTime: "09:00", isNotificationEnabled: false)
        #expect(NotificationScheduler.shouldScheduleNotification(for: habit, weekday: 2) == false)
    }

    @Test("targetTime이 nil이면 false를 반환한다")
    func shouldSchedule_noTargetTime_returnsFalse() {
        let habit = makeHabit(targetTime: nil)
        #expect(NotificationScheduler.shouldScheduleNotification(for: habit, weekday: 2) == false)
    }

    @Test("아카이브된 습관은 false를 반환한다")
    func shouldSchedule_archivedHabit_returnsFalse() {
        let habit = makeHabit(isArchived: true)
        #expect(NotificationScheduler.shouldScheduleNotification(for: habit, weekday: 2) == false)
    }

    @Test("스케줄에 없는 요일은 false를 반환한다")
    func shouldSchedule_wrongWeekday_returnsFalse() {
        let habit = makeHabit(schedule: [2, 3, 4, 5, 6]) // 월~금
        #expect(NotificationScheduler.shouldScheduleNotification(for: habit, weekday: 1) == false) // 일요일
    }

    @Test("스케줄에 있는 요일은 true를 반환한다")
    func shouldSchedule_correctWeekday_returnsTrue() {
        let habit = makeHabit(schedule: [2, 3, 4, 5, 6]) // 월~금
        #expect(NotificationScheduler.shouldScheduleNotification(for: habit, weekday: 3) == true) // 화요일
    }

    // MARK: - notificationsForHabit

    @Test("매일 습관은 7개 알림 엔트리를 반환한다")
    func notificationsForHabit_dailyHabit_returns7() {
        let habit = makeHabit(schedule: [1, 2, 3, 4, 5, 6, 7], targetTime: "09:00")
        let entries = NotificationScheduler.notificationsForHabit(habit)
        #expect(entries.count == 7)
    }

    @Test("평일 습관은 5개 알림 엔트리를 반환한다")
    func notificationsForHabit_weekdaysOnly_returns5() {
        let habit = makeHabit(schedule: [2, 3, 4, 5, 6], targetTime: "09:00")
        let entries = NotificationScheduler.notificationsForHabit(habit)
        #expect(entries.count == 5)
    }

    @Test("targetTime이 nil이면 빈 배열을 반환한다")
    func notificationsForHabit_noTargetTime_returnsEmpty() {
        let habit = makeHabit(targetTime: nil)
        let entries = NotificationScheduler.notificationsForHabit(habit)
        #expect(entries.isEmpty)
    }

    @Test("알림 비활성화 시 빈 배열을 반환한다")
    func notificationsForHabit_disabled_returnsEmpty() {
        let habit = makeHabit(targetTime: "09:00", isNotificationEnabled: false)
        let entries = NotificationScheduler.notificationsForHabit(habit)
        #expect(entries.isEmpty)
    }

    @Test("id가 nil인 습관은 빈 배열을 반환한다")
    func notificationsForHabit_nilId_returnsEmpty() {
        let habit = makeHabit(id: nil, targetTime: "09:00")
        let entries = NotificationScheduler.notificationsForHabit(habit)
        #expect(entries.isEmpty)
    }

    @Test("범위 밖 시각은 nil을 반환한다")
    func preNotificationTime_outOfRange_returnsNil() {
        #expect(NotificationScheduler.preNotificationTime(targetTime: "25:00") == nil)
        #expect(NotificationScheduler.preNotificationTime(targetTime: "12:60") == nil)
        #expect(NotificationScheduler.preNotificationTime(targetTime: "") == nil)
    }
}

// MARK: - MockNotificationService Tests

@Suite("MockNotificationService Tests")
struct MockNotificationServiceTests {

    @Test("스케줄링 시 식별자가 추가된다")
    func schedulePreNotification_addsToScheduled() async throws {
        let service = MockNotificationService()
        let habit = makeHabit(id: "h1", schedule: [2])
        try await service.schedulePreNotification(for: habit, weekday: 2)
        #expect(service.scheduledIdentifiers.contains("h1-pre-2"))
    }

    @Test("취소 시 해당 습관의 알림이 모두 제거된다")
    func cancelNotifications_removesFromScheduled() async throws {
        let service = MockNotificationService()
        let habit = makeHabit(id: "h1", schedule: [2, 3])
        try await service.schedulePreNotification(for: habit, weekday: 2)
        try await service.schedulePreNotification(for: habit, weekday: 3)
        try await service.cancelNotifications(for: "h1")
        let count = await service.pendingNotificationCount()
        #expect(count == 0)
    }

    @Test("전체 취소 시 모든 알림이 제거된다")
    func cancelAllNotifications_clearsAll() async throws {
        let service = MockNotificationService()
        let habit1 = makeHabit(id: "h1", schedule: [2])
        let habit2 = makeHabit(id: "h2", schedule: [3])
        try await service.schedulePreNotification(for: habit1, weekday: 2)
        try await service.schedulePreNotification(for: habit2, weekday: 3)
        try await service.cancelAllNotifications()
        let count = await service.pendingNotificationCount()
        #expect(count == 0)
    }

    @Test("대기 중 알림 수가 정확하다")
    func pendingNotificationCount_returnsCorrect() async throws {
        let service = MockNotificationService()
        let habit = makeHabit(id: "h1", schedule: [2, 3, 4])
        try await service.schedulePreNotification(for: habit, weekday: 2)
        try await service.schedulePreNotification(for: habit, weekday: 3)
        try await service.schedulePreNotification(for: habit, weekday: 4)
        let count = await service.pendingNotificationCount()
        #expect(count == 3)
    }

    @Test("rescheduleAll은 기존 알림을 교체한다")
    func rescheduleAll_replacesExisting() async throws {
        let service = MockNotificationService()
        // 먼저 하나 등록
        let oldHabit = makeHabit(id: "old", schedule: [2])
        try await service.schedulePreNotification(for: oldHabit, weekday: 2)
        #expect(service.scheduledIdentifiers.contains("old-pre-2"))

        // rescheduleAll로 새 습관들로 교체
        let newHabit = makeHabit(id: "new", schedule: [1, 2, 3, 4, 5, 6, 7], targetTime: "08:00")
        try await service.rescheduleAll(habits: [newHabit])

        #expect(!service.scheduledIdentifiers.contains("old-pre-2"))
        let count = await service.pendingNotificationCount()
        #expect(count == 7)
    }
}

// MARK: - M9b: 미완료 리마인드 Tests

@Suite("M9b: 미완료 리마인드 Tests")
struct OverdueReminderTests {

    // MARK: - overdueNotificationIdentifier

    @Test("미완료 식별자 형식이 '{habitId}-overdue-{weekday}'이다")
    func overdueNotificationIdentifier_format() {
        let identifier = NotificationScheduler.overdueNotificationIdentifier(habitId: "abc", weekday: 2)
        #expect(identifier == "abc-overdue-2")
    }

    // MARK: - summaryNotificationIdentifier

    @Test("종합 알림 식별자는 'daily-summary'이다")
    func summaryNotificationIdentifier_format() {
        let identifier = NotificationScheduler.summaryNotificationIdentifier()
        #expect(identifier == "daily-summary")
    }

    // MARK: - overdueNotificationTime

    @Test("60분 지연 시 1시간 후를 반환한다")
    func overdueNotificationTime_60minDelay_addsHour() {
        let result = NotificationScheduler.overdueNotificationTime(targetTime: "09:00", delayMinutes: 60)
        #expect(result != nil)
        #expect(result?.hour == 10)
        #expect(result?.minute == 0)
    }

    @Test("30분 지연 시 30분 후를 반환한다")
    func overdueNotificationTime_30minDelay_adds30min() {
        let result = NotificationScheduler.overdueNotificationTime(targetTime: "09:00", delayMinutes: 30)
        #expect(result != nil)
        #expect(result?.hour == 9)
        #expect(result?.minute == 30)
    }

    @Test("자정을 넘어가는 경우 래핑된다")
    func overdueNotificationTime_crossMidnight() {
        let result = NotificationScheduler.overdueNotificationTime(targetTime: "23:30", delayMinutes: 60)
        #expect(result != nil)
        #expect(result?.hour == 0)
        #expect(result?.minute == 30)
    }

    @Test("잘못된 시각 형식은 nil을 반환한다")
    func overdueNotificationTime_invalidTime_returnsNil() {
        let result = NotificationScheduler.overdueNotificationTime(targetTime: "invalid", delayMinutes: 60)
        #expect(result == nil)
    }

    // MARK: - overdueNotificationsForHabit

    @Test("평일 습관은 5개 미완료 알림 엔트리를 반환한다")
    func overdueNotificationsForHabit_weekdays_returns5() {
        let habit = makeHabit(schedule: [2, 3, 4, 5, 6], targetTime: "09:00")
        let entries = NotificationScheduler.overdueNotificationsForHabit(habit, delayMinutes: 60)
        #expect(entries.count == 5)
    }

    @Test("targetTime이 nil이면 빈 배열을 반환한다")
    func overdueNotificationsForHabit_noTargetTime_returnsEmpty() {
        let habit = makeHabit(targetTime: nil)
        let entries = NotificationScheduler.overdueNotificationsForHabit(habit, delayMinutes: 60)
        #expect(entries.isEmpty)
    }

    @Test("알림 비활성화 시 빈 배열을 반환한다")
    func overdueNotificationsForHabit_disabled_returnsEmpty() {
        let habit = makeHabit(targetTime: "09:00", isNotificationEnabled: false)
        let entries = NotificationScheduler.overdueNotificationsForHabit(habit, delayMinutes: 60)
        #expect(entries.isEmpty)
    }

    @Test("09:00 + 60분 지연 시 각 엔트리의 시각이 10:00이다")
    func overdueNotificationsForHabit_correctTime() {
        let habit = makeHabit(schedule: [2, 3, 4, 5, 6], targetTime: "09:00")
        let entries = NotificationScheduler.overdueNotificationsForHabit(habit, delayMinutes: 60)
        for entry in entries {
            #expect(entry.hour == 10)
            #expect(entry.minute == 0)
        }
    }

    // MARK: - summaryMessage

    @Test("여러 습관의 종합 메시지를 생성한다")
    func summaryMessage_multipleHabits() {
        let message = NotificationScheduler.summaryMessage(habitNames: ["독서", "러닝", "영어"])
        #expect(message == "오늘 아직 3개 습관을 완료하지 않았습니다 (독서, 러닝, 영어)")
    }

    @Test("단일 습관의 종합 메시지를 생성한다")
    func summaryMessage_singleHabit() {
        let message = NotificationScheduler.summaryMessage(habitNames: ["독서"])
        #expect(message == "오늘 아직 1개 습관을 완료하지 않았습니다 (독서)")
    }

    @Test("빈 배열은 빈 문자열을 반환한다")
    func summaryMessage_empty() {
        let message = NotificationScheduler.summaryMessage(habitNames: [])
        #expect(message == "")
    }

    // MARK: - 추가 엣지케이스

    @Test("0분 지연 시 원래 시각을 반환한다")
    func overdueNotificationTime_zeroDelay_returnsSameTime() {
        let result = NotificationScheduler.overdueNotificationTime(targetTime: "09:00", delayMinutes: 0)
        #expect(result?.hour == 9)
        #expect(result?.minute == 0)
    }

    @Test("음수 지연은 nil을 반환한다")
    func overdueNotificationTime_negativeDelay_returnsNil() {
        let result = NotificationScheduler.overdueNotificationTime(targetTime: "09:00", delayMinutes: -10)
        #expect(result == nil)
    }

    @Test("id가 nil인 습관은 미완료 알림을 생성하지 않는다")
    func overdueNotificationsForHabit_nilId_returnsEmpty() {
        let habit = makeHabit(id: nil, targetTime: "09:00")
        let entries = NotificationScheduler.overdueNotificationsForHabit(habit, delayMinutes: 60)
        #expect(entries.isEmpty)
    }

    @Test("아카이브된 습관은 미완료 알림을 생성하지 않는다")
    func overdueNotificationsForHabit_archived_returnsEmpty() {
        let habit = makeHabit(targetTime: "09:00", isArchived: true)
        let entries = NotificationScheduler.overdueNotificationsForHabit(habit, delayMinutes: 60)
        #expect(entries.isEmpty)
    }

    // MARK: - MockNotificationService overdue tests

    @Test("미완료 알림 스케줄링 시 식별자가 추가된다")
    func scheduleOverdueNotification_addsIdentifier() async throws {
        let service = MockNotificationService()
        let habit = makeHabit(id: "h1", schedule: [2])
        try await service.scheduleOverdueNotification(for: habit, weekday: 2, delayMinutes: 60)
        #expect(service.scheduledIdentifiers.contains("h1-overdue-2"))
    }

    @Test("미완료 알림 취소 시 사전 알림은 유지된다")
    func cancelOverdueNotifications_removesOnlyOverdue() async throws {
        let service = MockNotificationService()
        let habit = makeHabit(id: "h1", schedule: [2])

        // pre 알림과 overdue 알림 모두 등록
        try await service.schedulePreNotification(for: habit, weekday: 2)
        try await service.scheduleOverdueNotification(for: habit, weekday: 2, delayMinutes: 60)
        #expect(service.scheduledIdentifiers.contains("h1-pre-2"))
        #expect(service.scheduledIdentifiers.contains("h1-overdue-2"))

        // overdue만 취소
        try await service.cancelOverdueNotifications(for: "h1")
        #expect(service.scheduledIdentifiers.contains("h1-pre-2"))
        #expect(!service.scheduledIdentifiers.contains("h1-overdue-2"))
    }
}
