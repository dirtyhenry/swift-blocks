# Understanding QueryClient

How QueryClient works under the hood, why it exists, and how its design
compares to TanStack Query.

## Why a query layer?

Networking in Swift apps tends to follow one of two paths: either every call
site manages its own caching and loading state, or a heavyweight framework takes
over the entire data flow. QueryClient sits between these extremes — a
lightweight coordination layer that handles the repetitive parts (caching,
deduplication, retries, staleness tracking) while staying out of the way for
everything else.

The goal is not to replicate TanStack Query feature-for-feature. It is to bring
its most valuable ideas — stale-while-revalidate, request deduplication, and the
status/fetching separation — into Swift's concurrency model with zero
dependencies.

## Core ideas borrowed from TanStack Query

### Stale-while-revalidate

TanStack Query's signature behavior: return cached data instantly, then silently
refresh in the background. This eliminates loading spinners on repeat visits
while keeping data fresh.

QueryClient implements the same flow:

1. A `query(key:fetch:)` call checks the cache.
2. If cached data exists and `staleTime` hasn't elapsed, it returns immediately.
3. If cached data exists but is stale, it returns the stale data **and** kicks
   off a background refetch.
4. If no cached data exists, it awaits the fetch directly.

The `staleTime` and `cacheTime` options control this behavior. `staleTime`
determines how long data is considered fresh (default: 0, meaning immediately
stale). `cacheTime` determines how long data stays in the cache at all (default:
5 minutes).

### The status vs. isFetching separation

This is the insight that makes stale-while-revalidate work at the UI level. In
many networking layers, "loading" is a single boolean. TanStack Query splits
this into two dimensions:

- **status**: the overall state of the query (`.idle`, `.loading`, `.success`,
  `.error`)
- **isFetching**: whether a network request is currently in flight

A query can be `.success` with `isFetching == true` — it has data, but is
refreshing in the background. This lets UIs show content with a subtle refresh
indicator instead of replacing everything with a spinner.

`QueryState<T>` captures both dimensions, plus `isStale`, `data`, `error`, and
`dataUpdatedAt`.

### Request deduplication

If two parts of an app call `query(key:fetch:)` with the same key while a fetch
is already in flight, the second caller awaits the existing task instead of
starting a duplicate request. This falls out naturally from tracking in-flight
`Task` instances by key.

## Where QueryClient diverges from TanStack Query

### No reactivity layer

TanStack Query is built around observability — components subscribe to query
state and re-render automatically. QueryClient deliberately stops short of this.
It is an actor that you `await` on, not an observable object. Consumers can
build their own observation (via `AsyncStream`, Combine, `@Observable`, etc.) on
top of the `state(for:as:)` method.

This keeps the core free of any UI framework dependency and avoids opinionated
choices about state propagation.

### No mutations

TanStack Query bundles mutations alongside queries, with features like
optimistic updates and mutation lifecycle hooks. QueryClient handles queries
only. The `setQueryData(_:data:)` method enables manual cache writes (useful for
optimistic updates), but orchestrating mutations is left to the caller.

### No garbage collection

TanStack Query runs a background garbage collector that removes inactive queries
after their `cacheTime` expires. QueryClient uses lazy eviction instead: expired
entries are skipped on read and can be explicitly purged with `evictExpired()`.
This avoids background timers and keeps the actor model simple.

### No query observers or window focus refetching

Browser-specific features like refetching on window focus or network reconnect
are not included. These are application-level concerns on Apple platforms
(responding to `UIApplication.willEnterForegroundNotification`, `NWPathMonitor`,
etc.) and are better handled by the consuming app.

## Internal architecture

### Actors all the way down

Both `QueryCache` and `QueryClient` are actors. This provides thread safety
without locks and maps cleanly to Swift's structured concurrency model.

`QueryCache` owns a `Dictionary<AnyQueryKey, CacheEntry>`. It was deliberately
built with `Dictionary` rather than `NSCache` — `NSCache` is unavailable on
Linux and its eviction behavior is unpredictable. Query caches are
low-cardinality (hundreds of keys, not millions), so a dictionary with
time-based expiration is the right tool.

`QueryClient` owns the cache actor, a dictionary of in-flight `Task` instances,
and a dictionary of `QueryState` snapshots. All mutation happens through the
actor's serialized context.

### Type erasure

Cache entries store `any Sendable` values. This lets a single cache hold queries
of different types. `AnyQueryKey` type-erases the key for storage while
preserving the ability to unwrap back to the original type (e.g., for prefix
matching on `QueryKeyPath`).

### Retry mechanism

Retries are handled inside `QueryClient` rather than delegating to
`RetryTransport`. This is intentional — query-level retries apply to the fetch
closure regardless of whether it uses `Transport` underneath. The retry logic
mirrors `RetryTransport`'s approach (attempt counting with configurable delay)
but operates at a higher level.

### Transport bridge

The `query(key:options:transport:endpoint:)` extension connects QueryClient to
the existing `Transport` + `Endpoint` system. It's a thin wrapper that captures
`transport.load(endpoint)` as the fetch closure. This extension is excluded on
Linux (matching `Transport`'s own platform constraints).

## Key types at a glance

| Type | Role |
|------|------|
| `QueryKey` | Protocol for cache keys (`Hashable & Sendable`) |
| `QueryKeyPath` | Array-based hierarchical key with prefix matching |
| `AnyQueryKey` | Type-erased key for internal storage |
| `QueryState<T>` | Full state snapshot (status, data, error, fetching, stale) |
| `QueryOptions` | Configuration (staleTime, cacheTime, retryCount, retryDelay) |
| `QueryCache` | Actor-based dictionary cache with TTL |
| `QueryClient` | Coordinator actor (fetch, dedup, invalidate, retry) |
| `QueryError` | Error cases (cancelled, allRetriesFailed, typeMismatch) |
