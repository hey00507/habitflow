import Testing
@testable import HabitFlow

@Suite("HabitService Tests")
struct HabitServiceTests {
    let service = MockHabitService()

    // MARK: - Create

    @Test("습관 생성 시 ID가 할당된다")
    func test_createHabit_assignsId() async throws {
        let habit = Habit(name: "러닝", icon: "figure.run", color: "#4CAF50")
        let created = try await service.createHabit(habit)
        #expect(created.id != nil)
        #expect(created.name == "러닝")
    }

    @Test("습관 생성 후 목록에서 조회된다")
    func test_createHabit_appearsInFetch() async throws {
        let habit = Habit(name: "독서", icon: "book.fill", color: "#2196F3")
        _ = try await service.createHabit(habit)
        let habits = try await service.fetchHabits()
        #expect(habits.contains { $0.name == "독서" })
    }

    // MARK: - Fetch

    @Test("아카이브된 습관은 조회되지 않는다")
    func test_fetchHabits_excludesArchived() async throws {
        var habit = Habit(name: "명상", icon: "brain.head.profile", color: "#9C27B0")
        habit.isArchived = true
        _ = try await service.createHabit(habit)
        let habits = try await service.fetchHabits()
        #expect(!habits.contains { $0.name == "명상" })
    }

    // MARK: - Update

    @Test("습관 이름을 수정할 수 있다")
    func test_updateHabit_changesName() async throws {
        let created = try await service.createHabit(Habit(name: "운동"))
        var updated = created
        updated.name = "헬스"
        try await service.updateHabit(updated)
        let habits = try await service.fetchHabits()
        #expect(habits.first?.name == "헬스")
    }

    @Test("존재하지 않는 습관 수정 시 에러가 발생한다")
    func test_updateHabit_notFound_throws() async throws {
        let ghost = Habit(id: "nonexistent", name: "없는 습관")
        await #expect(throws: HabitServiceError.self) {
            try await service.updateHabit(ghost)
        }
    }

    // MARK: - Delete

    @Test("습관 삭제 시 목록에서 사라진다")
    func test_deleteHabit_removesFromList() async throws {
        let created = try await service.createHabit(Habit(name: "코딩"))
        try await service.deleteHabit(created.id!)
        let habits = try await service.fetchHabits()
        #expect(!habits.contains { $0.name == "코딩" })
    }

    @Test("습관 삭제 시 관련 로그도 함께 삭제된다")
    func test_deleteHabit_deletesLogs() async throws {
        let created = try await service.createHabit(Habit(name: "영어"))
        let log = HabitLog(date: "2026-03-17")
        try await service.createLog(log, habitId: created.id!)
        try await service.deleteHabit(created.id!)
        let logs = try await service.fetchLogs(habitId: created.id!, from: "2026-03-01", to: "2026-03-31")
        #expect(logs.isEmpty)
    }

    // MARK: - Logs

    @Test("로그 생성 시 completedAt이 설정된다")
    func test_createLog_setsCompletedAt() async throws {
        let created = try await service.createHabit(Habit(name: "물 마시기"))
        let log = HabitLog(date: "2026-03-17", completedAt: .now)
        try await service.createLog(log, habitId: created.id!)
        let logs = try await service.fetchLogs(habitId: created.id!, from: "2026-03-17", to: "2026-03-17")
        #expect(logs.first?.completedAt != nil)
    }

    @Test("같은 날짜에 로그를 다시 생성하면 덮어쓴다")
    func test_createLog_sameDateOverwrites() async throws {
        let created = try await service.createHabit(Habit(name: "스트레칭"))
        let log1 = HabitLog(date: "2026-03-17", memo: "아침")
        let log2 = HabitLog(date: "2026-03-17", memo: "저녁")
        try await service.createLog(log1, habitId: created.id!)
        try await service.createLog(log2, habitId: created.id!)
        let logs = try await service.fetchLogs(habitId: created.id!, from: "2026-03-17", to: "2026-03-17")
        #expect(logs.count == 1)
        #expect(logs.first?.memo == "저녁")
    }

    @Test("기간 내 로그만 조회된다")
    func test_fetchLogs_filtersDateRange() async throws {
        let created = try await service.createHabit(Habit(name: "일기"))
        try await service.createLog(HabitLog(date: "2026-03-15"), habitId: created.id!)
        try await service.createLog(HabitLog(date: "2026-03-17"), habitId: created.id!)
        try await service.createLog(HabitLog(date: "2026-03-20"), habitId: created.id!)
        let logs = try await service.fetchLogs(habitId: created.id!, from: "2026-03-16", to: "2026-03-18")
        #expect(logs.count == 1)
        #expect(logs.first?.date == "2026-03-17")
    }

    @Test("로그 삭제 시 해당 날짜 로그가 사라진다")
    func test_deleteLog_removesSpecificDate() async throws {
        let created = try await service.createHabit(Habit(name: "감사 일기"))
        try await service.createLog(HabitLog(date: "2026-03-17"), habitId: created.id!)
        try await service.createLog(HabitLog(date: "2026-03-18"), habitId: created.id!)
        try await service.deleteLog(habitId: created.id!, date: "2026-03-17")
        let logs = try await service.fetchLogs(habitId: created.id!, from: "2026-03-01", to: "2026-03-31")
        #expect(logs.count == 1)
        #expect(logs.first?.date == "2026-03-18")
    }
}
