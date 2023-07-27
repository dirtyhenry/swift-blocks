import Blocks
import ComposableArchitecture
import Foundation
import UIKit

struct ImagePickerFeature: ReducerProtocol {
    struct State {}

    enum Action {
        // MARK: - UI Interactions

        case cancelButtonTapped
        case usePhotoButtonTapped(UIImage)

        // MARK: - Delegation

        case delegate(Delegate)

        enum Delegate: Equatable {
            case usePhoto(UIImage)
        }
    }

    @Dependency(\.dismiss) var dismiss

    func reduce(into _: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .cancelButtonTapped:
            return .run { _ in await dismiss() }

        case let .usePhotoButtonTapped(newPhoto):
            return .run { send in
                await send(.delegate(.usePhoto(newPhoto)))
                await dismiss()
            }

        case .delegate:
            return .none
        }
    }
}

extension ImagePickerFeature.State: Equatable {}
extension ImagePickerFeature.Action: Equatable {}
