import Foundation

/// This structure constructs ICalendar documents according to RFC 5545.
public struct ICalendarObject {
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
        """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:\(productIdentifier)
        \(events.map { $0.iCalString(formatter: formatter) }.joined(separator: "\n"))
        END:VCALENDAR
        """
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
    func iCalString(formatter: ISO8601DateFormatter) -> String {
        """
        BEGIN:VEVENT
        UID:\(uid)
        DTSTAMP:\(formatter.string(from: dateTimeStamp))
        DTSTART:\(formatter.string(from: dateTimeStart))
        DTEND:\(formatter.string(from: dateTimeEnd))
        SUMMARY:\(summary)
        DESCRIPTION:\(description)
        END:VEVENT
        """
    }
}
