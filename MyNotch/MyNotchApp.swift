import SwiftUI

@main
struct MyNotchApp: App {
    // This connects our custom window logic
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We use Settings to prevent Xcode from opening a normal, boring window
        Settings {
            EmptyView()
        }
    }
}
