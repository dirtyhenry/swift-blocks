import Foundation

public extension StringProtocol {
    /// Makes a safe filename from a title, for macOS and Obsidian.
    ///
    /// The filename is easy to read. This method keeps letters with accents, other Unicode letters, emoji and spaces.
    /// Use ``slugify()`` to make an identifier for a URL.
    ///
    /// This method does these steps:
    ///
    /// 1. It changes the text to Unicode normalization form C (NFC).
    /// 2. It replaces each character that is not safe with a space. These characters are `/`, `\`, `:`, `*`, `?`,
    ///    `"`, `<`, `>`, `|`, `#`, `^`, `[`, `]` and control characters.
    /// 3. It removes invisible characters, such as zero-width spaces and bidirectional controls.
    /// 4. It replaces each sequence of whitespace with one space.
    /// 5. It removes spaces and dots from the start and the end.
    /// 6. It keeps `maxLength` bytes or less. It does not cut a character in two. Then it does step 5 again.
    /// 7. If the result is empty, it returns `fallback`, after the same steps.
    ///
    /// ```swift
    /// "Swift: Codable / JSON #1".sanitizedFilename() // "Swift Codable JSON 1"
    /// "Café ☕️ notes".sanitizedFilename()            // "Café ☕️ notes"
    /// "  ...  ".sanitizedFilename()                 // "Untitled"
    /// ```
    ///
    /// - Parameters:
    ///   - maxLength: The maximum length of the result, in UTF-8 bytes. macOS accepts a filename of 255 bytes or less.
    ///     The default value, 200, keeps space for an extension such as `.md`.
    ///   - fallback: The value to return if no safe characters remain. If `fallback` also has no safe characters, the
    ///     method returns `Untitled`.
    /// - Returns: A filename without an extension. The result is never empty.
    func sanitizedFilename(maxLength: Int = 200, fallback: String = "Untitled") -> String {
        let sanitized = sanitize(String(self), maxLength: maxLength)
        guard sanitized.isEmpty else {
            return sanitized
        }
        let sanitizedFallback = sanitize(fallback, maxLength: maxLength)
        return sanitizedFallback.isEmpty ? "Untitled" : sanitizedFallback
    }
}

private func sanitize(_ string: String, maxLength: Int) -> String {
    let replaced = replacingUnsafeScalars(in: string.precomposedStringWithCanonicalMapping)
    let collapsed = replaced.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    return trimmingSpacesAndDots(utf8Prefix(trimmingSpacesAndDots(collapsed), maxLength: maxLength))
}

/// Replaces each forbidden scalar with a space, together with the marks that follow it, and removes invisible
/// scalars.
private func replacingUnsafeScalars(in string: String) -> String {
    var result = String.UnicodeScalarView()
    var isAfterForbiddenScalar = false
    for scalar in string.unicodeScalars {
        if isForbiddenInFilename(scalar) {
            result.append(" ")
            isAfterForbiddenScalar = true
        } else if isAfterForbiddenScalar, isMark(scalar) {
            continue
        } else {
            isAfterForbiddenScalar = false
            if !invisibleScalars.contains(scalar) {
                result.append(scalar)
            }
        }
    }
    return String(result)
}

private let forbiddenScalars: Set<Unicode.Scalar> = [
    "/", "\\", ":", "*", "?", "\"", "<", ">", "|", "#", "^", "[", "]"
]

/// Zero-width spaces, byte order marks and bidirectional controls. Zero-width joiners stay, because emoji use them.
private let invisibleScalars: Set<Unicode.Scalar> = [
    "\u{200B}", "\u{200E}", "\u{200F}", "\u{FEFF}",
    "\u{202A}", "\u{202B}", "\u{202C}", "\u{202D}", "\u{202E}",
    "\u{2066}", "\u{2067}", "\u{2068}", "\u{2069}"
]

private func isForbiddenInFilename(_ scalar: Unicode.Scalar) -> Bool {
    forbiddenScalars.contains(scalar) || scalar.properties.generalCategory == .control
}

/// Returns whether `scalar` changes the scalar before it: a combining mark or a variation selector.
private func isMark(_ scalar: Unicode.Scalar) -> Bool {
    switch scalar.properties.generalCategory {
    case .nonspacingMark, .spacingMark, .enclosingMark:
        true
    default:
        false
    }
}

/// Removes spaces and dots from the start and the end, together with the marks that are combined with them.
private func trimmingSpacesAndDots(_ string: String) -> String {
    let isSpaceOrDot: (Character) -> Bool = { character in
        character.unicodeScalars.first.map { $0 == "." || $0 == " " } ?? false
    }
    return String(string.drop(while: isSpaceOrDot).reversed().drop(while: isSpaceOrDot).reversed())
}

/// Returns the longest prefix of `string` that uses `maxLength` bytes or less, without a partial character.
private func utf8Prefix(_ string: String, maxLength: Int) -> String {
    var length = 0
    var result = ""
    for character in string {
        length += character.utf8.count
        guard length <= maxLength else {
            break
        }
        result.append(character)
    }
    return result
}
