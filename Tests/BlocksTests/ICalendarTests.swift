import Blocks
import XCTest

final class ICalendarTests: XCTestCase {
    func testBasicUsage() throws {
        var iCalendarObject = ICalendarObject(productIdentifier: productIdentifier)

        let event = ICalendarEventComponent(
            uid: "19970901T130000Z-123401@example.com",
            dateTimeStamp: dateFormatter.date(from: "19970901T130000Z")!,
            dateTimeStart: dateFormatter.date(from: "19970903T163000Z")!,
            dateTimeEnd: dateFormatter.date(from: "19970903T190000Z")!,
            summary: "Annual Employee Review",
            description: "Some more details here."
        )
        iCalendarObject.add(event: event)

        let expectedICAL = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//ABC Corporation//NONSGML My Product//
        BEGIN:VEVENT
        UID:19970901T130000Z-123401@example.com
        DTSTAMP:19970901T130000Z
        DTSTART:19970903T163000Z
        DTEND:19970903T190000Z
        SUMMARY:Annual Employee Review
        DESCRIPTION:Some more details here.
        END:VEVENT
        END:VCALENDAR
        """.replacingOccurrences(of: "\n", with: "\r\n")

        XCTAssertEqual(iCalendarObject.iCalString(), expectedICAL)
    }

    func testWithNameAndDescription() throws {
        var iCalendarObject = ICalendarObject(productIdentifier: productIdentifier)
        iCalendarObject.name = "My Calendar Name"
        iCalendarObject.description = "A description of my calendar"

        let expectedICAL = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//ABC Corporation//NONSGML My Product//
        NAME:My Calendar Name
        X-WR-CALNAME:My Calendar Name
        DESCRIPTION:A description of my calendar
        X-WR-CALDESC:A description of my calendar
        END:VCALENDAR
        """.replacingOccurrences(of: "\n", with: "\r\n")

        XCTAssertEqual(iCalendarObject.iCalString(), expectedICAL)
    }

    func testWithCustomFormatter() throws {
        var iCalendarObject = ICalendarObject(productIdentifier: productIdentifier)

        let skipTimezoneDateFormatter = ISO8601DateFormatter()
        skipTimezoneDateFormatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime]

        let event = ICalendarEventComponent(
            uid: "19970901T130000Z-123401@example.com",
            dateTimeStamp: dateFormatter.date(from: "19970901T130000Z")!,
            dateTimeStart: dateFormatter.date(from: "19970903T163000Z")!,
            dateTimeEnd: dateFormatter.date(from: "19970903T190000Z")!,
            summary: "Annual Employee Review",
            description: "Some more details here.",
            dateFormatter: skipTimezoneDateFormatter
        )
        iCalendarObject.add(event: event)

        let expectedICAL = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//ABC Corporation//NONSGML My Product//
        BEGIN:VEVENT
        UID:19970901T130000Z-123401@example.com
        DTSTAMP:19970901T130000
        DTSTART:19970903T163000
        DTEND:19970903T190000
        SUMMARY:Annual Employee Review
        DESCRIPTION:Some more details here.
        END:VEVENT
        END:VCALENDAR
        """.replacingOccurrences(of: "\n", with: "\r\n")

        XCTAssertEqual(iCalendarObject.iCalString(), expectedICAL)
    }

    // MARK: - Test Utils

    let productIdentifier = "-//ABC Corporation//NONSGML My Product//"

    var dateFormatter: ISO8601DateFormatter = {
        let res = ISO8601DateFormatter()
        res.formatOptions = [.withYear, .withMonth, .withDay, .withTime, .withTimeZone]
        return res
    }()
}
