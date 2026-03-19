import Foundation
import Testing
@testable import HabitFlow

@Suite("WidgetDataStore")
struct WidgetDataStoreTests {

    // MARK: - Save & Load

    @Test("저장 후 로드하면 동일한 데이터를 반환한다")
    func saveAndLoad() {
        let defaults = UserDefaults(suiteName: "test.widget.\(UUID().uuidString)")!
        let data = WidgetHabitData(
            totalCount: 3,
            completedCount: 2,
            habits: [
                WidgetHabitItem(name: "운동", icon: "figure.run", color: "#4CAF50", isCompleted: true),
                WidgetHabitItem(name: "독서", icon: "book.fill", color: "#2196F3", isCompleted: true),
                WidgetHabitItem(name: "명상", icon: "brain.head.profile", color: "#9C27B0", isCompleted: false)
            ],
            heatmapEntries: [
                WidgetHeatmapDay(date: "2026-03-18", count: 2, intensity: 2),
                WidgetHeatmapDay(date: "2026-03-19", count: 3, intensity: 3)
            ],
            updatedAt: Date(timeIntervalSince1970: 1_774_000_000)
        )

        WidgetDataStore.save(data, userDefaults: defaults)
        let loaded = WidgetDataStore.load(userDefaults: defaults)

        #expect(loaded == data)
    }

    @Test("저장된 데이터가 없으면 nil을 반환한다")
    func loadEmpty() {
        let defaults = UserDefaults(suiteName: "test.widget.empty.\(UUID().uuidString)")!
        let loaded = WidgetDataStore.load(userDefaults: defaults)
        #expect(loaded == nil)
    }

    @Test("덮어쓰기 시 최신 데이터를 반환한다")
    func overwrite() {
        let defaults = UserDefaults(suiteName: "test.widget.\(UUID().uuidString)")!

        let old = WidgetHabitData(
            totalCount: 1, completedCount: 0,
            habits: [WidgetHabitItem(name: "A", icon: "star", color: "#000", isCompleted: false)],
            heatmapEntries: [],
            updatedAt: Date(timeIntervalSince1970: 1_000)
        )
        WidgetDataStore.save(old, userDefaults: defaults)

        let new = WidgetHabitData(
            totalCount: 2, completedCount: 2,
            habits: [
                WidgetHabitItem(name: "A", icon: "star", color: "#000", isCompleted: true),
                WidgetHabitItem(name: "B", icon: "leaf", color: "#111", isCompleted: true)
            ],
            heatmapEntries: [],
            updatedAt: Date(timeIntervalSince1970: 2_000)
        )
        WidgetDataStore.save(new, userDefaults: defaults)

        let loaded = WidgetDataStore.load(userDefaults: defaults)
        #expect(loaded == new)
        #expect(loaded?.completedCount == 2)
    }

    // MARK: - buildWidgetData

    @Test("buildWidgetData — 완료/총합 카운트를 올바르게 계산한다")
    func buildWidgetDataCounts() {
        let habits = [
            WidgetHabitItem(name: "운동", icon: "figure.run", color: "#4CAF50", isCompleted: true),
            WidgetHabitItem(name: "독서", icon: "book.fill", color: "#2196F3", isCompleted: false),
            WidgetHabitItem(name: "명상", icon: "brain.head.profile", color: "#9C27B0", isCompleted: true)
        ]
        let heatmap = [
            HeatmapEntry(date: "2026-03-19", count: 2, intensity: 2)
        ]

        let result = WidgetDataBuilder.buildWidgetData(habits: habits, heatmapEntries: heatmap)

        #expect(result.totalCount == 3)
        #expect(result.completedCount == 2)
        #expect(result.habits.count == 3)
    }

    @Test("buildWidgetData — HeatmapEntry를 WidgetHeatmapDay로 변환한다")
    func buildWidgetDataHeatmap() {
        let heatmap = [
            HeatmapEntry(date: "2026-03-17", count: 0, intensity: 0),
            HeatmapEntry(date: "2026-03-18", count: 1, intensity: 1),
            HeatmapEntry(date: "2026-03-19", count: 4, intensity: 4)
        ]

        let result = WidgetDataBuilder.buildWidgetData(habits: [], heatmapEntries: heatmap)

        #expect(result.heatmapEntries.count == 3)
        #expect(result.heatmapEntries[0] == WidgetHeatmapDay(date: "2026-03-17", count: 0, intensity: 0))
        #expect(result.heatmapEntries[2] == WidgetHeatmapDay(date: "2026-03-19", count: 4, intensity: 4))
    }

    @Test("buildWidgetData — 빈 습관 목록이면 0/0을 반환한다")
    func buildWidgetDataEmpty() {
        let result = WidgetDataBuilder.buildWidgetData(habits: [], heatmapEntries: [])

        #expect(result.totalCount == 0)
        #expect(result.completedCount == 0)
        #expect(result.habits.isEmpty)
        #expect(result.heatmapEntries.isEmpty)
    }
}
