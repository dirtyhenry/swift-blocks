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
        let march26 = DateString(from: "2022-03-26", calendar: .frenchCalendar())!
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
        let march1st = DateString(from: "2022-03-01", calendar: .frenchCalendar())!
        let aWeekLater = march1st.advanced(by: 7)
        let range = march1st ..< aWeekLater

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let array = Array(range).map { $0.string(with: formatter) }
        XCTAssertEqual(array, ["20220301", "20220302", "20220303", "20220304", "20220305", "20220306", "20220307"])
    }
}
