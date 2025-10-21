import SwiftUI

@main
struct StreamSwipeApp: App {
    @StateObject private var discoveryViewModel = ShowDiscoveryViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(discoveryViewModel)
        }
    }
}
