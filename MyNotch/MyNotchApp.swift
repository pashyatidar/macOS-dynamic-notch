import SwiftUI

@main
struct MyNotchApp: App {
    /// Connects the custom window logic to the application lifecycle.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        /// Uses Settings to prevent the application from opening a standard window on launch.
        Settings {
            EmptyView()
        }
    }
}
