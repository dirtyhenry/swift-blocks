# 🌐 Transport

This package contains powerful abstractions with a very small footprint to make
code sending HTTP requests easily testable and composable.

It builds on two major influences:

1. The [tiny-networking][1] library by [objc.io][2];
1. The talk [_You deserve nice things_][3] by [Soroush Khanlou][4].

## Overview

### Endpoints

Any API endpoint can be defined as an `Endpoint` struct, that can make code very
descriptive and to the point when dealing with JSON.

```swift
struct SignInEndpoint {
    struct Request: Codable {
        let login: String
        let password: String
    }

    struct Response: Codable {
        let token: String
    }
}

struct MyGreatAPI {
    func signIn(login: String, password: String) async throws -> Endpoint<SignInEndpoint.Response> {
        let url = try URL.myGreatAPIURLComponents(path: "/api/signIn")
        let request = try SignInEndpoint.Request(login: login, password: password)
        return Endpoint<FetchSaltEndpoint.Response>(json: .get, url: url, body: body)
    }
}
```

### Transports Toolbox

Endpoints are then carried over the network by some `Transport` instance, which
is an instance that deals with sending a `URLRequest` somewhere that will return
a response and some data asynchronously.

So while `Transport` is most of the time a simple abstraction of an `URLSession`
instance, it can also be a mock, a wrapper for other transports, etc.

For instance, during tests, to build a transport that will log requests and
responses, will snapshot results on disks, will throw if the response's status
code is in not in the 200 to 399 range, then, you could use:

```swift
StatusCodeCheckingTransport(
    wrapping: LoggingTransport(
        wrapping: URLSession.shared,
        subsystem: bundleId
    )
)
```

This template makes it very easy to compose features around a transport, share
code more easily and make tests easy to write.

### Network Logs

`LoggingTransport` writes one message for each request and one message for each
response. Each request gets a number. The response shows the same number.

```
→ #12 POST https://example.com/graphql (SignIn)
← #12 200 POST https://example.com/graphql · 181 ms · 1.2 KB
```

To read the logs, do these steps:

1. Open Console.app.
1. Choose **Action > Include Debug Messages**. Most messages use the `debug`
   level, and Console.app does not show them by default.
1. Filter on the subsystem of your `LoggingTransport`.
1. Select a message to see the body and the headers.

The log level shows the result. A 4xx status code uses the `error` level. A 5xx
status code or a thrown error uses the `fault` level. All other messages use
the `debug` level, cancellations included.

The system stores `error` and `fault` messages on disk. Thus, these messages
contain only the summary, with no query and no user info in the URL. A second
`debug` message, `↳ #12 details`, contains the full URL, the body and the
headers.

The logs hide the values of the `Authorization`, `Cookie` and `Set-Cookie`
headers. To hide other headers, use `LoggingTransport.Configuration`.

## Topics

- `Endpoint`
- `Transport`
- `LoggingTransport`
- `MockTransport`
- `StatusCodeCheckingTransport`
- `RetryTransport`
- `AuthenticatingTransport`
- `MultipartRequest`
- `TransportError`
- `WrongStatusCodeError`
- `URLRequestHeaderItem`
- `MailtoComponents`

[1]: https://github.com/objcio/tiny-networking
[2]: https://www.objc.io/
[3]: https://www.youtube.com/watch?v=CTZOjl6_NuY
[4]: https://www.khanlou.com/
