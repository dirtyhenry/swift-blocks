@testable import Blocks
import XCTest

final class DateStringTests: XCTestCase {
    func testBasicUsage() throws {
        let randomDate: DateString = "2022-01-19"
        XCTAssertEqual(randomDate.description, "2022-01-19")
        XCTAssertEqual(randomDate.advanced(by: 1).description, "2022-01-20")
        XCTAssertEqual(randomDate.advanced(by: 12).description, "2022-01-31")
        XCTAssertEqual(randomDate.advanced(by: 13).description, "2022-02-01")
    }

    func testDaylightSavingTimePeriods() throws {
        // In France, time will change on March 27th in 2022.
        let march26 = DateString(from: "2022-03-26", calendar: .parisCalendar())!
        XCTAssertEqual(march26.description, "2022-03-26")
        XCTAssertEqual(march26.advanced(by: 1).description, "2022-03-27")
        XCTAssertEqual(march26.advanced(by: 2).description, "2022-03-28")

        // In New York, time will change on March 13th in 2022.
        let march12 = DateString(from: "2022-03-12", calendar: .newYorkCalendar())!
        XCTAssertEqual(march12.description, "2022-03-12")
        XCTAssertEqual(march12.advanced(by: 1).description, "2022-03-13")
        XCTAssertEqual(march12.advanced(by: 2).description, "2022-03-14")
    }

    func testFormattingRangeOfDates() throws {
        let march1st = DateString(from: "2022-03-01", calendar: .parisCalendar())!
        let aWeekLater = march1st.advanced(by: 7)
        let range = march1st ..< aWeekLater

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = Calendar.parisCalendar().timeZone
        let array = Array(range).map { $0.string(with: formatter) }
        XCTAssertEqual(array, ["20220301", "20220302", "20220303", "20220304", "20220305", "20220306", "20220307"])
    }

    func testDistanceOfDatesIsConsistent() throws {
        let januaryFirst = DateString(from: "2022-01-01", calendar: .parisCalendar())!

        measure {
            for offset in 1 ... 100_000 {
                XCTAssertEqual(januaryFirst.advanced(by: offset).distance(to: januaryFirst), -offset)
            }
        }
    }

    struct MockCodable: Codable {
        let dateString: DateString
    }

    let mockJSON = """
    {"dateString":"2022-01-19"}
    """

    func testEncodable() throws {
        let mockCodable = MockCodable(dateString: "2022-01-19")
        let json = try JSONEncoder().encode(mockCodable)
        let jsonString = String(data: json, encoding: .utf8)
        XCTAssertEqual(jsonString, mockJSON)
    }

    func testDecodable() throws {
        let mockCodable = try JSONDecoder().decode(MockCodable.self, from: mockJSON.data(using: .utf8)!)
        XCTAssertEqual("2022-01-19", mockCodable.dateString.description)
    }

    func testWeekdays() {
        XCTAssertEqual(DateString(stringLiteral: "2023-03-13").weekday, DateString.Weekday.monday)
        XCTAssertEqual(DateString(stringLiteral: "2023-03-14").weekday, DateString.Weekday.tuesday)
        XCTAssertEqual(DateString(stringLiteral: "2023-03-15").weekday, DateString.Weekday.wednesday)
        XCTAssertEqual(DateString(stringLiteral: "2023-03-16").weekday, DateString.Weekday.thursday)
        XCTAssertEqual(DateString(stringLiteral: "2023-03-17").weekday, DateString.Weekday.friday)
        XCTAssertEqual(DateString(stringLiteral: "2023-03-18").weekday, DateString.Weekday.saturday)
        XCTAssertEqual(DateString(stringLiteral: "2023-03-19").weekday, DateString.Weekday.sunday)
    }

    func testAdvancedToWeekday() {
        XCTAssertEqual(DateString(stringLiteral: "2023-03-13").advanced(toNext: .tuesday).description, "2023-03-14")
        XCTAssertEqual(DateString(stringLiteral: "2023-03-14").advanced(toNext: .tuesday).description, "2023-03-14")
        XCTAssertEqual(DateString(stringLiteral: "2023-03-15").advanced(toNext: .tuesday).description, "2023-03-21")
        XCTAssertEqual(DateString(stringLiteral: "2023-03-16").advanced(toNext: .tuesday).description, "2023-03-21")
        XCTAssertEqual(DateString(stringLiteral: "2023-03-17").advanced(toNext: .tuesday).description, "2023-03-21")
        XCTAssertEqual(DateString(stringLiteral: "2023-03-18").advanced(toNext: .tuesday).description, "2023-03-21")
        XCTAssertEqual(DateString(stringLiteral: "2023-03-19").advanced(toNext: .tuesday).description, "2023-03-21")
    }
}
