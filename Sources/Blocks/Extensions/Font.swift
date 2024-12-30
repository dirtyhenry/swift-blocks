#if canImport(UIKit)
import UIKit

/// Extension on UIFont providing a method to retrieve all available font names.
public extension UIFont {
    /// Returns an array containing all available font names.
    ///
    /// Font names are sorted alphabetically, with variations grouped under their family names.
    ///
    /// - Returns: An array of all available font names.
    static func allFontNames() -> [String] {
        familyNames.sorted()
            .map { UIFont.fontNames(forFamilyName: $0).sorted() }
            .flatMap(\.self)
    }
}
#endif

#if canImport(AppKit)
import AppKit

/// Extension on NSFont providing a method to retrieve all available font names.
public extension NSFont {
    /// Returns an array containing all available font names.
    ///
    /// Font names are sorted alphabetically.
    ///
    /// - Returns: An array of all available font names.
    static func allFontNames() -> [String] {
        NSFontManager.shared.availableFonts.sorted()
    }
}
#endif
