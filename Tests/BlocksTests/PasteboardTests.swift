import Blocks
import XCTest

final class PasteboardTests: XCTestCase {
    func testBasicUsage() throws {
        let pasteboard = Pasteboard()
        pasteboard.copy(text: "8137538166")

        #if os(macOS)
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "8137538166")
        #endif

        #if os(iOS)
        XCTAssertEqual(UIPasteboard.general.value(forPasteboardType: "public.text") as? String, "8137538166")
        #endif
    }
}
