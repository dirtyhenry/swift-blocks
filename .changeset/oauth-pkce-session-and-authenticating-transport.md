---
"swift-blocks": minor
---

Add `OAuthAuthorizationSession` and `AuthenticatingTransport`. The session runs a PKCE authorization code flow in `ASWebAuthenticationSession`. The transport adds a bearer token to each request and refreshes it when it expires. An `OAuthCredentialsStore` keeps the credentials, in memory or in the keychain.
