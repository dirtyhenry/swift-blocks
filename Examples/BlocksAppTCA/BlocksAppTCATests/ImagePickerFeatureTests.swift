import ComposableArchitecture
import XCTest

@testable import BlocksAppTCA

@MainActor
final class ImagePickerFeatureTests: XCTestCase {
    func testTakePhoto() async {
        let store = TestStore(initialState: ImagePickerFeature.State()) {
            ImagePickerFeature()
        }

        await store.send(.cancelButtonTapped) {
            $0.photo = nil
        }
    }
}
