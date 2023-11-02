# Networking

This package contains powerful abstractions with a very small footprint to make code sending HTTP requests
easily testable and composable.

It builds on two major influences:

1. The tiny networking library by Chris Eidhof and Florian Zigler;
1. The talk *You deserve nice things* by Soroush Kanlou.

## Overview

### Endpoints

Any API endpoint can be defined as an `Endpoint` struct, that can make code very descriptive and to the point
when dealing with JSON.

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

### Transports

Endpoints are then carried over the network by some `Transport` instance, which is an instance that deals
with sending a `URLRequest` somewhere that will return a response and some data asynchronously.

So while `Transport` is most of the time a simple abstraction of an `URLSession` instance, it can also be
a mock, a wrapper for other transports, etc.

For instance, during tests, to build a transport that will log requests and responses, will snapshot results 
on disks, will throw if the response's status code is in not in the 200 to 399 range, then, you could use:

```swift
SnapshottingTransport(
    wrapping: LogginTransport(
       wrapping: StatusCodeCheckingTransport(
            wrapping: URLSession.shared
        )
    )
)
```

This template makes it very easy to compose features around a transport, share code more easily and make 
tests easy to write.

## Topics

- ``Transport``
- ``StatusCodeCheckingTransport``
- ``MultipartRequest``
- ``TransportError``