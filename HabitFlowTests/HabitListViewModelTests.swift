import Testing
@testable import HabitFlow

@Suite("HabitListViewModel Tests")
@MainActor
struct HabitListViewModelTests {
    let service = MockHabitService()

    private func makeViewModel() -> HabitListViewModel {
        HabitListViewModel(service: service)
    }

    // MARK: - Load

    @Test("습관 목록을 로드한다")
    func test_loadHabits_fetchesFromService() async {
        _ = try? await service.createHabit(Habit(name: "러닝"))
        _ = try? await service.createHabit(Habit(name: "독서"))
        let vm = makeViewModel()
        await vm.loadHabits()
        #expect(vm.habits.count == 2)
        #expect(!vm.isLoading)
    }

    @Test("로딩 중 isLoading이 true가 된다")
    func test_loadHabits_setsIsLoading() async {
        let vm = makeViewModel()
        #expect(vm.isLoading == false)
        await vm.loadHabits()
        #expect(vm.isLoading == false) // 완료 후 false
    }

    // MARK: - Create

    @Test("습관을 생성하면 목록에 추가된다")
    func test_createHabit_addsToList() async {
        let vm = makeViewModel()
        await vm.createHabit(Habit(name: "명상"))
        #expect(vm.habits.count == 1)
        #expect(vm.habits.first?.name == "명상")
    }

    @Test("생성된 습관에 ID가 할당된다")
    func test_createHabit_assignsId() async {
        let vm = makeViewModel()
        await vm.createHabit(Habit(name: "코딩"))
        #expect(vm.habits.first?.id != nil)
    }

    // MARK: - Update

    @Test("습관 이름을 수정하면 목록에 반영된다")
    func test_updateHabit_reflectsInList() async {
        let vm = makeViewModel()
        await vm.createHabit(Habit(name: "운동"))
        var habit = vm.habits.first!
        habit.name = "헬스"
        await vm.updateHabit(habit)
        #expect(vm.habits.first?.name == "헬스")
    }

    // MARK: - Delete

    @Test("습관을 삭제하면 목록에서 사라진다")
    func test_deleteHabit_removesFromList() async {
        let vm = makeViewModel()
        await vm.createHabit(Habit(name: "영어"))
        let id = vm.habits.first!.id!
        await vm.deleteHabit(id)
        #expect(vm.habits.isEmpty)
    }

    // MARK: - Archive

    @Test("습관을 아카이브하면 목록에서 사라진다")
    func test_archiveHabit_removesFromList() async {
        let vm = makeViewModel()
        await vm.createHabit(Habit(name: "스트레칭"))
        let habit = vm.habits.first!
        await vm.archiveHabit(habit)
        #expect(vm.habits.isEmpty)
    }
}
