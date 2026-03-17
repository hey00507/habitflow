import Foundation
import FirebaseAuth

@MainActor
@Observable
final class AuthService {
    private(set) var userId: String?
    private(set) var isAuthenticated = false

    func signInAnonymously() async throws {
        let result = try await Auth.auth().signInAnonymously()
        userId = result.user.uid
        isAuthenticated = true
    }

    func restoreSession() {
        if let user = Auth.auth().currentUser {
            userId = user.uid
            isAuthenticated = true
        }
    }
}
