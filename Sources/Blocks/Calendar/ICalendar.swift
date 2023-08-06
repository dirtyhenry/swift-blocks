import Foundation

/// This structure constructs minimalist ICalendar documents according to RFC 5545.
public struct ICalendarObject {
    private let separator = "\r\n"

    
    /// This property specifies the identifier for the product that
    /// created the iCalendar object.
    let productIdentifier: String

    /// The events components of the calendar document.
    private(set) var events: [ICalendarEventComponent]

    public init(productIdentifier: String, events: [ICalendarEventComponent] = []) {
        self.productIdentifier = productIdentifier
        self.events = events
    }

    public mutating func add(event: ICalendarEventComponent) {
        events.append(event)
    }

    public func iCalString(formatter: ISO8601DateFormatter) -> String {
        return components.joined(separator: separator)
    }
    
    @ICalendarBuilder var components: [String] {
        ICalKeyValue(key: "BEGIN", value: "VCALENDAR")
        ICalKeyValue(key: "VERSION", value: "2.0")
        ICalKeyValue(key: "PRODID", value: productIdentifier)
        events
        ICalKeyValue(key: "END", value: "VCALENDAR")
    }
}

struct ICalKeyValue {
    let key: String
    let value: String
    
    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

struct ICalKeyDateValue {
    let key: String
    let value: Date
    
    init(key: String, value: Date) {
        self.key = key
        self.value = value
    }
}

public struct ICalendarEventComponent {
    /// This property defines the persistent, globally unique identifier for the calendar component.
    let uid: String

    /// This property specifies the date and time that the information
    /// associated with the calendar component was last revised in the
    /// calendar store.
    let dateTimeStamp: Date

    /// This property specifies when the calendar component begins.
    let dateTimeStart: Date

    /// This property specifies the date and time that a calendar component ends.
    let dateTimeEnd: Date

    /// This property defines a short summary or subject for the
    /// calendar component.
    let summary: String

    /// This property provides a more complete description of the
    /// calendar component than that provided by the `summary` property.
    let description: String

    public init(uid: String, dateTimeStamp: Date, dateTimeStart: Date, dateTimeEnd: Date, summary: String, description: String) {
        self.uid = uid
        self.dateTimeStamp = dateTimeStamp
        self.dateTimeStart = dateTimeStart
        self.dateTimeEnd = dateTimeEnd
        self.summary = summary
        self.description = description
    }
}

public extension ICalendarEventComponent {
    @ICalendarBuilder var components: [String] {
        ICalKeyValue(key: "BEGIN", value: "VEVENT")
        ICalKeyValue(key: "UID", value: uid)
        ICalKeyDateValue(key: "DTSTAMP", value: dateTimeStamp)
        ICalKeyDateValue(key: "DTSTART", value: dateTimeStart)
        ICalKeyDateValue(key: "DTEND", value: dateTimeEnd)
        ICalKeyValue(key: "SUMMARY", value: summary)
        ICalKeyValue(key: "DESCRIPTION", value: description)
        ICalKeyValue(key: "END", value: "VEVENT")
    }
}

@resultBuilder
struct ICalendarBuilder {
    static var formatter: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime, .withTimeZone]
        return dateFormatter
    }()
    
    static func buildBlock(_ components: [String]...) -> [String] {
        components.flatMap { $0 }
    }
    
    static func buildExpression(_ expression: ICalKeyValue) -> [String] {
        return ["\(expression.key):\(expression.value)"]
    }
    
    static func buildExpression(_ expression: ICalKeyDateValue) -> [String] {
        return ["\(expression.key):\(formatter.string(from: expression.value))"]
    }
    
    static func buildExpression(_ expression: [ICalendarEventComponent]) -> [String] {
        expression.map { $0.components }.flatMap { $0 }
    }
    
    static func buildArray(_ components: [[String]]) -> [String] {
        components.flatMap { $0 }
    }
}
