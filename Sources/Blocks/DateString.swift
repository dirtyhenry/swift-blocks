import Foundation

public struct DateString {
    // MARK: - Creating an instance

    init?(from dateAsString: String, calendar: Calendar = .current) {
        let formatter = Self.createFormatter(timeZone: calendar.timeZone)
        guard let date = formatter.date(from: dateAsString) else {
            return nil
        }

        self.init(date: date, calendar: calendar, formatter: formatter)
    }

    private init(date: Date, calendar: Calendar = .current, formatter: ISO8601DateFormatter? = nil) {
        self.formatter = formatter ?? Self.createFormatter(timeZone: calendar.timeZone)
        self.date = date
        self.calendar = calendar
    }

    // MARK: - Properties

    private let formatter: ISO8601DateFormatter
    private let date: Date
    private let calendar: Calendar

    // MARK: - Converting to other formats

    func string(with alternativeFormatter: DateFormatter) -> String {
        alternativeFormatter.string(from: date)
    }

    private static func createFormatter(timeZone: TimeZone) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = timeZone
        return formatter
    }
}

extension DateString: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(from: value)!
    }
}

extension DateString: CustomStringConvertible {
    public var description: String {
        formatter.string(from: date)
    }
}

extension DateString: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(formatter.string(from: date)) (\(calendar) \(calendar.timeZone) \(date))"
    }
}

@available(macOS 10.15, *)
extension DateString: Strideable {
    public func distance(to other: DateString) -> Int {
        let timeInterval = date.distance(to: other.date)
        return Int(round(timeInterval / 86400.0))
    }

    public func advanced(by value: Int) -> DateString {
        let newDate = calendar.date(byAdding: .day, value: value, to: date)!
        return DateString(date: newDate, calendar: calendar, formatter: formatter)
    }
}
