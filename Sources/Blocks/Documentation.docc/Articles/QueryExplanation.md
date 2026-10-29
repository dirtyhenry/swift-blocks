# The design of QueryClient

Learn how QueryClient works, why it exists and how it compares to TanStack Query.

## Why a query layer

In many Swift apps, each call site manages its own cache and its own loading state. Other apps
give all the data flow to a large framework. QueryClient is between these two approaches. It is a
small coordination layer for the repetitive parts: the cache, the deduplication, the retries and
the staleness. It does not control the rest of the app.

QueryClient does not copy all the features of TanStack Query. It takes the most useful ideas:
stale-while-revalidate, request deduplication and the separation of the status and the fetch
activity. It uses Swift concurrency and has no dependencies.

## Ideas from TanStack Query

### Stale-while-revalidate

TanStack Query returns the cached data immediately, then refreshes it in the background. Thus the
user does not see a loading indicator for data that the app already has, and the data stays
current.

QueryClient uses the same flow:

1. A `query(key:fetch:)` call examines the cache.
2. If the cache has data and the `staleTime` is not over, the call returns the data.
3. If the cache has data but the data is stale, the call returns the data **and** starts a fetch
   in the background.
4. If the cache has no data, the call waits for a fetch.

The `staleTime` and `cacheTime` options control this flow. `staleTime` is the time during which
the data is fresh. The default is 0: the data is stale immediately. `cacheTime` is the time during
which the cache keeps the data after the fetch. The default is 5 minutes.

### Status and fetch activity

In many network layers, one Boolean tells if the data loads. TanStack Query uses two values:

- **status**: the state of the query (`.idle`, `.loading`, `.success`, `.error`)
- **isFetching**: `true` while a request is in progress

A query can have the `.success` status while `isFetching` is `true`. It has data, and it refreshes
the data in the background. Thus the user interface can show the data with a small refresh
indicator, and not a full loading indicator.

`QueryState<T>` contains these two values, and also `isStale`, `data`, `error` and `dataUpdatedAt`.

### Request deduplication

Sometimes two parts of an app call `query(key:fetch:)` with the same key while a fetch is in
progress. Then the second caller waits for the result of the fetch in progress, and the client
does not send a second request.

If one caller is cancelled, only this caller stops. The fetch continues for the other callers.

## Differences from TanStack Query

### No reactivity layer

In TanStack Query, the components observe the state of the queries and update automatically.
QueryClient does not do this. It is an actor that you `await`, not an observable object. To observe
a query, build your own observation (with `AsyncStream`, Combine, `@Observable`, or other tools)
on `state(for:as:)`.

Thus the core does not depend on a user interface framework, and does not select a method to
send the state changes.

### No mutations

TanStack Query has mutations, with optimistic updates and lifecycle hooks. QueryClient has
queries only. Use `setQueryData(_:data:)` to write the cache, for example for an optimistic
update. The caller controls the mutations.

### No garbage collector

TanStack Query has a garbage collector that removes the inactive queries after their cache time.
QueryClient has no timer. When it stores data, the cache removes the expired entries. A read
ignores an expired entry. To remove the expired entries at a different time, call
`evictExpired()`.

### No observers and no refetch on window focus

QueryClient does not refetch when the window gets the focus or when the network connects again.
On Apple platforms, the app controls these events, for example with
`UIApplication.willEnterForegroundNotification` or `NWPathMonitor`.

## Internal architecture

### Actors

`QueryCache` and `QueryClient` are actors. Thus they are thread-safe without locks, and they
agree with the Swift concurrency model.

`QueryCache` contains a `Dictionary<AnyQueryKey, CacheEntry>`. It does not use `NSCache`, because
`NSCache` is not available on Linux and its eviction is not predictable. A query cache contains
hundreds of keys, not millions. Thus a dictionary with time-based expiration is sufficient.

`QueryClient` contains the cache actor, a dictionary of the fetches in progress and a dictionary
of `QueryState` values. All the changes occur in the serial context of the actor.

Each fetch in progress has an identifier. When a fetch completes after an invalidation, the
client ignores its result. Thus an old fetch cannot complete a newer fetch for the same key, and
cannot write to the cache.

### Type erasure

The cache entries contain `any Sendable` values. Thus one cache can contain queries of different
types. `AnyQueryKey` removes the type of the key for the storage. You can get the original key
again, for example to compare the prefix of a `QueryKeyPath`.

### Retries

`QueryClient` retries the fetches itself. It does not use `RetryTransport`, because the retries
apply to all fetch closures, also to closures that do not use `Transport`. The retries work as in
`RetryTransport`: the client counts the attempts and waits for a delay that you can configure.

### Transport bridge

The `query(key:options:transport:endpoint:)` extension connects QueryClient to `Transport` and
`Endpoint`. It uses `transport.load(endpoint)` as the fetch closure. This extension is not
available on Linux, as `Transport`.

## Key types

| Type | Role |
|------|------|
| `QueryKey` | Protocol for the cache keys (`Hashable & Sendable`) |
| `QueryKeyPath` | Hierarchical key, made of an array, with prefix matching |
| `AnyQueryKey` | Key without its type, for the storage |
| `QueryState<T>` | Full state (status, data, error, fetch activity, staleness) |
| `QueryOptions` | Configuration (staleTime, cacheTime, retryCount, retryDelay) |
| `QueryCache` | Dictionary cache with expiration, in an actor |
| `QueryClient` | Coordinator actor (fetch, deduplication, invalidation, retries) |
| `QueryError` | Errors (cancelled, allRetriesFailed, typeMismatch) |
