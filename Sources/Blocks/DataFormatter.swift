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

    public static func base64String(from data: some DataProtocol, options: Data.Base64EncodingOptions = []) -> String {
        Data(data).base64EncodedString(options: options)
    }

    public static func base64String(from bytes: some ContiguousBytes, options: Data.Base64EncodingOptions = []) -> String {
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

    public static func hexadecimalString(from data: some DataProtocol, options: HexadecimalEncodingOptions = []) -> String {
        hexadecimalString(from: Data(data), options: options)
    }

    public static func hexadecimalString(from bytes: some ContiguousBytes, options: HexadecimalEncodingOptions = []) -> String {
        bytes.withUnsafeBytes { buffer in
            hexadecimalString(from: Data(buffer), options: options)
        }
    }

    public static func data(fromHexadecimalString hexadecimalString: String) -> Data? {
        let bytes: UnfoldSequence<UInt8, String.Index> = sequence(state: hexadecimalString.startIndex) { startIndex in
            guard startIndex < hexadecimalString.endIndex else { return nil }
            let endIndex = hexadecimalString.index(startIndex, offsetBy: 2, limitedBy: hexadecimalString.endIndex) ?? hexadecimalString.endIndex
            defer { startIndex = endIndex }
            return UInt8(hexadecimalString[startIndex ..< endIndex], radix: 16)
        }
        return Data(bytes)
    }

    // MARK: - Base64-URL Support

    public static func base64URLString(from data: Data, options: Data.Base64EncodingOptions = []) -> String {
        data
            .base64EncodedString(options: options) // Regular base64 encoder
            .replacingOccurrences(of: "=", with: "") // Remove any trailing '='s
            .replacingOccurrences(of: "+", with: "-") // 62nd char of encoding
            .replacingOccurrences(of: "/", with: "_") // 63rd char of encoding
            .trimmingCharacters(in: .whitespaces)
    }

    public static func base64URLString(from data: some DataProtocol, options: Data.Base64EncodingOptions = []) -> String {
        base64URLString(from: Data(data), options: options)
    }

    public static func base64URLString(from bytes: some ContiguousBytes, options: Data.Base64EncodingOptions = []) -> String {
        bytes.withUnsafeBytes { buffer in
            base64URLString(from: Data(buffer), options: options)
        }
    }

    public static func data(fromBase64URLString base64URLString: String) -> Data? {
        let modifiedString = base64URLString
            .replacingOccurrences(of: "_", with: "/")
            .replacingOccurrences(of: "-", with: "+")

        let nbOfPaddedCharacters = modifiedString.count % 4
        let padding = switch nbOfPaddedCharacters {
        case 1:
            "==="
        case 2:
            "=="
        case 3:
            "="
        default: // Including 0
            ""
        }

        return Data(base64Encoded: "\(modifiedString)\(padding)")
    }
}
