import Foundation
import FirebaseFirestore

struct HabitLog: Codable, Identifiable {
    @DocumentID var id: String?  // 문서 ID = "yyyy-MM-dd"
    var date: String             // "yyyy-MM-dd"
    var isCompleted: Bool
    var memo: String?
    var completedAt: Date?

    init(
        id: String? = nil,
        date: String,
        isCompleted: Bool = true,
        memo: String? = nil,
        completedAt: Date? = .now
    ) {
        self.id = id
        self.date = date
        self.isCompleted = isCompleted
        self.memo = memo
        self.completedAt = completedAt
    }
}
