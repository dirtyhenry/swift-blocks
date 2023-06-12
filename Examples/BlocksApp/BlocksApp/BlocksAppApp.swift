import SwiftUI

@main
struct BlocksAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(model: WatchState())
        }
    }
}
