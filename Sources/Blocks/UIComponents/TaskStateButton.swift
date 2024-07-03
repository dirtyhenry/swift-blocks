#if canImport(SwiftUI)
import SwiftUI

@available(macOS 12.0, *)
@available(iOS 15.0, *)
public struct TaskStateButton: View {
    // MARK: - UI Properties

    private var defaultTitleKey: LocalizedStringKey
    private var runningTitleKey: LocalizedStringKey?
    private var systemImage: String?

    // MARK: - Behavior

    private var action: () -> Void
    private var disabledWhenCompleted: Bool

    // MARK: - VStack props

    private var alignment: HorizontalAlignment

    private var state: TaskState

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

    public var body: some View {
        VStack(alignment: alignment) {
            HStack {
                Button(action: action, label: {
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
                }).disabled(isDisabled())
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
