import Foundation

enum WidgetDataStore {
    static let appGroupId = "group.com.ethankim.HabitFlow"
    private static let key = "widgetHabitData"

    static func save(_ data: WidgetHabitData, userDefaults: UserDefaults? = nil) {
        let defaults = userDefaults ?? UserDefaults(suiteName: appGroupId)
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        defaults?.set(encoded, forKey: key)
    }

    static func load(userDefaults: UserDefaults? = nil) -> WidgetHabitData? {
        let defaults = userDefaults ?? UserDefaults(suiteName: appGroupId)
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetHabitData.self, from: data)
    }
}
