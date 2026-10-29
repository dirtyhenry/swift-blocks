import Foundation

/// A type that can serve as a query cache key.
public protocol QueryKey: Hashable, Sendable {}

extension String: QueryKey {}

/// A hierarchical query key built from an array of hashable components.
///
/// Supports prefix-based matching for pattern invalidation:
/// ```swift
/// let key = QueryKeyPath(["posts", "123", "comments"])
/// key.hasPrefix(QueryKeyPath(["posts", "123"])) // true
/// key.hasPrefix(QueryKeyPath(["users"]))         // false
/// ```
public struct QueryKeyPath: QueryKey, ExpressibleByArrayLiteral, @unchecked Sendable {
    public let components: [AnyHashable]

    public init(_ components: [AnyHashable]) {
        self.components = components
    }

    public init(arrayLiteral elements: AnyHashable...) {
        components = elements
    }

    public func hasPrefix(_ prefix: QueryKeyPath) -> Bool {
        guard prefix.components.count <= components.count else { return false }
        return zip(components, prefix.components).allSatisfy { $0 == $1 }
    }
}

/// A type-erased wrapper around any `QueryKey`, used for internal cache storage.
///
/// Uses `@unchecked Sendable` because the underlying `AnyHashable` wraps
/// a value that conforms to `QueryKey` (which requires `Sendable`).
public struct AnyQueryKey: Hashable, @unchecked Sendable {
    private let base: AnyHashable

    public init(_ key: some QueryKey) {
        base = AnyHashable(key)
    }

    /// Returns the underlying key cast to `K`, or nil if the type doesn't match.
    public func unwrap<K: QueryKey>(as _: K.Type) -> K? {
        base.base as? K
    }
}
