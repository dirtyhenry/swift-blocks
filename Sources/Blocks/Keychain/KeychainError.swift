import Foundation

/// An error met when dealing with keychain items.
public enum KeychainError: Error {
    /// Properties of a keychain item could not be accessed.
    case unexpectedData
    
    /// A wrapper around a keychain error code that was not handled.
    case unhandledError(status: OSStatus)
}

extension KeychainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unexpectedData:
            return "Properties of the keychain item could not be retrieved."
        case let .unhandledError(status):
            if let errorMessage = SecCopyErrorMessageString(status, nil) {
                return errorMessage as String
            } else {
                return "Unhandled keychain error code: \(status)"
            }
        }
    }
}
