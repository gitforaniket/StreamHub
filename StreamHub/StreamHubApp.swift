import SwiftUI
import WebKit

@main
struct StreamHubApp: App {
    init() {
        // Configure HTTP cookie storage for persistent sessions
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always
        
        // Configure WebKit data store for persistent sessions
        let dataStore = WKWebsiteDataStore.default()
        
        // Enhanced URL session configuration for better streaming compatibility
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 120.0
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        
        // Configure cache policy for better streaming performance
        config.requestCachePolicy = .useProtocolCachePolicy
        config.urlCache = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 200 * 1024 * 1024, diskPath: nil)
        
        print("StreamHub app initialized with enhanced network configuration and fullscreen video support")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    // Additional setup when view appears
                    print("ContentView appeared - Enhanced fullscreen video support enabled")
                    
                    // Configure window appearance for better video playback
                    if let window = NSApplication.shared.windows.first {
                        window.backgroundColor = NSColor.black
                        window.titlebarAppearsTransparent = false
                        window.isMovableByWindowBackground = true
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1200, height: 800)
        .commands {
            // Enhanced menu commands
            CommandGroup(replacing: .newItem) {
                Button("Add Platform...") {
                    NotificationCenter.default.post(name: .showAddPlatform, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandMenu("Navigation") {
                Button("Back") {
                    NotificationCenter.default.post(name: .goBack, object: nil)
                }
                .keyboardShortcut("[", modifiers: .command)
                
                Button("Forward") {
                    NotificationCenter.default.post(name: .goForward, object: nil)
                }
                .keyboardShortcut("]", modifiers: .command)
                
                Button("Refresh") {
                    NotificationCenter.default.post(name: .refresh, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Divider()
                
                Button("Reload Page") {
                    NotificationCenter.default.post(name: .refresh, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
            
            CommandMenu("View") {
                Button("Toggle App Fullscreen") {
                    if let window = NSApplication.shared.keyWindow {
                        window.toggleFullScreen(nil)
                    }
                }
                .keyboardShortcut("f", modifiers: [.command, .control])
                
                Button("Enter Video Fullscreen") {
                    // This will trigger fullscreen on the currently focused video element
                    NotificationCenter.default.post(name: .triggerVideoFullscreen, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
                
                Divider()
                
                Button("Show Developer Tools") {
                    NotificationCenter.default.post(name: .showDevTools, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
            }
            
            CommandMenu("Window") {
                Button("Minimize") {
                    NSApplication.shared.keyWindow?.miniaturize(nil)
                }
                .keyboardShortcut("m", modifiers: .command)
                
                Button("Zoom") {
                    NSApplication.shared.keyWindow?.zoom(nil)
                }
            }
            
            // Help menu with additional info
            CommandGroup(replacing: .help) {
                Button("StreamHub Help") {
                    if let url = URL(string: "https://github.com/gitforaniket/StreamHub") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Button("Report Issue") {
                    if let url = URL(string: "https://github.com/gitforaniket/StreamHub/issues") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Divider()
                
                Button("Keyboard Shortcuts") {
                    showKeyboardShortcuts()
                }
            }
        }
    }
    
    private func showKeyboardShortcuts() {
        let alert = NSAlert()
        alert.messageText = "Keyboard Shortcuts"
        alert.informativeText = """
        Navigation:
        ⌘+[ - Go Back
        ⌘+] - Go Forward
        ⌘+R - Refresh Page
        
        Window:
        ⌘+N - Add New Platform
        ⌘+F - Enter Video Fullscreen
        ⌘+⌃+F - Toggle App Fullscreen
        ⌘+M - Minimize Window
        
        Developer:
        ⌘+⌥+I - Show Developer Tools
        """
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Enhanced Notifications
extension Notification.Name {
    static let showAddPlatform = Notification.Name("showAddPlatform")
    static let triggerVideoFullscreen = Notification.Name("triggerVideoFullscreen")
    static let showDevTools = Notification.Name("showDevTools")
}
