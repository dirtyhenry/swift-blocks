---
"swift-blocks": minor
---

Make the `LoggingTransport` logs easier to read in Console.app. The first line of each message shows the method, the
status code, the URL, the duration and the size. A number links each response to its request. The log level shows the
result of the request. Error and fault messages contain only the summary, with no query in the URL, because the system stores them on disk.
The transport also logs thrown errors, pretty-prints JSON bodies and hides sensitive headers.
Use the new `LoggingTransport.Configuration` to change the hidden headers.
