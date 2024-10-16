/// `TaskState` represents the possible states of a task.
///
/// A task can be in one of four states:
/// - `notStarted`: The task has not yet started.
/// - `running`: The task is currently running. (Future improvement: this state could optionally include a cancellable object.)
/// - `completed`: The task has completed successfully.
/// - `failed(errorDescription: String)`: The task has failed, and the reason for the failure is provided as a string.
public enum TaskState: Equatable {
    /// The task has not started yet.
    case notStarted

    /// The task is currently running.
    ///
    /// TODO: Add an optional cancellable to the running state to handle cancellation scenarios in the future.
    case running

    /// The task has completed successfully.
    case completed

    /// The task has failed, with an associated error description.
    ///
    /// - Parameter errorDescription: A string describing the reason for the failure.
    case failed(errorDescription: String)
}

extension TaskState: CustomStringConvertible {
    /// A textual representation of the task state.
    ///
    /// This computed property provides a string description of the current task state.
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

// MARK: - Usage Example

/// Example of how to use `TaskState`.
///
/// ```
/// var currentState: TaskState = .notStarted
/// print(currentState) // Prints "Not started"
///
/// currentState = .running
/// print(currentState) // Prints "Running"
///
/// currentState = .completed
/// print(currentState) // Prints "Completed"
///
/// currentState = .failed(errorDescription: "Network error")
/// print(currentState) // Prints "Failed"
/// ```
