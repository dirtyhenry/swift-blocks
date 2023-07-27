//
//  ImagePickerViewTests.swift
//  BlocksAppTCATests
//
//  Created by Mickaël Floc'hlay on 19/07/2023.
//

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
