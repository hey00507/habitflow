import Foundation
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
        #expect(auth.isAnonymous == true)
        #expect(auth.userEmail == nil)
    }

    @Test("로그인 타입이 anonymous이면 isAnonymous가 true이다")
    func test_loginType_anonymous() {
        let auth = AuthService()
        #expect(auth.loginType == .anonymous)
        #expect(auth.isAnonymous == true)
    }

    @Test("로그인 타입 enum displayName이 올바르다")
    func test_loginType_displayNames() {
        #expect(LoginType.anonymous.displayName == "게스트")
        #expect(LoginType.google.displayName == "Google")
    }

    @Test("LoginType.google이면 isAnonymous가 false여야 한다")
    func test_loginType_google_isNotAnonymous() {
        #expect(LoginType.google != .anonymous)
    }

    @Test("LoginType에 email 케이스가 존재하지 않아야 한다")
    func test_loginType_noEmailCase() {
        let allCases: [LoginType] = [.anonymous, .google]
        #expect(allCases.count == 2)
    }
}
