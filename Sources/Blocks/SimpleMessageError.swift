import Foundation

public struct SimpleMessageError: Error {
    let message: String

    public init(message: String) {
        self.message = message
    }
}

extension SimpleMessageError: LocalizedError {
    public var errorDescription: String? {
        message
    }
}
