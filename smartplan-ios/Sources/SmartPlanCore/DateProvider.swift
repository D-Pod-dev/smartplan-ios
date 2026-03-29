import Foundation

public protocol DateProviding: Sendable {
    func now() -> Date
    func today(calendar: Calendar) -> Date
}

public struct SystemDateProvider: DateProviding {
    public init() {}

    public func now() -> Date {
        Date()
    }

    public func today(calendar: Calendar) -> Date {
        calendar.startOfDay(for: Date())
    }
}

public struct OverrideDateProvider: DateProviding {
    private let override: Date?

    public init(override: Date?) {
        self.override = override
    }

    public func now() -> Date {
        override ?? Date()
    }

    public func today(calendar: Calendar) -> Date {
        calendar.startOfDay(for: override ?? Date())
    }
}

public enum DateCodec {
    public static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    public static func parseDate(_ value: String) -> Date? {
        guard !value.isEmpty else { return nil }
        return isoDateFormatter.date(from: value)
    }

    public static func formatDate(_ date: Date) -> String {
        isoDateFormatter.string(from: date)
    }
}
