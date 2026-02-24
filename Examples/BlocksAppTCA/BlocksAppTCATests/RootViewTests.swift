@testable import BlocksAppTCA
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class RootViewTests: XCTestCase {
    func testView() {
        let store = Store(initialState: RootFeature.State(status: .authorized)) {
            RootFeature()
        }

        let sut = RootView(store: store)
        assertSnapshot(matching: sut, as: .image)
    }

    func testView2() {
        guard let image = UIImage(named: "DummyImage", in: Bundle(for: ImagePickerFeatureTests.self), with: nil) else {
            fatalError("Could not load image in bundle.")
        }
        let store = Store(initialState: RootFeature.State(latestPhoto: image, status: .authorized)) {
            RootFeature()
        }

        let sut = RootView(store: store)
        assertSnapshot(matching: sut, as: .image)
    }
}
