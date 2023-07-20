import Blocks
import ComposableArchitecture
import Foundation
import UIKit

struct RootFeature: ReducerProtocol {
    struct State {
        @PresentationState var takePhoto: ImagePickerFeature.State?
        var latestPhoto: UIImage?
    }

    enum Action {
        case takePhotoButtonTapped
        case usePhoto(PresentationAction<ImagePickerFeature.Action>)
    }

    var body: some ReducerProtocolOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .takePhotoButtonTapped:
                state.takePhoto = ImagePickerFeature.State()
                return .none

            case let .usePhoto(.presented(.delegate(.usePhoto(newPhoto)))):
                state.latestPhoto = newPhoto
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
