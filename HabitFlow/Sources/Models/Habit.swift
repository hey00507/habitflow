import Foundation
import FirebaseFirestore

struct Habit: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var icon: String          // SF Symbol name
    var color: String         // hex (e.g. "#FF5733")
    var schedule: [Int]       // 반복 요일 (1=일 ~ 7=토)
    var targetTime: String?   // "HH:mm"
    var createdAt: Date
    var isArchived: Bool

    init(
        id: String? = nil,
        name: String,
        icon: String = "star.fill",
        color: String = "#4CAF50",
        schedule: [Int] = [2, 3, 4, 5, 6], // 월~금
        targetTime: String? = nil,
        createdAt: Date = .now,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.schedule = schedule
        self.targetTime = targetTime
        self.createdAt = createdAt
        self.isArchived = isArchived
    }
}
