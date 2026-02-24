@testable import BlocksAppTCA
import ComposableArchitecture
import SnapshotTesting
import XCTest

final class ImagePickerViewTests: XCTestCase {
    func testView() {
        let store = Store(initialState: ImagePickerFeature.State()) {
            ImagePickerFeature()
        }

        let sut = ImagePickerView(store: store)
        assertSnapshot(matching: sut, as: .image)
    }
}
