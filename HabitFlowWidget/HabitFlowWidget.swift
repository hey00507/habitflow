import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct HabitFlowEntry: TimelineEntry {
    let date: Date
    let data: WidgetHabitData?
}

// MARK: - Timeline Provider

struct HabitFlowWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitFlowEntry {
        HabitFlowEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitFlowEntry) -> Void) {
        let data = WidgetDataStore.load()
        completion(HabitFlowEntry(date: .now, data: data ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitFlowEntry>) -> Void) {
        let data = WidgetDataStore.load()
        let entry = HabitFlowEntry(date: .now, data: data)
        // 15분마다 갱신
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Small Widget View (오늘 진행률)

struct TodayProgressView: View {
    let data: WidgetHabitData?

    private var completed: Int { data?.completedCount ?? 0 }
    private var total: Int { data?.totalCount ?? 0 }
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(completed)/\(total)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Text("완료")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)

            if let data, !data.habits.isEmpty {
                HStack(spacing: 2) {
                    ForEach(data.habits.prefix(5), id: \.name) { habit in
                        Image(systemName: habit.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(habit.isCompleted ? Color(hex: habit.color) : .gray)
                    }
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget View (미니 히트맵)

struct MiniHeatmapView: View {
    let data: WidgetHabitData?

    private var entries: [WidgetHeatmapDay] {
        let all = data?.heatmapEntries ?? []
        return Array(all.suffix(28)) // 최근 4주
    }

    var body: some View {
        HStack(spacing: 8) {
            // 왼쪽: 진행률
            VStack(alignment: .leading, spacing: 4) {
                Text("HabitFlow")
                    .font(.system(.caption, design: .rounded, weight: .semibold))

                Text("\(data?.completedCount ?? 0)/\(data?.totalCount ?? 0)")
                    .font(.system(.title2, design: .rounded, weight: .bold))

                Text("오늘")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 60)

            // 오른쪽: 잔디 히트맵
            heatmapGrid
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var heatmapGrid: some View {
        let rows = 7
        let columns = max(1, entries.count / rows + (entries.count % rows > 0 ? 1 : 0))

        return HStack(spacing: 2) {
            ForEach(0..<columns, id: \.self) { col in
                VStack(spacing: 2) {
                    ForEach(0..<rows, id: \.self) { row in
                        let index = col * rows + row
                        if index < entries.count {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(heatmapColor(intensity: entries[index].intensity))
                                .frame(width: 10, height: 10)
                        } else {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(Color.clear)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
            }
        }
    }

    private func heatmapColor(intensity: Int) -> Color {
        switch intensity {
        case 0: return Color.green.opacity(0.1)
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.5)
        case 3: return Color.green.opacity(0.7)
        default: return Color.green.opacity(0.9)
        }
    }
}

// MARK: - Widget Definitions

struct HabitFlowProgressWidget: Widget {
    let kind = "HabitFlowProgress"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitFlowWidgetProvider()) { entry in
            TodayProgressView(data: entry.data)
        }
        .configurationDisplayName("오늘의 습관")
        .description("오늘의 습관 진행률을 확인합니다")
        .supportedFamilies([.systemSmall])
    }
}

struct HabitFlowHeatmapWidget: Widget {
    let kind = "HabitFlowHeatmap"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitFlowWidgetProvider()) { entry in
            MiniHeatmapView(data: entry.data)
        }
        .configurationDisplayName("습관 잔디")
        .description("최근 4주간의 습관 기록을 잔디로 확인합니다")
        .supportedFamilies([.systemMedium])
    }
}

@main
struct HabitFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitFlowProgressWidget()
        HabitFlowHeatmapWidget()
    }
}

// MARK: - Placeholder Data

extension WidgetHabitData {
    static let placeholder = WidgetHabitData(
        totalCount: 5,
        completedCount: 3,
        habits: [
            WidgetHabitItem(name: "운동", icon: "figure.run", color: "#4CAF50", isCompleted: true),
            WidgetHabitItem(name: "독서", icon: "book.fill", color: "#2196F3", isCompleted: true),
            WidgetHabitItem(name: "명상", icon: "brain.head.profile", color: "#9C27B0", isCompleted: true),
            WidgetHabitItem(name: "물마시기", icon: "drop.fill", color: "#00BCD4", isCompleted: false),
            WidgetHabitItem(name: "일기", icon: "pencil.and.outline", color: "#FF9800", isCompleted: false)
        ],
        heatmapEntries: (0..<28).map { i in
            WidgetHeatmapDay(date: "", count: Int.random(in: 0...4), intensity: Int.random(in: 0...4))
        },
        updatedAt: .now
    )
}
