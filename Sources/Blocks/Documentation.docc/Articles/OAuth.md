# Sign in with OAuth 2.0 and PKCE

Authorize the app in a browser, then send requests with a bearer token that refreshes itself.

## Overview

Two types work together to talk to an OAuth 2.0 provider from an iOS or macOS app:

1. ``OAuthAuthorizationSession`` runs the authorization code flow with PKCE in a browser. It
   returns the authorization code and the PKCE code verifier.
2. ``AuthenticatingTransport`` adds the access token to each request. It refreshes the token
   before it expires, and one more time when the server says that the token is expired.

Both types are provider-agnostic. The app writes the provider-specific parts: the token exchange
and the refresh call.

## Authorize the app in a browser

Describe the authorization endpoint of the provider in an
``OAuthAuthorizationSession/Configuration``. Set `scopeParameterName` and `scopeSeparator` when
the provider does not use `scope` with spaces. For example, Slack reads user scopes from
`user_scope`, separated with commas.

```swift
let session = OAuthAuthorizationSession(configuration: .init(
    authorizationEndpoint: URL(string: "https://provider.tld/oauth/authorize")!,
    clientID: "my-client-id",
    scopes: ["users:read", "chat:write"],
    scopeParameterName: "user_scope",
    scopeSeparator: ",",
    redirectURI: URL(string: "myapp://oauth/callback")!
))
```

Call `authorize()` from the main actor. It builds the authorization URL with a random `state`
and a `S256` code challenge. It opens the URL in `ASWebAuthenticationSession`. It makes sure
that the callback has the same `state`. Then it returns the code and the code verifier.

```swift
do {
    let result = try await session.authorize()
    let credentials = try await exchange(code: result.code, codeVerifier: result.codeVerifier)
    try await store.save(credentials)
} catch OAuthAuthorizationError.cancelled {
    // The user closed the browser. Do nothing.
} catch {
    // Show the error.
}
```

The `exchange` function is yours. It posts the code and the code verifier to the token endpoint of
the provider. It returns ``OAuthCredentials``: the access token, its expiry date and the refresh
token.

To build the URL and read the callback without a browser, use
``OAuthAuthorizationSession/makeRequest(configuration:seeds:state:)`` and
``OAuthAuthorizationSession/parseCallback(url:expectedState:codeVerifier:)``.

## Keep the credentials

An ``OAuthCredentialsStore`` keeps the credentials between launches. Use
``KeychainOAuthCredentialsStore`` in an app. Use ``InMemoryOAuthCredentialsStore`` in tests and
previews.

```swift
let store = KeychainOAuthCredentialsStore(label: "Provider", account: "user-id")
```

## Send requests with a bearer token

Wrap a transport in an ``AuthenticatingTransport``. Give it the store and a closure that calls the
refresh endpoint of the provider.

```swift
let transport = AuthenticatingTransport(
    wrapping: URLSession.shared,
    store: store,
    refresh: { refreshToken in
        try await refresh(refreshToken: refreshToken)
    }
)

let user: User = try await transport.load(api.currentUser())
```

The transport does these steps for each request:

1. Loads the credentials from the store.
2. Refreshes the credentials when the access token expires in less than `leeway` seconds. The
   default leeway is 60 seconds.
3. Adds the `Authorization: Bearer <access token>` header and sends the request.
4. When the response says that the token is expired, refreshes the credentials and sends the
   request one more time.

Concurrent requests share one refresh. The transport saves the new credentials in the store after
each refresh.

### Detect an expired token

By default, the transport refreshes when the status code is 401. Some providers answer with a
status code 200 and an error in the body. Give an `isTokenExpired` closure for these providers:

```swift
let transport = AuthenticatingTransport(
    wrapping: URLSession.shared,
    store: store,
    isTokenExpired: { data, _ in
        let body = try? JSONDecoder().decode(SlackErrorBody.self, from: data)
        return body?.error == "token_expired"
    },
    refresh: refresh
)
```

### Ask the user to sign in again

When the refresh fails, the transport clears the store and throws
``ReauthenticationRequiredError``. The error also tells when the store is empty, or when the
credentials have no refresh token. Catch it to start a new ``OAuthAuthorizationSession``:

```swift
do {
    let user: User = try await transport.load(api.currentUser())
} catch is ReauthenticationRequiredError {
    try await signIn()
}
```

## Topics

### Authorization

- ``OAuthAuthorizationSession``
- ``OAuthAuthorizationError``
- ``PKCE``

### Requests

- ``AuthenticatingTransport``
- ``ReauthenticationRequiredError``

### Credentials

- ``OAuthCredentials``
- ``OAuthCredentialsStore``
- ``KeychainOAuthCredentialsStore``
- ``InMemoryOAuthCredentialsStore``
