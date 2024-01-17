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
            return .running
        case .running:
            return .completed
        case .completed:
            return .failed(errorDescription: "Dummy error")
        case .failed:
            return .notStarted
        }
    }
}
#endif

extension TaskState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notStarted:
            return "Not started"
        case .running:
            return "Running"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }
}
