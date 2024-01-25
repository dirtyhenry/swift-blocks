#if os(macOS)
import AppKit
#endif
#if os(iOS)
import UIKit
import UniformTypeIdentifiers
#endif
import Foundation

/// A utility struct for interacting with the system pasteboard.
public struct Pasteboard {
    /// Initializes a new instance of `Pasteboard`.
    public init() {}

    /// Copies the specified text to the system pasteboard.
    /// - Parameter text: The text to be copied.
    public func copy(text: String) {
        #if os(macOS)

        // MARK: - macOS

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if !pasteboard.setString(text, forType: .string) {
            fatalError("Copying failed")
        }
        #endif

        #if os(iOS)

        // MARK: - iOS

        let pasteboard = UIPasteboard.general
        if #available(iOS 14.0, *) {
            pasteboard.setValue(text, forPasteboardType: UTType.utf8PlainText.identifier)
        } else {
            pasteboard.setValue(text, forPasteboardType: "public.text")
        }
        #endif
    }
}
