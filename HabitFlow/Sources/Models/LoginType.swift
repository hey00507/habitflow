import Foundation

enum LoginType: String, Sendable {
    case anonymous
    case google

    var displayName: String {
        switch self {
        case .anonymous: "게스트"
        case .google: "Google"
        }
    }
}
