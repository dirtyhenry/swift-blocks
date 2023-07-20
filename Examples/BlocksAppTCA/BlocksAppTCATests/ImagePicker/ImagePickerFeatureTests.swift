import ComposableArchitecture
import XCTest

@testable import BlocksAppTCA

@MainActor
final class ImagePickerFeatureTests: XCTestCase {
    func testCancelTakePhoto() async {
        let isDismissInvoked = LockIsolated(false)
        let store = TestStore(initialState: ImagePickerFeature.State()) {
            ImagePickerFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect({
                isDismissInvoked.setValue(true)
            })
        }

        await store.send(.cancelButtonTapped)
        XCTAssertEqual(isDismissInvoked.value, true)
    }
    
    func testTakePhoto() async {
        let isDismissInvoked = LockIsolated(false)
        let store = TestStore(initialState: ImagePickerFeature.State()) {
            ImagePickerFeature()
        } withDependencies: {
            $0.dismiss = DismissEffect({
                isDismissInvoked.setValue(true)
            })
        }
        
        guard let image = UIImage(named: "DummyImage", in: Bundle(for: ImagePickerFeatureTests.self), with: nil) else {
            fatalError("Could not load image in bundle.")
        }

        await store.send(.usePhotoButtonTapped(image))
        await store.receive(.delegate(.usePhoto(image)))
        XCTAssertEqual(isDismissInvoked.value, true)
    }
}
