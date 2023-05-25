public enum TransportError: Error {
    case unexpectedNotHTTPResponse
    case unmetURLComponentsRequirements
    case unexpectedHTTPStatusCode(Int)
}
