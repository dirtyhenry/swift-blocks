# QueryClient

Fetch, cache, and revalidate async data with automatic deduplication and
retry.

## Overview

QueryClient is a lightweight caching layer for async data. It handles stale
data, deduplicates concurrent requests for the same key, and retries on failure
— so call sites stay focused on what to fetch, not how to manage it.

## Fetching data

Pass a key and an async closure. The client caches the result and returns it on
subsequent calls without re-fetching (subject to staleness rules).

```swift
let client = QueryClient()

let user: User = try await client.query(key: "current-user") {
    try await api.fetchCurrentUser()
}
```

The key can be any `String` or any type conforming to ``QueryKey``.

## Using hierarchical keys

Use ``QueryKeyPath`` when keys have a natural hierarchy. This enables
prefix-based invalidation later.

```swift
let post: Post = try await client.query(
    key: QueryKeyPath(["posts", postId])
) {
    try await api.fetchPost(id: postId)
}

let comments: [Comment] = try await client.query(
    key: QueryKeyPath(["posts", postId, "comments"])
) {
    try await api.fetchComments(postId: postId)
}
```

## Configuring staleness and cache lifetime

By default, data is immediately stale (`staleTime: 0`) and stays in the cache
for 5 minutes (`cacheTime: 300`). Override these per-client or per-query.

```swift
// Client-wide: data stays fresh for 30 seconds
let client = QueryClient(
    defaultOptions: QueryOptions(staleTime: 30, cacheTime: 600)
)

// Per-query override: this data stays fresh for 5 minutes
let config: Config = try await client.query(
    key: "app-config",
    options: QueryOptions(staleTime: 300)
) {
    try await api.fetchConfig()
}
```

When `staleTime` is 0, every call after the first returns cached data instantly
and triggers a background refetch — this is the stale-while-revalidate pattern.

## Prefetching data

Populate the cache ahead of time without waiting for the result.

```swift
await client.prefetch(key: "user-profile") {
    try await api.fetchProfile()
}
```

The data will be ready when `query(key:fetch:)` is called later.

## Reading and writing the cache manually

Write data directly into the cache (useful for optimistic updates):

```swift
await client.setQueryData("current-user", data: updatedUser)
```

Read cached data without triggering a fetch:

```swift
let cached = await client.getQueryData("current-user", as: User.self)
```

## Inspecting query state

Check the full state of a cached query, including whether it's currently
refetching in the background:

```swift
if let state = await client.state(for: "current-user", as: User.self) {
    switch state.status {
    case .success:
        // state.data is available
        // state.isFetching indicates a background refresh
        // state.isStale indicates the data is past its staleTime
    case .loading:
        // initial fetch in progress
    case .error:
        // state.error has details
    case .idle:
        // no fetch attempted yet
    }
}
```

## Invalidating cached data

Remove a specific key:

```swift
await client.invalidate("current-user")
```

Remove all keys matching a prefix (requires ``QueryKeyPath`` keys):

```swift
await client.invalidateMatching(prefix: QueryKeyPath(["posts"]))
```

Clear everything:

```swift
await client.invalidateAll()
```

Invalidation also cancels any in-flight fetch for the affected keys.

## Configuring retries

By default, failed fetches retry 3 times with exponential backoff (1s, 2s, 4s,
capped at 30s). Customize this per-client or per-query.

```swift
let client = QueryClient(
    defaultOptions: QueryOptions(
        retryCount: 2,
        retryDelay: { attempt in Double(attempt + 1) * 0.5 }
    )
)
```

Set `retryCount: 0` to disable retries entirely.

## Using with Transport and Endpoint

If you already use the ``Transport`` and ``Endpoint`` abstractions, a
convenience method bridges them directly:

```swift
let transport = StatusCodeCheckingTransport(
    wrapping: LoggingTransport(
        wrapping: URLSession.shared,
        subsystem: "com.example.app"
    )
)

let endpoint = Endpoint<User>(json: .get, url: userURL)

let user: User = try await client.query(
    key: "current-user",
    transport: transport,
    endpoint: endpoint
)
```

This is equivalent to calling `query(key:fetch:)` with
`transport.load(endpoint)` as the fetch closure.

> Note: The Transport bridge is not available on Linux.

## Topics

- ``QueryClient``
- ``QueryCache``
- ``QueryKey``
- ``QueryKeyPath``
- ``AnyQueryKey``
- ``QueryState``
- ``QueryStatus``
- ``QueryOptions``
- ``QueryError``
