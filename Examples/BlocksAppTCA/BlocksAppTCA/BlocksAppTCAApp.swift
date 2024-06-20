import ComposableArchitecture
import SwiftUI

@main
struct BlocksAppTCAApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(store: Store(initialState: RootFeature.State()) {
                RootFeature()
            })
        }
    }
}
