public enum TaskState: Equatable {
    case notStarted
    // TODO: Add an optional cancellable to the running state?
    case running
    case completed
    case failed(errorDescription: String)
}

#if DEBUG
extension TaskState {
    func debugLoopNextState() -> TaskState {
        switch self {
        case .notStarted:
            .running
        case .running:
            .completed
        case .completed:
            .failed(errorDescription: "Dummy error")
        case .failed:
            .notStarted
        }
    }
}
#endif

extension TaskState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notStarted:
            "Not started"
        case .running:
            "Running"
        case .completed:
            "Completed"
        case .failed:
            "Failed"
        }
    }
}
