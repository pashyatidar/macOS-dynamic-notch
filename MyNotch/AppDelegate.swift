import Cocoa
import SwiftUI
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var notchWindow: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        do {
            if SMAppService.mainApp.status == .notRegistered {
                try SMAppService.mainApp.register()
                print("Successfully registered to start at login!")
            }
        } catch {
            print("Failed to register for login: \(error)")
        }
        
        // THIS IS THE MAGIC KEY: Hides the Dock icon and makes it a system overlay
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
        
        // ADDED .fullScreenAuxiliary to ensure it stays visible on all desktop spaces
        notchWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        
        let contentView = NSHostingView(rootView: ContentView())
        notchWindow.contentView = contentView
        
        notchWindow.makeKeyAndOrderFront(nil)
    }
}
