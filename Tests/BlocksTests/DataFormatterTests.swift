import Blocks
import XCTest

final class DataFormatterTests: XCTestCase {
    func testDataFormatterBasicUsage() throws {
        let bytes: [UInt8] = Array(0 ... 255)
        let sampleData = Data(bytes)

        XCTAssertEqual(DataFormatter.base64String(from: sampleData), "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYGFiY2RlZmdoaWprbG1ub3BxcnN0dXZ3eHl6e3x9fn+AgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6ChoqOkpaanqKmqq6ytrq+wsbKztLW2t7i5uru8vb6/wMHCw8TFxsfIycrLzM3Oz9DR0tPU1dbX2Nna29zd3t/g4eLj5OXm5+jp6uvs7e7v8PHy8/T19vf4+fr7/P3+/w==")
        XCTAssertEqual(DataFormatter.hexadecimalString(from: sampleData), "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff")

        XCTAssertEqual(sampleData, DataFormatter.data(fromBase64String: DataFormatter.base64String(from: sampleData)))
        XCTAssertEqual(sampleData, DataFormatter.data(fromHexadecimalString: DataFormatter.hexadecimalString(from: sampleData)))
    }

    func testBase64URLFormatting() throws {
        let originData = Data([3, 236, 255, 224, 193])
        let base64URLEncodedString = DataFormatter.base64URLString(from: originData)
        XCTAssertEqual(base64URLEncodedString, "A-z_4ME")

        let destinationData = try XCTUnwrap(DataFormatter.data(fromBase64URLString: "A-z_4ME"))
        XCTAssertEqual(destinationData, originData)
    }
}
