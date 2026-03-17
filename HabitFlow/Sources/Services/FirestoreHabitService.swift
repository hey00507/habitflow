import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirestoreHabitService: HabitServiceProtocol {
    private let db = Firestore.firestore()

    private var userId: String {
        Auth.auth().currentUser?.uid ?? "anonymous"
    }

    private var habitsCollection: CollectionReference {
        db.collection("users").document(userId).collection("habits")
    }

    private func logsCollection(habitId: String) -> CollectionReference {
        habitsCollection.document(habitId).collection("logs")
    }

    // MARK: - Habits

    func createHabit(_ habit: Habit) async throws -> Habit {
        let ref = try habitsCollection.addDocument(from: habit)
        var created = habit
        created.id = ref.documentID
        return created
    }

    func fetchHabits() async throws -> [Habit] {
        let snapshot = try await habitsCollection
            .whereField("isArchived", isEqualTo: false)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Habit.self) }
    }

    func updateHabit(_ habit: Habit) async throws {
        guard let id = habit.id else { throw HabitServiceError.notFound }
        try habitsCollection.document(id).setData(from: habit, merge: true)
    }

    func deleteHabit(_ habitId: String) async throws {
        // 서브컬렉션(logs) 삭제
        let logSnapshots = try await logsCollection(habitId: habitId).getDocuments()
        for doc in logSnapshots.documents {
            try await doc.reference.delete()
        }
        // 습관 문서 삭제
        try await habitsCollection.document(habitId).delete()
    }

    // MARK: - Logs

    func createLog(_ log: HabitLog, habitId: String) async throws {
        // date를 문서 ID로 사용하여 같은 날짜 중복 방지
        try logsCollection(habitId: habitId).document(log.date).setData(from: log)
    }

    func fetchLogs(habitId: String, from: String, to: String) async throws -> [HabitLog] {
        let snapshot = try await logsCollection(habitId: habitId)
            .whereField("date", isGreaterThanOrEqualTo: from)
            .whereField("date", isLessThanOrEqualTo: to)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: HabitLog.self) }
    }

    func deleteLog(habitId: String, date: String) async throws {
        try await logsCollection(habitId: habitId).document(date).delete()
    }
}
