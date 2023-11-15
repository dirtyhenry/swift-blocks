import SwiftUI

@available(macOS 12.0, *)
@available(iOS 15.0, *)
public struct TaskStateButton: View {
    // MARK: - UI Properties

    private var defaultTitleKey: LocalizedStringKey
    private var runningTitleKey: LocalizedStringKey?
    private var systemImage: String?
    private var isPrimary: Bool

    // MARK: - Behavior

    private var action: () -> Void
    private var disabledWhenCompleted: Bool

    private var state: Binding<TaskState>

    public init(
        _ defaultTitleKey: LocalizedStringKey,
        runningTitleKey: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        isPrimary: Bool = false,
        action: @escaping () -> Void,
        disabledWhenCompleted: Bool = true,
        state: Binding<TaskState>
    ) {
        self.defaultTitleKey = defaultTitleKey
        self.runningTitleKey = runningTitleKey
        self.systemImage = systemImage
        self.isPrimary = isPrimary
        self.action = action
        self.disabledWhenCompleted = disabledWhenCompleted
        self.state = state
    }

    public var body: some View {
        VStack {
            HStack {
                Button(action: action, label: {
                    switch state.wrappedValue {
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

            if case let .failed(errorDescription: errorDescription) = state.wrappedValue {
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
        switch state.wrappedValue {
        case .notStarted, .failed:
            return false
        case .running:
            return true
        case .completed:
            return disabledWhenCompleted
        }
    }
}

#if DEBUG
    @available(macOS 12.0, *)
    @available(iOS 14.0, *)
    struct TaskStateButtonPreviews: PreviewProvider {
        struct PreviewWrapper: View {
            @State var task1State: TaskState = .notStarted
            @State var task2State: TaskState = .notStarted

            var body: some View {
                VStack {
                    Text("Buttons")
                    if #available(iOS 15.0, *) {
                        TaskStateButton(
                            "Do this",
                            runningTitleKey: "Doing this…",
                            systemImage: "play",
                            action: {
                                task1State = task1State.debugLoopNextState()
                            },
                            state: $task1State
                        )
                        .buttonStyle(.bordered)
                    }

                    if #available(iOS 15.0, *) {
                        TaskStateButton(
                            "Do that",
                            isPrimary: true,
                            action: {
                                task2State = task2State.debugLoopNextState()
                            },
                            disabledWhenCompleted: false,
                            state: $task2State
                        )
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }

        static var previews: some View {
            PreviewWrapper()
                .padding(32)
        }
    }
#endif
