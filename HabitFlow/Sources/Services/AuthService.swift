import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

enum AuthError: Error, Sendable {
    case missingClientID
    case missingIDToken
    case missingRootViewController
    case missingWindow
}

@MainActor
@Observable
final class AuthService {
    private(set) var userId: String?
    private(set) var isAuthenticated = false
    private(set) var loginType: LoginType = .anonymous
    private(set) var userEmail: String?

    var isAnonymous: Bool { loginType == .anonymous }

    // MARK: - Anonymous Auth

    func signInAnonymously() async throws {
        let result = try await Auth.auth().signInAnonymously()
        userId = result.user.uid
        isAuthenticated = true
        loginType = .anonymous
    }

    func restoreSession() {
        guard let user = Auth.auth().currentUser else { return }
        userId = user.uid
        isAuthenticated = true

        if user.isAnonymous {
            loginType = .anonymous
        } else {
            loginType = .google
            userEmail = user.email
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.missingClientID
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.missingRootViewController
        }
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        #elseif os(macOS)
        guard let window = NSApplication.shared.keyWindow else {
            throw AuthError.missingWindow
        }
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
        #endif

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingIDToken
        }
        let accessToken = result.user.accessToken.tokenString

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

        if let user = Auth.auth().currentUser, user.isAnonymous {
            let authResult = try await user.link(with: credential)
            userId = authResult.user.uid
            userEmail = authResult.user.email
        } else {
            let authResult = try await Auth.auth().signIn(with: credential)
            userId = authResult.user.uid
            userEmail = authResult.user.email
        }

        isAuthenticated = true
        loginType = .google
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        userId = nil
        isAuthenticated = false
        loginType = .anonymous
        userEmail = nil
    }
}
