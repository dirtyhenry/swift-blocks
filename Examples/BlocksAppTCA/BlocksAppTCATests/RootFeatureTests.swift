@testable import BlocksAppTCA
import ComposableArchitecture
import XCTest

@MainActor
final class RootFeatureTests: XCTestCase {
    func testCancelTakePhoto() async {
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        }

        await store.send(.takePhotoButtonTapped) {
            $0.takePhoto = ImagePickerFeature.State()
        }

        await store.send(.usePhoto(.presented(.cancelButtonTapped)))
        await store.receive(.usePhoto(.dismiss)) {
            $0.takePhoto = nil
        }
    }

    func testTakePhoto() async {
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        }

        await store.send(.takePhotoButtonTapped) {
            $0.takePhoto = ImagePickerFeature.State()
        }

        guard let image = UIImage(named: "DummyImage", in: Bundle(for: ImagePickerFeatureTests.self), with: nil) else {
            fatalError("Could not load image in bundle.")
        }
        await store.send(.usePhoto(.presented(.usePhotoButtonTapped(image))))
        await store.receive(.usePhoto(.presented(.delegate(.usePhoto(image))))) {
            $0.latestPhoto = image
        }
        await store.receive(.usePhoto(.dismiss)) {
            $0.takePhoto = nil
        }
    }
}
