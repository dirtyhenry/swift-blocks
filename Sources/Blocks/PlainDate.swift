import Foundation

/// A string that represents dates using their ISO 8601 representations.
///
/// `DateString` is a way to handle dates with no time — such as `2022-03-02` for March 2nd of 2022 — to
/// perform operations with convenience including adding days, dealing with ranges, etc.
///
/// ## Usage Overview
///
/// A date string can be initiated from a string literal, and can be used to create ranges.
///
/// ```swift
/// let dateString: DateString = "2022-03-01"
/// let aWeekLater = dateString.advanced(by: 7)
/// for day in march1st ..< aWeekLater {
///   print(day)
/// }
/// ```
public struct PlainDate {
    // MARK: - Creating an instance

    /// Returns a date string initialized using their ISO 8601 representation.
    /// - Parameters:
    ///   - dateAsString: The ISO 8601 representation of the date. For instance, `2022-03-02`for March 2nd of 2022.
    ///   - calendar: The calendar — including the time zone — to use. The default is the current calendar.
    /// - Returns:A date string, or `nil` if a valid date could not be created from `dateAsString`.
    public init?(from dateAsString: String, calendar: Calendar = .current) {
        let formatter = Self.createFormatter(timeZone: calendar.timeZone)
        guard let date = formatter.date(from: dateAsString) else {
            return nil
        }

        self.init(date: date, calendar: calendar, formatter: formatter)
    }

    /// Returns a date string initialized using their ISO 8601 representation.
    /// - Parameters:
    ///   - date: The date to represent.
    ///   - calendar: The calendar — including the time zone — to use. The default is the current calendar.
    public init(date: Date, calendar: Calendar = .current) {
        self.init(date: date, calendar: calendar, formatter: Self.createFormatter(timeZone: calendar.timeZone))
    }

    private init(date: Date, calendar: Calendar = .current, formatter: ISO8601DateFormatter) {
        self.formatter = formatter
        self.date = date
        self.calendar = calendar
    }

    // MARK: - Properties

    private let formatter: ISO8601DateFormatter
    private let date: Date
    private let calendar: Calendar

    // MARK: - Converting to other formats

    /// Returns a string representation of the date that the system formats using the receiver’s current settings.
    ///
    /// Use this method only if you need a string representation of the date that is not ISO 8601.
    ///
    /// The return value might be irrelevant if the date formatter uses some time information.
    ///
    /// - Parameter alternativeFormatter: The date formatter to use.
    /// - Returns: A string representation of the date.
    public func string(with alternativeFormatter: DateFormatter) -> String {
        alternativeFormatter.string(from: date)
    }

    private static func createFormatter(timeZone: TimeZone) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = timeZone
        return formatter
    }
}

extension PlainDate: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        if PlainDate(from: value) != nil {
            self.init(from: value)!
        } else {
            fatalError("Could not turn \(value) into a DateString.")
        }
    }
}

extension PlainDate: CustomStringConvertible {
    public var description: String {
        formatter.string(from: date)
    }
}

extension PlainDate: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(formatter.string(from: date)) (\(calendar) \(calendar.timeZone) \(date))"
    }
}

extension PlainDate: Strideable {
    public func distance(to other: PlainDate) -> Int {
        if #available(macOS 10.15, iOS 13.0, *) {
            // 🐇 A faster working — so far — alternative.
            let timeInterval = date.distance(to: other.date)
            return Int(round(timeInterval / 86400.0))
        } else {
            // 🐢 Intellectually satisfying but a little slow.
            let start = calendar.ordinality(of: .day, in: .era, for: date)
            let end = calendar.ordinality(of: .day, in: .era, for: other.date)

            guard let start, let end else {
                fatalError("The distance between 2 dates could not be computed.")
            }

            return end - start
        }
    }

    public func advanced(by value: Int) -> PlainDate {
        let newDate = calendar.date(byAdding: .day, value: value, to: date)!
        return PlainDate(date: newDate, calendar: calendar, formatter: formatter)
    }
}

extension PlainDate: Decodable {
    public init(from decoder: Decoder) throws {
        try self.init(stringLiteral: decoder.singleValueContainer().decode(String.self))
    }
}

extension PlainDate: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

public extension PlainDate {
    enum Weekday: Int {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
    }

    var weekday: Weekday {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let components = calendar.dateComponents([.weekday], from: date)
        guard let result = Weekday(rawValue: components.weekday!) else {
            fatalError("No weekday found for \(self)")
        }

        return result
    }

    func advanced(toNext outputWeekday: Weekday) -> PlainDate {
        var advancingDay = self
        while advancingDay.weekday != outputWeekday {
            advancingDay = advancingDay.advanced(by: 1)
        }
        return advancingDay
    }
}

public extension PlainDate {
    var dateComponents: DateComponents {
        calendar.dateComponents([.year, .month, .day], from: date)
    }
}

@available(*, deprecated, renamed: "PlainDate", message: "Cf. Temporal effort in JS.")
public typealias DateString = PlainDate
