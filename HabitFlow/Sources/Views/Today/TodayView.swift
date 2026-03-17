import SwiftUI

struct TodayView: View {
    @State var viewModel: TodayViewModel
    @State private var memoTarget: TodayHabitItem?
    @State private var memoText = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.todayHabits.isEmpty {
                    emptyState
                } else {
                    todayList
                }
            }
            .navigationTitle("오늘")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Text("\(viewModel.completedCount)/\(viewModel.todayHabits.count)")
                        .font(.headline)
                        .foregroundStyle(viewModel.completionRate == 1.0 ? .green : .secondary)
                }
            }
            .task {
                await viewModel.loadToday()
            }
            .alert("메모", isPresented: Binding(
                get: { memoTarget != nil },
                set: { if !$0 { memoTarget = nil; memoText = "" } }
            )) {
                TextField("메모 입력", text: $memoText)
                Button("저장") {
                    if let target = memoTarget {
                        Task { await viewModel.addMemo(memoText, to: target) }
                    }
                    memoTarget = nil
                    memoText = ""
                }
                Button("취소", role: .cancel) {
                    memoTarget = nil
                    memoText = ""
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "오늘은 쉬는 날",
            systemImage: "moon.zzz",
            description: Text("오늘 예정된 습관이 없습니다")
        )
    }

    private var todayList: some View {
        List {
            ForEach(viewModel.todayHabits) { item in
                TodayHabitRow(item: item) {
                    Task { await viewModel.toggleCheck(item) }
                } onLongPress: {
                    memoTarget = item
                    memoText = item.memo ?? ""
                }
            }
        }
    }
}

struct TodayHabitRow: View {
    let item: TodayHabitItem
    let onToggle: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isCompleted ? Color(hex: item.habit.color) : .gray)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.habit.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(item.isCompleted, color: .secondary)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)

                HStack(spacing: 4) {
                    if let time = item.habit.targetTime {
                        Text(time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let memo = item.memo, !memo.isEmpty {
                        Text("· \(memo)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Image(systemName: item.habit.icon)
                .foregroundStyle(Color(hex: item.habit.color).opacity(item.isCompleted ? 0.4 : 1.0))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onLongPressGesture { onLongPress() }
    }
}
