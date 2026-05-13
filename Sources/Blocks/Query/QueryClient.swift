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
    private var inFlight: [AnyQueryKey: InFlightFetch] = [:]
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

                startBackgroundRefetchIfIdle(key: anyKey, options: opts, fetch: fetch)
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
        startBackgroundRefetchIfIdle(key: anyKey, options: opts, fetch: fetch)
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
        cancelInFlight(anyKey)
        states.removeValue(forKey: anyKey)
    }

    /// Invalidates all keys whose `QueryKeyPath` starts with the given prefix.
    public func invalidateMatching(prefix: QueryKeyPath) async {
        await cache.removeMatching(prefix: prefix)
        let matching = Set(inFlight.keys).union(states.keys).filter { key in
            guard let path = key.unwrap(as: QueryKeyPath.self) else { return false }
            return path.hasPrefix(prefix)
        }
        for key in matching {
            cancelInFlight(key)
            states.removeValue(forKey: key)
        }
    }

    /// Invalidates all cached data.
    public func invalidateAll() async {
        await cache.clear()
        for key in Array(inFlight.keys) {
            cancelInFlight(key)
        }
        states.removeAll()
    }

    // MARK: - Private

    private func executeFetch<T: Sendable>(
        key: AnyQueryKey,
        options: QueryOptions,
        fetch: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        if inFlight[key] == nil {
            states[key] = QueryState<T>(status: .loading, isFetching: true)
            startFetch(key: key, options: options, fetch: fetch)
        }

        let result = try await awaitFetch(key: key)

        guard let typed = result as? T else {
            throw QueryError.typeMismatch(
                expected: String(describing: T.self),
                actual: String(describing: type(of: result))
            )
        }
        return typed
    }

    private func startBackgroundRefetchIfIdle<T: Sendable>(
        key: AnyQueryKey,
        options: QueryOptions,
        fetch: @Sendable @escaping () async throws -> T
    ) {
        guard inFlight[key] == nil else { return }

        if let existing = states[key] as? QueryState<T> {
            states[key] = QueryState<T>(
                status: existing.status,
                data: existing.data,
                dataUpdatedAt: existing.dataUpdatedAt,
                isFetching: true,
                isStale: true
            )
        } else {
            states[key] = QueryState<T>(status: .loading, isFetching: true)
        }

        startFetch(key: key, options: options, fetch: fetch)
    }

    private func startFetch<T: Sendable>(
        key: AnyQueryKey,
        options: QueryOptions,
        fetch: @Sendable @escaping () async throws -> T
    ) {
        let fetchTask = Task<any Sendable, any Error> {
            try await fetchWithRetry(options: options, fetch: fetch)
        }
        inFlight[key] = InFlightFetch(task: fetchTask)

        Task { [weak self] in
            let result: Result<any Sendable, any Error>
            do {
                let value = try await fetchTask.value
                result = .success(value)
            } catch {
                result = .failure(error)
            }
            await self?.settleFetch(key: key, result: result, options: options, cacheType: T.self)
        }
    }

    private func awaitFetch(key: AnyQueryKey) async throws -> any Sendable {
        let waiterId = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                registerWaiter(key: key, id: waiterId, continuation: continuation)
            }
        } onCancel: {
            Task { [weak self] in
                await self?.removeWaiter(key: key, id: waiterId)
            }
        }
    }

    private func registerWaiter(
        key: AnyQueryKey,
        id: UUID,
        continuation: CheckedContinuation<any Sendable, any Error>
    ) {
        guard let fetch = inFlight[key] else {
            // The fetch settled between the caller observing it and registering. This is
            // possible because the broadcaster runs on the actor and may have completed
            // before this method ran. Surface as cancellation; the caller can retry.
            continuation.resume(throwing: QueryError.cancelled)
            return
        }
        fetch.waiters[id] = continuation
    }

    private func removeWaiter(key: AnyQueryKey, id: UUID) {
        guard let fetch = inFlight[key] else { return }
        guard let continuation = fetch.waiters.removeValue(forKey: id) else { return }
        continuation.resume(throwing: QueryError.cancelled)
        // Intentionally do not cancel `fetch.task` — other waiters or background completion may still need the result.
    }

    private func cancelInFlight(_ key: AnyQueryKey) {
        guard let fetch = inFlight.removeValue(forKey: key) else { return }
        fetch.task.cancel()
        for (_, continuation) in fetch.waiters {
            continuation.resume(throwing: QueryError.cancelled)
        }
    }

    private func settleFetch<T: Sendable>(
        key: AnyQueryKey,
        result: Result<any Sendable, any Error>,
        options: QueryOptions,
        cacheType _: T.Type
    ) async {
        guard let fetch = inFlight.removeValue(forKey: key) else {
            // Already invalidated. Waiters were resumed there.
            return
        }
        let waiters = fetch.waiters

        switch result {
        case let .success(value):
            if let typed = value as? T {
                await cache.set(key, data: typed, staleTime: options.staleTime, cacheTime: options.cacheTime)
                states[key] = QueryState<T>(
                    status: .success,
                    data: typed,
                    dataUpdatedAt: Date(),
                    isStale: false
                )
            }
        case let .failure(error):
            if let existing = states[key] as? QueryState<T>, existing.data != nil {
                // Preserve existing data on background-refetch failure.
                states[key] = QueryState<T>(
                    status: existing.status,
                    data: existing.data,
                    error: error,
                    dataUpdatedAt: existing.dataUpdatedAt,
                    isFetching: false,
                    isStale: true
                )
            } else {
                states[key] = QueryState<T>(status: .error, error: error)
            }
        }

        for (_, continuation) in waiters {
            continuation.resume(with: result)
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
                    do {
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    } catch is CancellationError {
                        throw QueryError.cancelled
                    }
                }
            }
        }
        throw QueryError.allRetriesFailed(attempts: retries + 1, lastError: lastError!)
    }
}

// MARK: - InFlightFetch

@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
private final class InFlightFetch {
    let task: Task<any Sendable, any Error>
    var waiters: [UUID: CheckedContinuation<any Sendable, any Error>] = [:]

    init(task: Task<any Sendable, any Error>) {
        self.task = task
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
