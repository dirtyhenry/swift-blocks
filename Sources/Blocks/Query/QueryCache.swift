import Foundation

/// An actor-based cache for query results with time-based expiration.
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
public actor QueryCache {
    struct CacheEntry {
        let data: any Sendable
        let createdAt: Date
        let cacheTime: TimeInterval
        let staleTime: TimeInterval

        var expiresAt: Date {
            createdAt.addingTimeInterval(cacheTime)
        }

        var staleAt: Date {
            createdAt.addingTimeInterval(staleTime)
        }

        func isExpired(at now: Date) -> Bool {
            now >= expiresAt
        }

        func isStale(at now: Date) -> Bool {
            now >= staleAt
        }
    }

    private var entries: [AnyQueryKey: CacheEntry] = [:]

    public init() {}

    /// Returns the cached data for a key, or nil if absent or expired.
    public func get<T: Sendable>(_ key: AnyQueryKey, as _: T.Type) -> T? {
        guard let entry = entries[key], !entry.isExpired(at: Date()) else {
            return nil
        }
        return entry.data as? T
    }

    /// Returns full cache entry metadata for a key, or nil if absent or expired.
    func getEntry(_ key: AnyQueryKey) -> CacheEntry? {
        guard let entry = entries[key], !entry.isExpired(at: Date()) else {
            return nil
        }
        return entry
    }

    /// Stores data in the cache.
    public func set(_ key: AnyQueryKey, data: some Sendable, staleTime: TimeInterval, cacheTime: TimeInterval) {
        entries[key] = CacheEntry(
            data: data,
            createdAt: Date(),
            cacheTime: cacheTime,
            staleTime: staleTime
        )
    }

    /// Removes a specific key from the cache.
    public func remove(_ key: AnyQueryKey) {
        entries.removeValue(forKey: key)
    }

    /// Removes all keys whose underlying `QueryKeyPath` has the given prefix.
    public func removeMatching(prefix: QueryKeyPath) {
        for key in entries.keys {
            if let path = key.unwrap(as: QueryKeyPath.self), path.hasPrefix(prefix) {
                entries.removeValue(forKey: key)
            }
        }
    }

    /// Removes all expired entries.
    public func evictExpired() {
        let now = Date()
        entries = entries.filter { !$0.value.isExpired(at: now) }
    }

    /// Removes all entries.
    public func clear() {
        entries.removeAll()
    }

    /// The number of entries currently in the cache.
    public var count: Int {
        entries.count
    }
}
