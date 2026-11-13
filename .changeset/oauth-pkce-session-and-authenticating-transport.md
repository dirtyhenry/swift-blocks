---
"swift-blocks": minor
---

Add `OAuthAuthorizationSession`, a PKCE authorization code flow that runs in `ASWebAuthenticationSession`, and `AuthenticatingTransport`, a transport that adds a bearer token to each request and refreshes it when it expires. Credentials live in an `OAuthCredentialsStore`, with in-memory and keychain implementations.
