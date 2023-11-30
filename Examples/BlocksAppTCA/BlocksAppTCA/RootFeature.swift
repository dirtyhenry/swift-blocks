import AVFoundation
import Blocks
import ComposableArchitecture
import Foundation
import UIKit

struct RootFeature: Reducer {
    struct State {
        @PresentationState var takePhoto: ImagePickerFeature.State?
        var latestPhoto: UIImage?
        var status: AVAuthorizationStatus

        init(latestPhoto: UIImage? = nil, status: AVAuthorizationStatus? = nil) {
            self.latestPhoto = latestPhoto
            self.status = status ?? AVCaptureDevice.authorizationStatus(for: .video)
        }
    }

    enum Action {
        case takePhotoButtonTapped
        case usePhoto(PresentationAction<ImagePickerFeature.Action>)
    }

    var body: some ReducerOf<Self> {
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
