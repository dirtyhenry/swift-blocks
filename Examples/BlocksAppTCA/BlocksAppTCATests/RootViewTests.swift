import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BlocksAppTCA

@MainActor
final class RootViewTests: XCTestCase {
    func testView() throws {
        let store = Store(initialState: RootFeature.State(status: .authorized)) {
            RootFeature()
        }

        let sut = RootView(store: store)
        assertSnapshot(matching: sut, as: .image)
    }

    func testView2() throws {
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
