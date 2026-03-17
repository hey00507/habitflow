import Testing
@testable import HabitFlow

@Suite("AuthService Tests")
@MainActor
struct AuthServiceTests {
    @Test("초기 상태에서는 미인증이다")
    func test_initialState_notAuthenticated() {
        let auth = AuthService()
        #expect(auth.isAuthenticated == false)
        #expect(auth.userId == nil)
    }
}
