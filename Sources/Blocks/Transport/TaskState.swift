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
