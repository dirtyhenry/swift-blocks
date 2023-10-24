import ComposableArchitecture
import SnapshotTesting
import XCTest

@testable import BlocksAppTCA

final class ImagePickerViewTests: XCTestCase {
    func testView() throws {
        let store = Store(initialState: ImagePickerFeature.State()) {
            ImagePickerFeature()
        }

        let sut = ImagePickerView(store: store)
        assertSnapshot(matching: sut, as: .image)
    }
}
