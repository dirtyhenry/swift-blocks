//
//  ImagePickerViewTests.swift
//  BlocksAppTCATests
//
//  Created by Mickaël Floc'hlay on 19/07/2023.
//

import XCTest
import SnapshotTesting
import ComposableArchitecture
import SwiftUI

@testable import BlocksAppTCA

@MainActor
final class RootViewTests: XCTestCase {
    func testView() throws {
        let store = Store(initialState: RootFeature.State()) {
            RootFeature()
        }
        
        let sut = RootView(store: store)
        assertSnapshot(matching: sut, as: .image)
    }
    
    func testView2() throws {
        guard let image = UIImage(named: "DummyImage", in: Bundle(for: ImagePickerFeatureTests.self), with: nil) else {
            fatalError("Could not load image in bundle.")
        }
        let store = Store(initialState: RootFeature.State(latestPhoto: image)) {
            RootFeature()
        }

        let sut = RootView(store: store)
        assertSnapshot(matching: sut, as: .image)
    }
}
