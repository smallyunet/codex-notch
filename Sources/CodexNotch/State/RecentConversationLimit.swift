import Foundation

enum RecentConversationLimit: Int, CaseIterable, Identifiable, Sendable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5

    static let storageKey = "recentConversationLimit"
    static let defaultLimit: RecentConversationLimit = .two

    var id: Int { rawValue }

    var title: String {
        "\(rawValue) 条"
    }

    static func fromStoredValue(_ rawValue: Int) -> RecentConversationLimit {
        Self(rawValue: rawValue) ?? Self.defaultLimit
    }
}

struct NotchRuntimePreferences: Equatable, Sendable {
    let recentConversationLimit: RecentConversationLimit

    static func read(from userDefaults: UserDefaults) -> NotchRuntimePreferences {
        NotchRuntimePreferences(
            recentConversationLimit: RecentConversationLimit.fromStoredValue(
                userDefaults.integer(forKey: RecentConversationLimit.storageKey)
            )
        )
    }
}
