import Foundation

enum WidgetDataBuilder {
    static func buildWidgetData(
        habits: [WidgetHabitItem],
        heatmapEntries: [HeatmapEntry],
        now: Date = .now
    ) -> WidgetHabitData {
        let heatmapDays = heatmapEntries.map {
            WidgetHeatmapDay(date: $0.date, count: $0.count, intensity: $0.intensity)
        }
        return WidgetHabitData(
            totalCount: habits.count,
            completedCount: habits.filter(\.isCompleted).count,
            habits: habits,
            heatmapEntries: heatmapDays,
            updatedAt: now
        )
    }
}
