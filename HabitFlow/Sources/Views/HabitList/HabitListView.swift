import SwiftUI

struct HabitListView: View {
    @State var viewModel: HabitListViewModel
    @State private var showingForm = false
    @State private var editingHabit: Habit?

    var body: some View {
        AdaptiveNavigation {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.habits.isEmpty {
                    emptyState
                } else {
                    habitList
                }
            }
            .navigationTitle("습관")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                HabitFormView { habit in
                    Task { await viewModel.createHabit(habit) }
                }
                .adaptiveSheet()
            }
            .sheet(item: $editingHabit) { habit in
                HabitFormView(habit: habit) { updated in
                    Task { await viewModel.updateHabit(updated) }
                }
                .adaptiveSheet()
            }
            .task {
                await viewModel.loadHabits()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "습관이 없습니다",
            systemImage: "leaf",
            description: Text("+ 버튼을 눌러 첫 습관을 추가해보세요")
        )
    }

    private var habitList: some View {
        List {
            ForEach(viewModel.habits) { habit in
                HabitRow(habit: habit)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingHabit = habit
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            if let id = habit.id {
                                Task { await viewModel.deleteHabit(id) }
                            }
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }

                        Button {
                            Task { await viewModel.archiveHabit(habit) }
                        } label: {
                            Label("보관", systemImage: "archivebox")
                        }
                        .tint(.orange)
                    }
            }
        }
    }
}

struct HabitRow: View {
    let habit: Habit

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: habit.icon)
                .font(.title2)
                .foregroundStyle(Color(hex: habit.color))
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Text(scheduleText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let time = habit.targetTime {
                        Text("· \(time)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var scheduleText: String {
        let dayNames = ["", "일", "월", "화", "수", "목", "금", "토"]
        let days = habit.schedule.sorted().compactMap { dayNames[safe: $0] }
        if days.count == 7 { return "매일" }
        if habit.schedule.sorted() == [2, 3, 4, 5, 6] { return "평일" }
        if habit.schedule.sorted() == [1, 7] { return "주말" }
        return days.joined(separator: " ")
    }
}

private extension Array where Element == String {
    subscript(safe index: Int) -> String? {
        indices.contains(index) ? self[index] : nil
    }
}
