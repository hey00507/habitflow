import SwiftUI

struct HeatmapView: View {
    @State private var viewModel: HeatmapViewModel

    private static let greenColor = Color(hex: "#4CAF50")
    private static let cellSize: CGFloat = 12
    private static let cellSpacing: CGFloat = 2

    init(service: HabitServiceProtocol) {
        _viewModel = State(initialValue: HeatmapViewModel(service: service))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    habitPicker
                    heatmapGrid
                    summaryStats
                }
                .padding()
            }
            .navigationTitle("잔디")
            .task {
                await viewModel.loadHeatmap()
            }
        }
    }

    // MARK: - Habit Picker

    private var habitPicker: some View {
        Picker("습관 필터", selection: $viewModel.selectedHabitId) {
            Text("전체").tag(nil as String?)
            ForEach(viewModel.habits) { habit in
                Text(habit.name).tag(habit.id as String?)
            }
        }
        .pickerStyle(.menu)
        .onChange(of: viewModel.selectedHabitId) {
            Task { await viewModel.loadHeatmap() }
        }
    }

    // MARK: - Heatmap Grid

    private var heatmapGrid: some View {
        let weeks = groupedByWeek(viewModel.entries)

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                weekdayLabels

                VStack(alignment: .leading, spacing: 0) {
                    monthLabels(weeks: weeks)

                    HStack(spacing: Self.cellSpacing) {
                        ForEach(0..<weeks.count, id: \.self) { weekIndex in
                            VStack(spacing: Self.cellSpacing) {
                                ForEach(0..<7, id: \.self) { dayIndex in
                                    if dayIndex < weeks[weekIndex].count {
                                        cellView(for: weeks[weekIndex][dayIndex])
                                    } else {
                                        Color.clear
                                            .frame(width: Self.cellSize, height: Self.cellSize)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var weekdayLabels: some View {
        let labels: [(index: Int, label: String)] = [
            (0, "일"), (2, "화"), (4, "목")
        ]

        return VStack(spacing: 0) {
            Text("")
                .font(.caption2)
                .frame(height: 16)

            ForEach(0..<7, id: \.self) { dayIndex in
                if let match = labels.first(where: { $0.index == dayIndex }) {
                    Text(match.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: Self.cellSize + Self.cellSpacing, alignment: .trailing)
                } else {
                    Color.clear
                        .frame(width: 20, height: Self.cellSize + Self.cellSpacing)
                }
            }
        }
        .padding(.trailing, 4)
    }

    private func monthLabels(weeks: [[HeatmapEntry]]) -> some View {
        HStack(spacing: Self.cellSpacing) {
            ForEach(0..<weeks.count, id: \.self) { weekIndex in
                let label = monthLabel(for: weeks[weekIndex])
                Text(label ?? "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: Self.cellSize, height: 16, alignment: .leading)
            }
        }
    }

    private func cellView(for entry: HeatmapEntry) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(colorForIntensity(entry.intensity))
            .frame(width: Self.cellSize, height: Self.cellSize)
    }

    // MARK: - Summary Stats

    private var summaryStats: some View {
        let today = DateFormat.string(from: .now)
        let todayCount = viewModel.entries.first(where: { $0.date == today })?.count ?? 0
        let totalCount = viewModel.entries.reduce(0) { $0 + $1.count }

        return HStack {
            Label("오늘: \(todayCount)개 완료", systemImage: "checkmark.circle")
            Spacer()
            Label("총 완료: \(totalCount)개", systemImage: "flame")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    // MARK: - Helpers

    private func colorForIntensity(_ intensity: Int) -> Color {
        switch intensity {
        case 0: return .secondary.opacity(0.15)
        case 1: return Self.greenColor.opacity(0.3)
        case 2: return Self.greenColor.opacity(0.5)
        case 3: return Self.greenColor.opacity(0.75)
        default: return Self.greenColor.opacity(1.0)
        }
    }

    private func groupedByWeek(_ entries: [HeatmapEntry]) -> [[HeatmapEntry]] {
        guard !entries.isEmpty else { return [] }
        return stride(from: 0, to: entries.count, by: 7).map { start in
            Array(entries[start..<min(start + 7, entries.count)])
        }
    }

    private func monthLabel(for week: [HeatmapEntry]) -> String? {
        guard let first = week.first else { return nil }
        let day = String(first.date.suffix(2))
        guard let dayNum = Int(day), dayNum <= 7 else { return nil }
        let monthStr = String(first.date.dropFirst(5).prefix(2))
        guard let month = Int(monthStr) else { return nil }
        return "\(month)월"
    }
}

#Preview {
    HeatmapView(service: MockHabitService())
}
