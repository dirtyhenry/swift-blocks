import Foundation

/// A formatter that converts between binary data and their plain text representations.
public enum DataFormatter {
    public struct HexadecimalEncodingOptions: OptionSet {
        public let rawValue: Int

        public static let uppercase = HexadecimalEncodingOptions(rawValue: 1 << 0)

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    // MARK: - Base64 Support

    public static func base64String(from data: Data, options: Data.Base64EncodingOptions = []) -> String {
        data.base64EncodedString(options: options)
    }

    public static func base64String<T: DataProtocol>(from data: T, options: Data.Base64EncodingOptions = []) -> String {
        Data(data).base64EncodedString(options: options)
    }

    public static func base64String<T: ContiguousBytes>(from bytes: T, options: Data.Base64EncodingOptions = []) -> String {
        bytes.withUnsafeBytes { buffer in
            Data(buffer).base64EncodedString(options: options)
        }
    }

    public static func data(fromBase64String base64String: String) -> Data? {
        Data(base64Encoded: base64String)
    }

    // MARK: - Hexadecimal Support

    public static func hexadecimalString(from data: Data, options: HexadecimalEncodingOptions = []) -> String {
        let format = options.contains(.uppercase) ? "%02hhX" : "%02hhx"
        return data.map { String(format: format, $0) }.joined()
    }

    public static func hexadecimalString<T: DataProtocol>(from data: T, options: HexadecimalEncodingOptions = []) -> String {
        hexadecimalString(from: Data(data), options: options)
    }

    public static func hexadecimalString<T: ContiguousBytes>(from bytes: T, options: HexadecimalEncodingOptions = []) -> String {
        bytes.withUnsafeBytes { buffer in
            hexadecimalString(from: Data(buffer), options: options)
        }
    }

    public static func data(fromHexadecimalString base64String: String) -> Data? {
        let bytes: UnfoldSequence<UInt8, String.Index> = sequence(state: base64String.startIndex) { startIndex in
            guard startIndex < base64String.endIndex else { return nil }
            let endIndex = base64String.index(startIndex, offsetBy: 2, limitedBy: base64String.endIndex) ?? base64String.endIndex
            defer { startIndex = endIndex }
            return UInt8(base64String[startIndex ..< endIndex], radix: 16)
        }
        return Data(bytes)
    }
}
