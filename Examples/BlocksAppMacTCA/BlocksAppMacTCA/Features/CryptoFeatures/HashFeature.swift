import Blocks
import ComposableArchitecture
import Foundation

func doShit() async -> Bool {
    true
}

struct HashFeature: Reducer {
    struct State {
        var myVar1: Bool
        var myVar2: Bool
    }

    enum Action {
        case myAction1
        case myAction2(TaskResult<Bool>)
    }

    @Dependency(\.urlSession) var urlSession

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .myAction1:
            state.myVar1 = !state.myVar1
            return .none

        case let .myAction2(result):
            switch result {
            case .success:
                print("Success")
            case .failure:
                print("Todo")
            }
            return .none
        }
    }
}

extension HashFeature.State: Equatable {}
extension HashFeature.Action: Equatable {}
