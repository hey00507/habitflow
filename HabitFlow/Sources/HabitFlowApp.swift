import SwiftUI
import FirebaseCore

@main
struct HabitFlowApp: App {
    @State private var authService = AuthService()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)
                .task {
                    authService.restoreSession()
                    if !authService.isAuthenticated {
                        try? await authService.signInAnonymously()
                    }
                }
        }
    }
}
