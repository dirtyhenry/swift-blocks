import Foundation

public struct SimpleError: Error {
    let message: String

    public init(message: String) {
        self.message = message
    }
}

extension SimpleError: LocalizedError {
    public var errorDescription: String? {
        message
    }
}
