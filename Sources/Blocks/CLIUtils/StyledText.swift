/// A color for ANSI terminal output.
public enum ANSIColor: Int, Sendable, CaseIterable {
    case black = 0
    case red = 1
    case green = 2
    case yellow = 3
    case blue = 4
    case magenta = 5
    case cyan = 6
    case white = 7

    /// The ANSI code for setting this as the foreground color (30–37).
    public var foregroundCode: Int {
        30 + rawValue
    }

    /// The ANSI code for setting this as the background color (40–47).
    public var backgroundCode: Int {
        40 + rawValue
    }
}

/// A text modifier for ANSI terminal output.
public enum ANSIModifier: Int, Sendable, Hashable {
    case bold = 1
    case dim = 2
    case italic = 3
    case underline = 4
    case inverse = 7
    case hidden = 8
    case strikethrough = 9

    /// The ANSI SGR code that enables this modifier.
    public var openCode: Int {
        rawValue
    }
}

/// A string annotated with ANSI color and modifier information.
///
/// `StyledText` stores a raw string alongside optional foreground/background colors
/// and a set of modifiers. Its `description` emits the appropriate ANSI escape
/// sequences, enabling composable colored output via Swift string interpolation:
///
/// ```swift
/// print("\("Hello".red.bold) \("world".blue)")
/// ```
public struct StyledText: Sendable, CustomStringConvertible {
    /// The undecorated text content.
    public let rawText: String

    /// The foreground color, if any.
    public var foreground: ANSIColor?

    /// The background color, if any.
    public var background: ANSIColor?

    /// The set of active text modifiers.
    public var modifiers: Set<ANSIModifier>

    /// Creates a new styled text value.
    public init(_ text: String, foreground: ANSIColor? = nil, background: ANSIColor? = nil, modifiers: Set<ANSIModifier> = []) {
        rawText = text
        self.foreground = foreground
        self.background = background
        self.modifiers = modifiers
    }

    /// The ANSI-escaped string representation.
    ///
    /// When no styling is applied, the raw text is returned as-is (no escape codes).
    public var description: String {
        let hasStyle = foreground != nil || background != nil || !modifiers.isEmpty
        guard hasStyle else { return rawText }

        var codes: [Int] = modifiers.sorted(by: { $0.openCode < $1.openCode }).map(\.openCode)
        if let fg = foreground { codes.append(fg.foregroundCode) }
        if let bg = background { codes.append(bg.backgroundCode) }

        let sequence = codes.map(String.init).joined(separator: ";")
        return "\u{001B}[\(sequence)m\(rawText)\u{001B}[0m"
    }

    // MARK: - Internal helpers

    func with(foreground color: ANSIColor) -> StyledText {
        StyledText(rawText, foreground: color, background: background, modifiers: modifiers)
    }

    func with(background color: ANSIColor) -> StyledText {
        StyledText(rawText, foreground: foreground, background: color, modifiers: modifiers)
    }

    func with(modifier: ANSIModifier) -> StyledText {
        StyledText(rawText, foreground: foreground, background: background, modifiers: modifiers.union([modifier]))
    }
}
