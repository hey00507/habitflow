import Foundation

struct Habit: Codable, Identifiable, Sendable, Hashable {
    var id: String?
    var name: String
    var icon: String          // SF Symbol name
    var color: String         // hex (e.g. "#FF5733")
    var schedule: [Int]       // 반복 요일 (1=일 ~ 7=토)
    var targetTime: String?   // "HH:mm"
    var createdAt: Date
    var isArchived: Bool
    var isNotificationEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case name, icon, color, schedule, targetTime, createdAt, isArchived, isNotificationEnabled
    }

    init(
        id: String? = nil,
        name: String,
        icon: String = "star.fill",
        color: String = "#4CAF50",
        schedule: [Int] = [2, 3, 4, 5, 6],
        targetTime: String? = nil,
        createdAt: Date = .now,
        isArchived: Bool = false,
        isNotificationEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.schedule = schedule
        self.targetTime = targetTime
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.isNotificationEnabled = isNotificationEnabled
    }
}
