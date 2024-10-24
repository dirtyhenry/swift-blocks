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

## Topics

- `Endpoint`
- `Transport`
- `LoggingTransport`
- `MockTransport`
- `StatusCodeCheckingTransport`
- `MultipartRequest`
- `TransportError`
- `WrongStatusCodeError`
- `URLRequestHeaderItem`
- `MailtoComponents`

[1]: https://github.com/objcio/tiny-networking
[2]: https://www.objc.io/
[3]: https://www.youtube.com/watch?v=CTZOjl6_NuY
[4]: https://www.khanlou.com/
