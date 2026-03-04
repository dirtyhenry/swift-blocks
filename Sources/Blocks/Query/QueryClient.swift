import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A query client that coordinates caching, deduplication, and fetching.
///
/// Inspired by TanStack Query's core model:
/// - Stale-while-revalidate: returns cached data immediately, refetches in background
/// - Request deduplication: concurrent calls for the same key share a single in-flight fetch
/// - Fine-grained state: separates `status` from `isFetching` for flexible UI binding
///
/// ```swift
/// let client = QueryClient()
/// let user: User = try await client.query(key: "user-123") {
///     try await api.fetchUser(id: "123")
/// }
/// ```
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
public actor QueryClient {
    private let cache: QueryCache
    private let defaultOptions: QueryOptions
    private var inFlightTasks: [AnyQueryKey: Task<any Sendable, any Error>] = [:]
    private var states: [AnyQueryKey: any Sendable] = [:]

    public init(cache: QueryCache = QueryCache(), defaultOptions: QueryOptions = QueryOptions()) {
        self.cache = cache
        self.defaultOptions = defaultOptions
    }

    /// Fetches data for a key, using the cache when fresh and deduplicating in-flight requests.
    ///
    /// - Parameters:
    ///   - key: The query key.
    ///   - options: Override options for this query. Falls back to client defaults.
    ///   - fetch: The async function that produces the data.
    /// - Returns: The fetched or cached data.
    public func query<T: Sendable>(
        key: some QueryKey,
        options: QueryOptions? = nil,
        fetch: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        let opts = options ?? defaultOptions
        let anyKey = AnyQueryKey(key)

        if let entry = await cache.getEntry(anyKey) {
            if let data = entry.data as? T {
                if !entry.isStale(at: Date()) {
                    return data
                }

                triggerBackgroundRefetch(key: anyKey, options: opts, fetch: fetch)
                return data
            }
        }

        return try await executeFetch(key: anyKey, options: opts, fetch: fetch)
    }

    /// Prefetches data into the cache without returning it.
    public func prefetch(
        key: some QueryKey,
        options: QueryOptions? = nil,
        fetch: @Sendable @escaping () async throws -> some Sendable
    ) {
        let opts = options ?? defaultOptions
        let anyKey = AnyQueryKey(key)
        triggerBackgroundRefetch(key: anyKey, options: opts, fetch: fetch)
    }

    /// Manually writes data into the cache for a key.
    public func setQueryData<T: Sendable>(_ key: some QueryKey, data: T, options: QueryOptions? = nil) async {
        let opts = options ?? defaultOptions
        let anyKey = AnyQueryKey(key)
        await cache.set(anyKey, data: data, staleTime: opts.staleTime, cacheTime: opts.cacheTime)
        states[anyKey] = QueryState<T>(
            status: .success,
            data: data,
            dataUpdatedAt: Date(),
            isStale: false
        )
    }

    /// Reads cached data for a key without triggering a fetch.
    public func getQueryData<T: Sendable>(_ key: some QueryKey, as _: T.Type) async -> T? {
        await cache.get(AnyQueryKey(key), as: T.self)
    }

    /// Returns the current `QueryState` for a key, if one exists.
    public func state<T: Sendable>(for key: some QueryKey, as _: T.Type) -> QueryState<T>? {
        states[AnyQueryKey(key)] as? QueryState<T>
    }

    // MARK: - Invalidation

    /// Invalidates a specific key, removing it from cache and cancelling any in-flight fetch.
    public func invalidate(_ key: some QueryKey) async {
        let anyKey = AnyQueryKey(key)
        await cache.remove(anyKey)
        inFlightTasks[anyKey]?.cancel()
        inFlightTasks.removeValue(forKey: anyKey)
        states.removeValue(forKey: anyKey)
    }

    /// Invalidates all keys whose `QueryKeyPath` starts with the given prefix.
    public func invalidateMatching(prefix: QueryKeyPath) async {
        await cache.removeMatching(prefix: prefix)
        for key in inFlightTasks.keys {
            if let path = key.unwrap(as: QueryKeyPath.self), path.hasPrefix(prefix) {
                inFlightTasks[key]?.cancel()
                inFlightTasks.removeValue(forKey: key)
                states.removeValue(forKey: key)
            }
        }
    }

    /// Invalidates all cached data.
    public func invalidateAll() async {
        await cache.clear()
        for task in inFlightTasks.values {
            task.cancel()
        }
        inFlightTasks.removeAll()
        states.removeAll()
    }

    // MARK: - Private

    private func executeFetch<T: Sendable>(
        key: AnyQueryKey,
        options: QueryOptions,
        fetch: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        if let existingTask = inFlightTasks[key] {
            let result = try await existingTask.value
            guard let typed = result as? T else {
                throw QueryError.typeMismatch(
                    expected: String(describing: T.self),
                    actual: String(describing: type(of: result))
                )
            }
            return typed
        }

        states[key] = QueryState<T>(status: .loading, isFetching: true)

        let task = Task<any Sendable, any Error> {
            try await fetchWithRetry(options: options, fetch: fetch)
        }
        inFlightTasks[key] = task

        do {
            let result = try await task.value
            inFlightTasks.removeValue(forKey: key)

            guard let typed = result as? T else {
                throw QueryError.typeMismatch(
                    expected: String(describing: T.self),
                    actual: String(describing: type(of: result))
                )
            }

            await cache.set(key, data: typed, staleTime: options.staleTime, cacheTime: options.cacheTime)
            states[key] = QueryState<T>(
                status: .success,
                data: typed,
                dataUpdatedAt: Date(),
                isStale: false
            )
            return typed
        } catch {
            inFlightTasks.removeValue(forKey: key)
            states[key] = QueryState<T>(status: .error, error: error)
            throw error
        }
    }

    private nonisolated func fetchWithRetry<T: Sendable>(
        options: QueryOptions,
        fetch: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        var lastError: (any Error)?
        let retries = max(0, options.retryCount)
        for attempt in 0 ... retries {
            do {
                try Task.checkCancellation()
                return try await fetch()
            } catch is CancellationError {
                throw QueryError.cancelled
            } catch {
                lastError = error
                if attempt < retries {
                    let delay = max(0, options.retryDelay(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        throw QueryError.allRetriesFailed(attempts: retries + 1, lastError: lastError!)
    }

    private func triggerBackgroundRefetch<T: Sendable>(
        key: AnyQueryKey,
        options: QueryOptions,
        fetch: @Sendable @escaping () async throws -> T
    ) {
        guard inFlightTasks[key] == nil else { return }

        if let existing = states[key] as? QueryState<T> {
            states[key] = QueryState<T>(
                status: existing.status,
                data: existing.data,
                dataUpdatedAt: existing.dataUpdatedAt,
                isFetching: true,
                isStale: true
            )
        }

        let task = Task<any Sendable, any Error> { [weak self] in
            do {
                let result = try await self?.fetchWithRetry(options: options, fetch: fetch) as T?
                guard let self, let result else { return () as any Sendable }
                await completeBackgroundRefetch(key: key, data: result, options: options)
                return result as any Sendable
            } catch {
                await self?.cleanUpFailedBackgroundRefetch(key: key, as: T.self, error: error)
                throw error
            }
        }
        inFlightTasks[key] = task
    }

    private func cleanUpFailedBackgroundRefetch<T: Sendable>(key: AnyQueryKey, as _: T.Type, error: any Error) {
        inFlightTasks.removeValue(forKey: key)

        // Reset isFetching so the UI doesn't show a stuck spinner.
        // Preserve existing data so stale-while-revalidate still works.
        if let existing = states[key] as? QueryState<T> {
            states[key] = QueryState<T>(
                status: existing.data != nil ? existing.status : .error,
                data: existing.data,
                error: error,
                dataUpdatedAt: existing.dataUpdatedAt,
                isFetching: false,
                isStale: true
            )
        }
    }

    private func completeBackgroundRefetch<T: Sendable>(key: AnyQueryKey, data: T, options: QueryOptions) async {
        await cache.set(key, data: data, staleTime: options.staleTime, cacheTime: options.cacheTime)
        inFlightTasks.removeValue(forKey: key)
        states[key] = QueryState<T>(
            status: .success,
            data: data,
            dataUpdatedAt: Date(),
            isStale: false
        )
    }
}

// MARK: - Transport + Endpoint Bridge

#if os(Linux)
// Transport bridge not available on Linux
#else
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
public extension QueryClient {
    /// Fetches data for a key using a `Transport` and `Endpoint`.
    func query<A: Sendable>(
        key: some QueryKey,
        options: QueryOptions? = nil,
        transport: Transport,
        endpoint: Endpoint<A>
    ) async throws -> A {
        try await query(key: key, options: options) {
            try await transport.load(endpoint)
        }
    }
}
#endif
