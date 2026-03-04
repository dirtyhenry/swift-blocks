import Foundation

/// The status of a query in the cache.
public enum QueryStatus: Sendable {
    case idle
    case loading
    case success
    case error
}

/// The full state of a cached query.
///
/// The separation between `status` and `isFetching` is key:
/// a query can be `.success` with `isFetching == true` during a
/// stale-while-revalidate background refetch.
public struct QueryState<T: Sendable>: Sendable {
    public let status: QueryStatus
    public let data: T?
    public let error: (any Error)?
    public let dataUpdatedAt: Date?
    public let isFetching: Bool
    public let isStale: Bool

    public init(
        status: QueryStatus = .idle,
        data: T? = nil,
        error: (any Error)? = nil,
        dataUpdatedAt: Date? = nil,
        isFetching: Bool = false,
        isStale: Bool = false
    ) {
        self.status = status
        self.data = data
        self.error = error
        self.dataUpdatedAt = dataUpdatedAt
        self.isFetching = isFetching
        self.isStale = isStale
    }
}
