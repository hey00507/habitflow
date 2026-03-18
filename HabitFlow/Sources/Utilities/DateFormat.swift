import Foundation

enum DateFormat {
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static func string(from date: Date) -> String {
        yyyyMMdd.string(from: date)
    }

    static func date(from string: String) -> Date? {
        yyyyMMdd.date(from: string)
    }
}
