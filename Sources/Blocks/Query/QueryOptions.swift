import Foundation

/// Configuration options for a query.
public struct QueryOptions: Sendable {
    /// How long data is considered fresh after fetching (in seconds).
    /// Default: 0 (immediately stale).
    public var staleTime: TimeInterval

    /// How long unused data remains in the cache (in seconds).
    /// Default: 300 (5 minutes).
    public var cacheTime: TimeInterval

    /// Maximum number of retry attempts on failure.
    /// Default: 3.
    public var retryCount: Int

    /// Computes the delay before retry attempt `n` (0-indexed).
    /// Default: exponential backoff capped at 30s.
    public var retryDelay: @Sendable (Int) -> TimeInterval

    public init(
        staleTime: TimeInterval = 0,
        cacheTime: TimeInterval = 300,
        retryCount: Int = 3,
        retryDelay: @Sendable @escaping (Int) -> TimeInterval = QueryOptions.exponentialBackoff
    ) {
        self.staleTime = staleTime
        self.cacheTime = cacheTime
        self.retryCount = retryCount
        self.retryDelay = retryDelay
    }

    /// Exponential backoff: 1s, 2s, 4s, 8s, ... capped at 30s.
    public static func exponentialBackoff(attempt: Int) -> TimeInterval {
        min(pow(2.0, Double(attempt)) * 1.0, 30.0)
    }
}
