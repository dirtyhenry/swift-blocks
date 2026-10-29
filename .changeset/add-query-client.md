---
"swift-blocks": minor
---

Add `QueryClient`. It fetches async data, keeps it in a cache and refreshes it in the background. It sends one request for concurrent queries with the same key, and retries the failed fetches.
