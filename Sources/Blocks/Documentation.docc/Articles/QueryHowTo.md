# Fetch and cache async data

Fetch async data, keep it in a cache and refresh it, with deduplication and retries.

## Overview

``QueryClient`` is a small cache layer for async data. It knows when the data is stale. It sends
one request for concurrent queries with the same key. It retries failed fetches. Thus the call
sites tell what to fetch, and the client manages the rest.

## Fetch data

Give a key and an async closure. The client keeps the result in its cache. The next calls return
the cached result and do not fetch again, until the data becomes stale.

```swift
let client = QueryClient()

let user: User = try await client.query(key: "current-user") {
    try await api.fetchCurrentUser()
}
```

The key can be a `String` or a value of a type that conforms to ``QueryKey``.

## Use hierarchical keys

Use ``QueryKeyPath`` if your keys have a hierarchy. Then you can invalidate all the keys that
start with a prefix.

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

## Configure the stale time and the cache time

- `staleTime` is the time during which the data is fresh. The default is 0: the data is stale
  immediately.
- `cacheTime` is the time during which the cache keeps the data after the fetch. The default is
  300 seconds (5 minutes).

Set the options for all the queries of a client, or for one query:

```swift
// For all the queries: the data is fresh for 30 seconds.
let client = QueryClient(
    defaultOptions: QueryOptions(staleTime: 30, cacheTime: 600)
)

// For one query: the data is fresh for 5 minutes.
let config: Config = try await client.query(
    key: "app-config",
    options: QueryOptions(staleTime: 300)
) {
    try await api.fetchConfig()
}
```

When the data is fresh, the client returns it and does not fetch. When the data is stale, the
client returns it immediately and fetches new data in the background. This pattern is
"stale-while-revalidate". When the cache time is over, the client removes the data. The next call
waits for a new fetch.

## Prefetch data

Put data in the cache before you need it. The method does not wait for the result.

```swift
await client.prefetch(key: "user-profile") {
    try await api.fetchProfile()
}
```

If the cache has fresh data for the key, the client does not fetch.

## Read and write the cache

Write data in the cache, for example for an optimistic update:

```swift
await client.setQueryData("current-user", data: updatedUser)
```

Read the cached data without a fetch:

```swift
let cached = await client.getQueryData("current-user", as: User.self)
```

## Examine the state of a query

Get the full state of a query. The state tells if a fetch is in progress in the background:

```swift
if let state = await client.state(for: "current-user", as: User.self) {
    switch state.status {
    case .success:
        // state.data contains the data.
        // state.isFetching is true during a background refresh.
        // state.isStale is true when the data is older than staleTime.
    case .loading:
        // The first fetch is in progress.
    case .error:
        // state.error contains the error.
    case .idle:
        // The client did not fetch yet.
    }
}
```

When the cache time is over, `state(for:as:)` returns `nil`, or a loading state if a fetch is in
progress.

## Invalidate cached data

Remove one key:

```swift
await client.invalidate("current-user")
```

Remove all the keys that start with a prefix. This operation applies to ``QueryKeyPath`` keys only:

```swift
await client.invalidateMatching(prefix: QueryKeyPath(["posts"]))
```

Remove all the keys:

```swift
await client.invalidateAll()
```

The invalidation also cancels the fetches in progress for these keys. The callers that wait for
these fetches get ``QueryError/cancelled``. The result of a cancelled fetch does not go into the
cache.

## Configure the retries

By default, the client retries a failed fetch 3 times. The delays increase exponentially: 1 s,
2 s, 4 s, with a maximum of 30 s. Set the retries for all the queries of a client, or for one
query:

```swift
let client = QueryClient(
    defaultOptions: QueryOptions(
        retryCount: 2,
        retryDelay: { attempt in Double(attempt + 1) * 0.5 }
    )
)
```

Set `retryCount` to 0 to disable the retries. When all the attempts fail, the client throws
``QueryError/allRetriesFailed(attempts:lastError:)``. Use `lastError` to get the error of the
last attempt.

## Use a transport and an endpoint

If you use ``Transport`` and ``Endpoint``, use the method that accepts them:

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

This method calls `query(key:fetch:)` with `transport.load(endpoint)` as the fetch closure.

> Note: This method is not available on Linux.

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
