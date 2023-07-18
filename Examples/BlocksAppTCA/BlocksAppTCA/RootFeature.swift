import Blocks
import ComposableArchitecture
import Foundation
import UIKit

struct RootFeature: ReducerProtocol {
    struct State {
        @PresentationState var takePhoto: ImagePickerFeature.State?
        var latestPhoto: UIImage?
        var count: Int
    }

    enum Action {
        case takePhotoButtonTapped
        case usePhoto(PresentationAction<ImagePickerFeature.Action>)
        case incrementButtonTapped
    }

    var body: some ReducerProtocolOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .incrementButtonTapped:
                state.count += 1
                return .none

            case .takePhotoButtonTapped:
                print("takePhotoButtonTapped \(state.count)")
                state.takePhoto = ImagePickerFeature.State()
                state.count += 1
                return .none

            case let .usePhoto(.presented(.delegate(.usePhoto(newPhoto)))):
                print("usePhoto \(state.count)")
                state.latestPhoto = newPhoto
                state.takePhoto = nil
                state.count += 1
                return .none

            case .usePhoto(.presented(.delegate(.cancel))):
                state.takePhoto = nil
                return .none

            case .usePhoto:
                return .none
            }
        }
        .ifLet(\.$takePhoto, action: /Action.usePhoto) {
            ImagePickerFeature()
        }
    }
}

extension RootFeature.State: Equatable {}
extension RootFeature.Action: Equatable {}
