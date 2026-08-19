#if canImport(Security)
@testable import Blocks
import Security
import XCTest

final class GenericPasswordKeychainItemTests: XCTestCase {
    func testDefaultStorageIsLocalOnly() {
        let item = GenericPasswordKeychainItem(label: "Label", account: "Account")
        XCTAssertEqual(item.storage, .localOnly)
    }

    func testLocalOnlyBaseDictionary() {
        let item = GenericPasswordKeychainItem(label: "Label", account: "Account", storage: .localOnly)
        let dictionary = item.baseDictionary

        XCTAssertEqual(dictionary[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(dictionary[kSecAttrLabel as String] as? String, "Label")
        XCTAssertEqual(dictionary[kSecAttrAccount as String] as? String, "Account")
        XCTAssertEqual(dictionary[kSecAttrSynchronizable as String] as? Bool, false)
    }

    func testICloudBaseDictionary() {
        let item = GenericPasswordKeychainItem(label: "Label", account: "Account", storage: .iCloud)
        let dictionary = item.baseDictionary

        XCTAssertEqual(dictionary[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(dictionary[kSecAttrLabel as String] as? String, "Label")
        XCTAssertEqual(dictionary[kSecAttrAccount as String] as? String, "Account")
        XCTAssertEqual(dictionary[kSecAttrSynchronizable as String] as? Bool, true)
    }

    func testQueryIncludesSynchronizableAttribute() {
        let item = GenericPasswordKeychainItem(label: "Label", account: "Account", storage: .iCloud)
        let query = item.query

        XCTAssertEqual(query[kSecMatchLimit as String] as? String, kSecMatchLimitOne as String)
        XCTAssertEqual(query[kSecAttrSynchronizable as String] as? Bool, true)
    }
}
#endif
