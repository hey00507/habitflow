import Foundation

struct HeatmapEntry: Equatable, Sendable {
    let date: String      // "yyyy-MM-dd"
    let count: Int        // completed habits count for this day
    let intensity: Int    // 0-4 color intensity level
}
