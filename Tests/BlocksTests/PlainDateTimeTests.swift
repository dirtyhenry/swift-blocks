import Blocks
import XCTest

final class PlainDateTimeTests: XCTestCase {
    func testAtHourAndMinuteInParis() throws {
        // Paris is on UTC+1 before March 27th 2022, on UTC+2 after.
        let winter = try XCTUnwrap(PlainDate(from: "2022-03-26", calendar: .parisCalendar()))
        let summer = try XCTUnwrap(PlainDate(from: "2022-03-28", calendar: .parisCalendar()))

        XCTAssertEqual(try XCTUnwrap(winter.at(hour: 21, minute: 0)), ISO8601DateFormatter().date(from: "2022-03-26T20:00:00Z"))
        XCTAssertEqual(try XCTUnwrap(summer.at(hour: 21, minute: 0)), ISO8601DateFormatter().date(from: "2022-03-28T19:00:00Z"))
    }

    func testAtHourAndMinuteInAnotherCalendar() throws {
        // New York is on UTC-4 after March 13th 2022.
        let date = try XCTUnwrap(PlainDate(from: "2022-03-14", calendar: .parisCalendar()))

        XCTAssertEqual(
            try XCTUnwrap(date.at(hour: 19, minute: 30, calendar: .newYorkCalendar())),
            ISO8601DateFormatter().date(from: "2022-03-14T23:30:00Z")
        )
    }
}
