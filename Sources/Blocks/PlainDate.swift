import Foundation

/// A string that represents dates without time, using their ISO 8601 representations.
///
/// `PlainDate` provides a way to handle dates with no time — such as `2022-03-02` for March 2nd of 2022 — to
/// perform operations with convenience, including adding days, dealing with ranges, and more.
///
/// ## Usage Overview
///
/// A plain date can be created from a string literal, or directly using a `Date` object. It supports date range
/// iteration, addition of days, and custom formatting.
///
/// ```swift
/// let march1st: PlainDate = "2022-03-01"
/// let aWeekLater = march1st.advanced(by: 7)
/// for day in march1st ..< aWeekLater {
///   print(day)
/// }
/// ```
public struct PlainDate: Sendable {
    // MARK: - Creating an instance

    /// Creates a plain date from an ISO 8601 string representation.
    ///
    /// - Parameters:
    ///   - dateAsString: The ISO 8601 string representing the date (e.g., `2022-03-02` for March 2nd, 2022).
    ///   - calendar: The calendar to use (default is `.current`).
    /// - Returns: A `PlainDate`, or `nil` if the string is not in the `YYYY-MM-DD` format.
    ///   The initializer also returns `nil` for a day that does not exist, such as `2022-02-30`.
    public init?(from dateAsString: String, calendar: Calendar = .current) {
        let parts = dateAsString.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              parts.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isNumber } }),
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2])
        else {
            return nil
        }

        var gregorian = Self.gregorianCalendar
        gregorian.timeZone = calendar.timeZone
        guard let date = gregorian.date(from: DateComponents(year: year, month: month, day: day)) else {
            return nil
        }

        self.init(date: date, calendar: calendar)

        // The calendar rolls over days that do not exist: 2022-02-30 becomes 2022-03-02.
        guard isoDay == ISODay(year: year, month: month, day: day) else {
            return nil
        }
    }

    /// Creates a plain date from a `Date` object.
    ///
    /// The initializer keeps the start of the day of `date` in `calendar`. It removes the time of day.
    ///
    /// - Parameters:
    ///   - date: The `Date` to represent.
    ///   - calendar: The calendar to use (default is `.current`).
    public init(date: Date, calendar: Calendar = .current) {
        self.date = calendar.startOfDay(for: date)
        self.calendar = calendar
    }

    // MARK: - Properties

    public let date: Date
    public let calendar: Calendar

    // MARK: - Converting to other formats

    /// Returns a string representation of the date using a custom formatter.
    ///
    /// - Note: Avoid using an `alternativeFormatter` with a `timeStyle` other than `.none`.
    ///
    /// - Parameter alternativeFormatter: The formatter to use.
    /// - Returns: A string representing the date.
    public func string(with alternativeFormatter: DateFormatter) -> String {
        #if DEBUG
        if alternativeFormatter.timeStyle != .none {
            fatalError(
                "Runtime issue: please do not use timeStyle in an alternative formatter."
            )
        }
        #endif
        return alternativeFormatter.string(from: date)
    }
}

extension PlainDate: ExpressibleByStringLiteral {
    // MARK: - ExpressibleByStringLiteral

    /// Allows `PlainDate` to be initialized from a string literal.
    ///
    /// Example:
    /// ```swift
    /// let date: PlainDate = "2022-03-02"
    /// ```
    public init(stringLiteral value: String) {
        guard let instance = PlainDate(from: value) else {
            fatalError("Could not turn \(value) into a DateString.")
        }

        self = instance
    }
}

extension PlainDate: CustomStringConvertible {
    // MARK: - CustomStringConvertible

    /// A string description of the `PlainDate` in ISO 8601 format.
    public var description: String {
        let isoDay = isoDay
        return String(format: "%04d-%02d-%02d", isoDay.year, isoDay.month, isoDay.day)
    }
}

extension PlainDate: CustomDebugStringConvertible {
    // MARK: - CustomDebugStringConvertible

    /// A debug description of the `PlainDate` including calendar and time zone details.
    public var debugDescription: String {
        "\(description) (\(calendar) \(calendar.timeZone) \(date))"
    }
}

extension PlainDate: Strideable {
    // MARK: - Strideable Conformance

    /// Calculates the distance in days to another `PlainDate`.
    public func distance(to other: PlainDate) -> Int {
        other.isoDay.julianDayNumber - isoDay.julianDayNumber
    }

    /// Advances the date by a specified number of days.
    ///
    /// - Precondition: The result must be in the range of dates that `calendar` can represent.
    public func advanced(by value: Int) -> PlainDate {
        guard let newDate = calendar.date(byAdding: .day, value: value, to: date) else {
            preconditionFailure("Could not advance \(self) by \(value) days.")
        }

        return PlainDate(date: newDate, calendar: calendar)
    }
}

extension PlainDate: Equatable, Hashable, Comparable {
    // MARK: - Equatable, Hashable and Comparable Conformances

    /// Two plain dates are equal when they have the same ISO 8601 day, also with different calendars.
    public static func == (lhs: PlainDate, rhs: PlainDate) -> Bool {
        lhs.isoDay == rhs.isoDay
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(isoDay)
    }

    public static func < (lhs: PlainDate, rhs: PlainDate) -> Bool {
        lhs.isoDay < rhs.isoDay
    }
}

extension PlainDate {
    /// The year, month and day of a plain date in the ISO 8601 (Gregorian) calendar.
    struct ISODay: Hashable, Comparable {
        let year: Int
        let month: Int
        let day: Int

        static func < (lhs: ISODay, rhs: ISODay) -> Bool {
            (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
        }

        /// The number of days since January 1st, 4713 BC, in the proleptic Julian calendar.
        ///
        /// The difference between two Julian day numbers is the number of days between them.
        var julianDayNumber: Int {
            let shift = (14 - month) / 12
            let shiftedYear = year + 4800 - shift
            let shiftedMonth = month + 12 * shift - 3
            return day + (153 * shiftedMonth + 2) / 5 + 365 * shiftedYear
                + shiftedYear / 4 - shiftedYear / 100 + shiftedYear / 400 - 32045
        }
    }

    private static let gregorianCalendar = Calendar(identifier: .gregorian)
    private static let iso8601Calendar = Calendar(identifier: .iso8601)

    /// The ISO 8601 day of this plain date, in the time zone of its calendar.
    var isoDay: ISODay {
        var gregorian = Self.gregorianCalendar
        gregorian.timeZone = calendar.timeZone
        let components = gregorian.dateComponents([.year, .month, .day], from: date)
        return ISODay(year: components.year ?? 0, month: components.month ?? 0, day: components.day ?? 0)
    }
}

public extension PlainDate {
    // MARK: - Weekday and Components

    /// Represents a day of the week.
    enum Weekday: Int {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
    }

    /// The day of the week for this `PlainDate`.
    var weekday: Weekday {
        let components = calendar.dateComponents([.weekday], from: date)
        guard let weekday = components.weekday, let result = Weekday(rawValue: weekday) else {
            preconditionFailure("No weekday found for \(self)")
        }

        return result
    }

    /// The year and week number of this `PlainDate`.
    var yearWeek: String {
        var iso8601 = Self.iso8601Calendar
        iso8601.timeZone = calendar.timeZone
        let components = iso8601.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", components.yearForWeekOfYear ?? 0, components.weekOfYear ?? 0)
    }

    /// Advances the date to the next specified weekday.
    func advanced(toNext outputWeekday: Weekday) -> PlainDate {
        var advancingDay = self
        while advancingDay.weekday != outputWeekday {
            advancingDay = advancingDay.advanced(by: 1)
        }
        return advancingDay
    }
}

public extension PlainDate {
    /// The date components (year, month, day) of this `PlainDate`.
    var dateComponents: DateComponents {
        calendar.dateComponents([.year, .month, .day], from: date)
    }
}

// MARK: - Codable Conformance

extension PlainDate: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        guard let instance = PlainDate(from: value) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Could not turn \(value) into a PlainDate."
            )
        }

        self = instance
    }
}

extension PlainDate: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

@available(*, deprecated, renamed: "PlainDate", message: "Cf. Temporal effort in JS.")
public typealias DateString = PlainDate

// MARK: - 3rd-Party Apps helpers

public extension PlainDate {
    /// Creates a custom URL for the current PlainDate instance, using the "day" URL scheme.
    ///
    /// The host portion of the URL is the date in ISO 8601 format, but with hyphens replaced by periods
    /// (for example, 2025-06-02 becomes 2025.06.02). This is intended for integration with third-party
    /// apps (such as Craft) that recognize or handle this style of date-based linking.
    func craftURL() throws -> URL {
        var components = URLComponents()
        components.scheme = "day"
        components.host = description.replacingOccurrences(of: "-", with: ".")

        guard let url = components.url else {
            throw SimpleMessageError(message: "Could not generate Craft URL for date \(self).")
        }

        return url
    }
}
