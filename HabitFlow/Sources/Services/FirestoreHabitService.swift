import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirestoreHabitService: HabitServiceProtocol, @unchecked Sendable {
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
        return snapshot.documents.compactMap { doc in
            var habit = try? doc.data(as: Habit.self)
            habit?.id = doc.documentID
            return habit
        }
    }

    func updateHabit(_ habit: Habit) async throws {
        guard let id = habit.id else { throw HabitServiceError.notFound }
        try habitsCollection.document(id).setData(from: habit, merge: true)
    }

    func deleteHabit(_ habitId: String) async throws {
        let logSnapshots = try await logsCollection(habitId: habitId).getDocuments()
        for doc in logSnapshots.documents {
            try await doc.reference.delete()
        }
        try await habitsCollection.document(habitId).delete()
    }

    // MARK: - Logs

    func createLog(_ log: HabitLog, habitId: String) async throws {
        try logsCollection(habitId: habitId).document(log.date).setData(from: log)
    }

    func fetchLogs(habitId: String, from: String, to: String) async throws -> [HabitLog] {
        let snapshot = try await logsCollection(habitId: habitId)
            .whereField("date", isGreaterThanOrEqualTo: from)
            .whereField("date", isLessThanOrEqualTo: to)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            var log = try? doc.data(as: HabitLog.self)
            log?.id = doc.documentID
            return log
        }
    }

    func deleteLog(habitId: String, date: String) async throws {
        try await logsCollection(habitId: habitId).document(date).delete()
    }
}
