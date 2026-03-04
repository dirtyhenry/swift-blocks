import Foundation

/// Errors specific to the query system.
public enum QueryError: Error, LocalizedError {
    /// The fetch function was cancelled.
    case cancelled
    /// All retry attempts exhausted.
    case allRetriesFailed(attempts: Int, lastError: any Error)
    /// A type mismatch when reading cached data.
    case typeMismatch(expected: String, actual: String)

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            "Query was cancelled."
        case let .allRetriesFailed(attempts, lastError):
            "Query failed after \(attempts) attempts. Last error: \(lastError.localizedDescription)"
        case let .typeMismatch(expected, actual):
            "Query cache type mismatch: expected \(expected), got \(actual)."
        }
    }
}
