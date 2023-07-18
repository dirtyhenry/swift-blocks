import Blocks
import ComposableArchitecture
import Foundation
import UIKit

struct ImagePickerFeature: ReducerProtocol {
    struct State {
        var photo: UIImage?
    }

    enum Action {
        // MARK: - UI Interactions

        case cancelButtonTapped
        case usePhotoButtonTapped(UIImage)

        // MARK: - Delegation

        case delegate(Delegate)

        enum Delegate: Equatable {
            case cancel
            case usePhoto(UIImage)
        }
    }

    // @Dependency(\.dismiss) var dismiss

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .cancelButtonTapped:
            return .send(.delegate(.cancel))
//            return .run { _ in await dismiss() }

        case let .usePhotoButtonTapped(newPhoto):
            state.photo = newPhoto
            return .send(.delegate(.usePhoto(newPhoto)))
//            return .run { send in
//                await send(.delegate(.usePhoto(newPhoto)))
//                await dismiss()
//            }

        case .delegate:
            return .none
        }
    }
}

extension ImagePickerFeature.State: Equatable {}
extension ImagePickerFeature.Action: Equatable {}
