import Foundation

/// Writes a flat `Encodable` value as a YAML front matter block.
///
/// Markdown tools such as Jekyll and Obsidian read this block at the start of a file.
///
/// ```swift
/// struct Note: Encodable {
///     let title: String
///     let date: PlainDate
///     let tags: [String]
///     let draft: Bool
/// }
///
/// let note = Note(title: #"Hello: "World""#, date: "2026-10-27", tags: ["swift", "yaml"], draft: false)
/// let frontMatter = try FrontMatterEncoder().encode(note)
/// // ---
/// // title: "Hello: \"World\""
/// // date: 2026-10-27
/// // tags: ["swift", "yaml"]
/// // draft: false
/// // ---
/// ```
///
/// The encoder writes each string as a JSON string. A JSON string is also a correct YAML string. For this reason,
/// quotation marks, colons, `#`, hyphens, line breaks and emoji do not cause errors in the block.
public struct FrontMatterEncoder: Sendable {
    public init() {}

    /// Writes `value` as a front matter block.
    ///
    /// The block starts and ends with a `---` line. A line break follows the last line.
    ///
    /// - Parameter value: A value with keys, such as a struct. Its properties must be flat.
    /// - Returns: The front matter block.
    /// - Throws: A ``FrontMatterEncodingError`` if the value does not have keys, if a value is not flat, or if a key
    ///   occurs two times.
    public func encode(_ value: some Encodable) throws -> String {
        let encoder = TopLevelEncoder()
        try value.encode(to: encoder)
        if let error = encoder.error {
            throw error
        }
        return (["---"] + encoder.lines + ["---"]).joined(separator: "\n") + "\n"
    }
}

/// The errors thrown by ``FrontMatterEncoder``.
public enum FrontMatterEncodingError: Error, Equatable, Sendable {
    /// The value does not have keys. For example, it is an array.
    case notKeyed
    /// The value for `key` is not flat. It is not a string, an integer, a Boolean, a ``PlainDate``, a `URL`, or an
    /// array of these types.
    case unsupportedValue(key: String)
    /// The value writes the same key two times. This can occur only with a custom `encode(to:)` implementation.
    case duplicateKey(String)
}

extension FrontMatterEncodingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notKeyed:
            "The value does not have keys. Use a value with keys, such as a struct."
        case let .unsupportedValue(key):
            "The value for \"\(key)\" is not flat. Use a string, an integer, a Boolean, a date, a URL, "
                + "or an array of these types."
        case let .duplicateKey(key):
            "The key \"\(key)\" occurs two times. Write each key one time only."
        }
    }
}

// MARK: - Top-level encoder

/// Collects one `key: value` line for each property of the encoded value.
private final class TopLevelEncoder: Encoder {
    var codingPath: [any CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]
    var lines: [String] = []
    var keys: Set<String> = []
    var error: FrontMatterEncodingError?

    func container<Key: CodingKey>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(LineContainer(encoder: self))
    }

    func unkeyedContainer() -> any UnkeyedEncodingContainer {
        error = error ?? .notKeyed
        return RejectingUnkeyedContainer()
    }

    func singleValueContainer() -> any SingleValueEncodingContainer {
        error = error ?? .notKeyed
        return ValueEncoder()
    }
}

private struct LineContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let encoder: TopLevelEncoder
    var codingPath: [any CodingKey] {
        []
    }

    mutating func encodeNil(forKey _: Key) throws {}

    mutating func encode(_ value: some Encodable, forKey key: Key) throws {
        guard let scalar = try render(value) else {
            throw FrontMatterEncodingError.unsupportedValue(key: key.stringValue)
        }
        guard encoder.keys.insert(key.stringValue).inserted else {
            throw FrontMatterEncodingError.duplicateKey(key.stringValue)
        }
        encoder.lines.append("\(yamlKey(key.stringValue)): \(scalar)")
    }

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy _: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> {
        reject(key)
        return KeyedEncodingContainer(RejectingKeyedContainer())
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> any UnkeyedEncodingContainer {
        reject(key)
        return RejectingUnkeyedContainer()
    }

    mutating func superEncoder() -> any Encoder {
        encoder
    }

    mutating func superEncoder(forKey key: Key) -> any Encoder {
        reject(key)
        return ValueEncoder()
    }

    private func reject(_ key: Key) {
        encoder.error = encoder.error ?? .unsupportedValue(key: key.stringValue)
    }
}

// MARK: - Values

/// Returns the YAML text for a flat value, or `nil` if the value is not flat.
private func render(_ value: some Encodable) throws -> String? {
    switch value {
    case let date as PlainDate:
        return date.description
    case let url as URL:
        return try jsonString(url.absoluteString)
    default:
        let encoder = ValueEncoder()
        try value.encode(to: encoder)
        return encoder.isRejected ? nil : encoder.output
    }
}

/// Renders a scalar, or an array of scalars as a YAML flow sequence.
private final class ValueEncoder: Encoder, SingleValueEncodingContainer {
    var codingPath: [any CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]
    var output: String?
    var isRejected = false

    func container<Key: CodingKey>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> {
        isRejected = true
        return KeyedEncodingContainer(RejectingKeyedContainer())
    }

    func unkeyedContainer() -> any UnkeyedEncodingContainer {
        let container = SequenceContainer(encoder: self)
        output = "[]"
        return container
    }

    func singleValueContainer() -> any SingleValueEncodingContainer {
        self
    }

    func encodeNil() throws {
        isRejected = true
    }

    func encode(_ value: Bool) throws {
        output = value ? "true" : "false"
    }

    func encode(_ value: String) throws {
        output = try jsonString(value)
    }

    func encode(_ value: Int) throws {
        output = String(value)
    }

    func encode(_ value: Int8) throws {
        output = String(value)
    }

    func encode(_ value: Int16) throws {
        output = String(value)
    }

    func encode(_ value: Int32) throws {
        output = String(value)
    }

    func encode(_ value: Int64) throws {
        output = String(value)
    }

    func encode(_ value: UInt) throws {
        output = String(value)
    }

    func encode(_ value: UInt8) throws {
        output = String(value)
    }

    func encode(_ value: UInt16) throws {
        output = String(value)
    }

    func encode(_ value: UInt32) throws {
        output = String(value)
    }

    func encode(_ value: UInt64) throws {
        output = String(value)
    }

    func encode(_: Double) throws {
        isRejected = true
    }

    func encode(_: Float) throws {
        isRejected = true
    }

    func encode(_ value: some Encodable) throws {
        guard let scalar = try render(value), !scalar.hasPrefix("[") else {
            isRejected = true
            return
        }
        output = scalar
    }
}

/// Collects array elements, which must be scalars, into a YAML flow sequence.
private struct SequenceContainer: UnkeyedEncodingContainer {
    let encoder: ValueEncoder
    var codingPath: [any CodingKey] {
        []
    }

    private var elements: [String] = []
    var count: Int {
        elements.count
    }

    init(encoder: ValueEncoder) {
        self.encoder = encoder
    }

    mutating func encodeNil() throws {
        encoder.isRejected = true
    }

    mutating func encode(_ value: some Encodable) throws {
        let element = ValueEncoder()
        try element.encode(value)
        guard !element.isRejected, let scalar = element.output else {
            encoder.isRejected = true
            return
        }
        elements.append(scalar)
        encoder.output = "[" + elements.joined(separator: ", ") + "]"
    }

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy _: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey> {
        encoder.isRejected = true
        return KeyedEncodingContainer(RejectingKeyedContainer())
    }

    mutating func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer {
        encoder.isRejected = true
        return RejectingUnkeyedContainer()
    }

    mutating func superEncoder() -> any Encoder {
        encoder.isRejected = true
        return ValueEncoder()
    }
}

// MARK: - Rejecting containers

/// Accepts and discards values written below a value that was already rejected.
private struct RejectingKeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    var codingPath: [any CodingKey] {
        []
    }

    mutating func encodeNil(forKey _: Key) throws {}
    mutating func encode(_: some Encodable, forKey _: Key) throws {}

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy _: NestedKey.Type,
        forKey _: Key
    ) -> KeyedEncodingContainer<NestedKey> {
        KeyedEncodingContainer(RejectingKeyedContainer<NestedKey>())
    }

    mutating func nestedUnkeyedContainer(forKey _: Key) -> any UnkeyedEncodingContainer {
        RejectingUnkeyedContainer()
    }

    mutating func superEncoder() -> any Encoder {
        ValueEncoder()
    }

    mutating func superEncoder(forKey _: Key) -> any Encoder {
        ValueEncoder()
    }
}

/// Accepts and discards values written below a value that was already rejected.
private struct RejectingUnkeyedContainer: UnkeyedEncodingContainer {
    var codingPath: [any CodingKey] {
        []
    }

    var count: Int {
        0
    }

    mutating func encodeNil() throws {}
    mutating func encode(_: some Encodable) throws {}

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy _: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey> {
        KeyedEncodingContainer(RejectingKeyedContainer<NestedKey>())
    }

    mutating func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer {
        RejectingUnkeyedContainer()
    }

    mutating func superEncoder() -> any Encoder {
        ValueEncoder()
    }
}

// MARK: - Formatting

/// Encodes `string` as a JSON string literal, which is also a valid double-quoted YAML scalar.
private func jsonString(_ string: String) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.withoutEscapingSlashes]
    let data = try encoder.encode(string)
    // swiftlint:disable:next optional_data_string_conversion
    let json = String(decoding: data, as: UTF8.self)
    // JSON escapes only C0 control characters. YAML also does not accept DEL, C1 control characters and the
    // noncharacters U+FFFE and U+FFFF, and folds U+0085 (NEL) into a space.
    return json.unicodeScalars.reduce(into: "") { result, scalar in
        if (0x7F ... 0x9F).contains(scalar.value) || scalar.value == 0xFFFE || scalar.value == 0xFFFF {
            result += String(format: "\\u%04X", scalar.value)
        } else {
            result.unicodeScalars.append(scalar)
        }
    }
}

/// Returns `key` as is when YAML reads it as a plain key, or JSON-encoded otherwise.
private func yamlKey(_ key: String) -> String {
    // YAML 1.1 parsers read these plain words as Booleans or null.
    let reservedWords: Set = ["y", "n", "yes", "no", "true", "false", "on", "off", "null"]
    let isPlain = key.first.map { $0.isLetter || $0 == "_" } == true
        && key.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_" || $0 == "-") }
        && !reservedWords.contains(key.lowercased())
    return isPlain ? key : (try? jsonString(key)) ?? key
}
