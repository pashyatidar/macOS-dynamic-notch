import Cocoa
import SwiftUI
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var notchWindow: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        /// Configures the application as an accessory to hide the Dock icon and behave as a system overlay.
        NSApp.setActivationPolicy(.accessory)
        
        guard let screen = NSScreen.main else { return }
        let screenWidth = screen.frame.width
        let screenHeight = screen.frame.height
        
        let notchWidth: CGFloat = 350
        let notchHeight: CGFloat = 200
        
        notchWindow = NSWindow(
            contentRect: NSRect(x: (screenWidth / 2) - (notchWidth / 2), y: screenHeight - notchHeight, width: notchWidth, height: notchHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        notchWindow.isOpaque = false
        notchWindow.backgroundColor = .clear
        notchWindow.level = .statusBar
        
        /// Configures the window collection behavior to ensure it stays visible on all desktop spaces, including full screen auxiliary spaces.
        notchWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        
        let contentView = NSHostingView(rootView: ContentView())
        notchWindow.contentView = contentView
        
        notchWindow.makeKeyAndOrderFront(nil)
    }
}
