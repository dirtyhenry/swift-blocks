#if canImport(UIKit)
import UIKit

public extension UIFont {
    static func allFontNames() -> [String] {
        familyNames.sorted()
            .map { UIFont.fontNames(forFamilyName: $0).sorted() }
            .flatMap { $0 }
    }
}
#endif

#if canImport(AppKit)
import AppKit

public extension NSFont {
    static func allFontNames() -> [String] {
        NSFontManager.shared.availableFonts.sorted()
    }
}
#endif
