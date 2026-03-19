import Foundation

struct WidgetHabitData: Codable, Equatable, Sendable {
    let totalCount: Int
    let completedCount: Int
    let habits: [WidgetHabitItem]
    let heatmapEntries: [WidgetHeatmapDay]
    let updatedAt: Date
}

struct WidgetHabitItem: Codable, Equatable, Sendable {
    let name: String
    let icon: String
    let color: String
    let isCompleted: Bool
}

struct WidgetHeatmapDay: Codable, Equatable, Sendable {
    let date: String      // "yyyy-MM-dd"
    let count: Int
    let intensity: Int    // 0-4
}
