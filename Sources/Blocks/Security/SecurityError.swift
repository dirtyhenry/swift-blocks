#if canImport(Security)
import Foundation
import Security

/// An error met when dealing with keychain items.
public enum SecurityError: Error {
    /// Properties of a keychain item could not be accessed.
    case unexpectedData

    /// A wrapper around a keychain error code that was not handled.
    case unhandledError(status: OSStatus)
}

extension SecurityError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unexpectedData:
            "Properties of the keychain item could not be retrieved."
        case let .unhandledError(status):
            if let errorMessage = SecCopyErrorMessageString(status, nil) {
                errorMessage as String
            } else {
                "Unhandled keychain error code: \(status)"
            }
        }
    }
}
#endif
