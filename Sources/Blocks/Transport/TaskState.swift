public enum TaskState: Equatable {
    case notStarted
    // TODO: Add an optional cancellable to the running state?
    case running
    case completed
    case failed(errorDescription: String)
}

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
