import Blocks
import XCTest

final class PackageDumpTests: XCTestCase {
    func testExample() throws {
        let dumpPackage = try JSONDecoder().decode(PackageDump.self, fromResource: "dump-package", in: Bundle.module)
        XCTAssertEqual(dumpPackage.name, "swift-blocks")
        XCTAssertEqual(dumpPackage.targets.count, 2)
        XCTAssertEqual(dumpPackage.targets[0].name, "Blocks")
        XCTAssertEqual(dumpPackage.targets[0].type, "regular")
        XCTAssertEqual(dumpPackage.targets[1].name, "BlocksTests")
        XCTAssertEqual(dumpPackage.targets[1].type, "test")
    }
}
