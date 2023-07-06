import SwiftUI

@main
struct BlocksApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(model: WatchState())
        }
    }
}
