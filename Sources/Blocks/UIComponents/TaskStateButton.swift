#if canImport(SwiftUI)
import SwiftUI

/// A button view that reflects the current state of a task (`TaskState`).
///
/// `TaskStateButton` displays different UI elements depending on the state of the task: not started, running, completed,
/// or failed. It also allows for customization of titles and images depending on the task state.
///
/// Available for macOS 12.0+ and iOS 15.0+.
@available(macOS 12.0, *)
@available(iOS 15.0, *)
public struct TaskStateButton: View {
    /// The current state of the task, used to adjust the button's appearance and behavior.
    private var state: TaskState

    // MARK: - UI Properties

    /// The localized string key to display when the task is not running or completed.
    private var defaultTitleKey: LocalizedStringKey

    /// The localized string key to display when the task is running.
    private var runningTitleKey: LocalizedStringKey?

    /// The system image to display in the button.
    private var systemImage: String?

    // MARK: - Behavior

    /// The action to execute when the button is tapped.
    private var action: () -> Void

    /// If true, the button is disabled when the task is completed.
    private var disabledWhenCompleted: Bool

    // MARK: - VStack props

    /// The horizontal alignment of the button content.
    private var alignment: HorizontalAlignment

    /// Initializes a new `TaskStateButton`.
    ///
    /// - Parameters:
    ///   - defaultTitleKey: The title to display when the task is not running or completed.
    ///   - runningTitleKey: The title to display when the task is running. If `nil`, the `defaultTitleKey` will be used.
    ///   - systemImage: The system image to display in the button. If `nil`, no image is shown.
    ///   - action: The action to perform when the button is tapped. Default is an empty closure.
    ///   - disabledWhenCompleted: If true, the button is disabled when the task is completed. Default is `true`.
    ///   - state: The current state of the task.
    ///   - alignment: The alignment of the content within the `VStack`. Default is `.center`.
    public init(
        _ defaultTitleKey: LocalizedStringKey,
        runningTitleKey: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        action: @escaping (() -> Void) = {},
        disabledWhenCompleted: Bool = true,
        state: TaskState,
        alignment: HorizontalAlignment = .center
    ) {
        self.defaultTitleKey = defaultTitleKey
        self.runningTitleKey = runningTitleKey
        self.systemImage = systemImage
        self.action = action
        self.disabledWhenCompleted = disabledWhenCompleted
        self.state = state
        self.alignment = alignment
    }

    // MARK: - Body

    /// The content and behavior of the `TaskStateButton`.
    public var body: some View {
        VStack(alignment: alignment) {
            HStack {
                Button(
                    action: action,
                    label: {
                        switch state {
                        case .notStarted:
                            defaultState()
                        case .running:
                            HStack(spacing: 8) {
                                #if os(iOS)
                                ProgressView()
                                #endif
                                Text(runningTitleKey ?? defaultTitleKey)
                            }
                        case .completed:
                            if disabledWhenCompleted {
                                Label(defaultTitleKey, systemImage: "checkmark")
                            } else if systemImage == nil {
                                Text(defaultTitleKey)
                            } else {
                                Label(defaultTitleKey, systemImage: systemImage!)
                            }
                        case .failed:
                            defaultState()
                        }
                    }
                ).disabled(isDisabled())
            }

            if case let .failed(errorDescription: errorDescription) = state {
                if #available(iOS 17.0, *) {
                    Text(errorDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    Text(errorDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func defaultState() -> some View {
        Group {
            if systemImage == nil {
                Text(defaultTitleKey)
            } else {
                Label(defaultTitleKey, systemImage: systemImage!)
            }
        }
    }

    private func isDisabled() -> Bool {
        switch state {
        case .notStarted, .failed:
            false
        case .running:
            true
        case .completed:
            disabledWhenCompleted
        }
    }
}

#if DEBUG
#Preview("Not started") {
    if #available(iOS 15.0, macOS 12.0, *) {
        var taskState: TaskState = .notStarted
        return TaskStateButton(
            "Do this",
            runningTitleKey: "Doing this…",
            systemImage: "play",
            action: {
                print("TaskStateButton was tapped")
            },
            state: taskState
        )
        .buttonStyle(.bordered)
    } else {
        return Text("OS is not supported.")
    }
}

#Preview("Running") {
    if #available(iOS 15.0, macOS 12.0, *) {
        var taskState: TaskState = .running
        return TaskStateButton(
            "Do this",
            runningTitleKey: "Doing this…",
            systemImage: "play",
            action: {
                print("TaskStateButton was tapped")
            },
            state: taskState
        )
        .buttonStyle(.bordered)
    } else {
        return Text("OS is not supported.")
    }
}

#Preview("Completed") {
    if #available(iOS 15.0, macOS 12.0, *) {
        var taskState: TaskState = .completed
        return TaskStateButton(
            "Do this",
            runningTitleKey: "Doing this…",
            systemImage: "play",
            action: {
                print("TaskStateButton was tapped")
            },
            state: taskState
        )
        .buttonStyle(.bordered)
    } else {
        return Text("OS is not supported.")
    }
}

#Preview("Error") {
    if #available(iOS 15.0, macOS 12.0, *) {
        var taskState: TaskState = .failed(errorDescription: "Very long error message")
        return TaskStateButton(
            "Do this",
            runningTitleKey: "Doing this…",
            systemImage: "play",
            action: {
                print("TaskStateButton was tapped")
            },
            state: taskState,
            alignment: .leading
        )
        .buttonStyle(.bordered)
    } else {
        return Text("OS is not supported.")
    }
}
#endif
#endif
