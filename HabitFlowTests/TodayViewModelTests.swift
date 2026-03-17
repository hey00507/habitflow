import Foundation
import Testing
@testable import HabitFlow

@Suite("TodayViewModel Tests")
@MainActor
struct TodayViewModelTests {
    let service = MockHabitService()

    private func makeViewModel() -> TodayViewModel {
        TodayViewModel(service: service)
    }

    // MARK: - 요일 필터링

    @Test("오늘 요일에 해당하는 습관만 표시된다")
    func test_todayHabits_filtersCorrectWeekday() async {
        let todayWeekday = Calendar.current.component(.weekday, from: .now) // 1=일 ~ 7=토
        _ = try? await service.createHabit(Habit(name: "매칭됨", schedule: [todayWeekday]))
        _ = try? await service.createHabit(Habit(name: "안매칭", schedule: [(todayWeekday % 7) + 1]))

        let vm = makeViewModel()
        await vm.loadToday()
        #expect(vm.todayHabits.count == 1)
        #expect(vm.todayHabits.first?.habit.name == "매칭됨")
    }

    // MARK: - 시간순 정렬

    @Test("습관이 targetTime 기준으로 정렬된다")
    func test_todayHabits_sortsByTargetTime() async {
        let todayWeekday = Calendar.current.component(.weekday, from: .now)
        _ = try? await service.createHabit(Habit(name: "저녁", schedule: [todayWeekday], targetTime: "20:00"))
        _ = try? await service.createHabit(Habit(name: "아침", schedule: [todayWeekday], targetTime: "07:00"))
        _ = try? await service.createHabit(Habit(name: "시간없음", schedule: [todayWeekday], targetTime: nil))

        let vm = makeViewModel()
        await vm.loadToday()
        #expect(vm.todayHabits[0].habit.name == "아침")
        #expect(vm.todayHabits[1].habit.name == "저녁")
        #expect(vm.todayHabits[2].habit.name == "시간없음")
    }

    // MARK: - 체크 토글

    @Test("체크하면 로그가 생성된다")
    func test_toggleCheck_createsLog() async {
        let todayWeekday = Calendar.current.component(.weekday, from: .now)
        _ = try? await service.createHabit(Habit(name: "러닝", schedule: [todayWeekday]))

        let vm = makeViewModel()
        await vm.loadToday()
        await vm.toggleCheck(vm.todayHabits[0])
        #expect(vm.todayHabits[0].isCompleted)
    }

    @Test("이미 체크된 습관을 토글하면 체크가 해제된다")
    func test_toggleCheck_existingLog_deletesLog() async {
        let todayWeekday = Calendar.current.component(.weekday, from: .now)
        _ = try? await service.createHabit(Habit(name: "독서", schedule: [todayWeekday]))

        let vm = makeViewModel()
        await vm.loadToday()
        await vm.toggleCheck(vm.todayHabits[0]) // 체크
        #expect(vm.todayHabits[0].isCompleted)
        await vm.toggleCheck(vm.todayHabits[0]) // 체크 해제
        #expect(!vm.todayHabits[0].isCompleted)
    }

    // MARK: - 완료율

    @Test("완료율이 정확하게 계산된다")
    func test_completionRate_calculatesCorrectly() async {
        let todayWeekday = Calendar.current.component(.weekday, from: .now)
        _ = try? await service.createHabit(Habit(name: "A", schedule: [todayWeekday]))
        _ = try? await service.createHabit(Habit(name: "B", schedule: [todayWeekday]))

        let vm = makeViewModel()
        await vm.loadToday()
        #expect(vm.completionRate == 0.0)

        await vm.toggleCheck(vm.todayHabits[0])
        #expect(vm.completionRate == 0.5)
    }
}
