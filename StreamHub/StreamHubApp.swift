import SwiftUI
import WebKit

@main
struct StreamHubApp: App {
    init() {
        // Configure HTTP cookie storage
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always
        
        // Configure WebKit data store for persistent sessions
        let dataStore = WKWebsiteDataStore.default()
        
        // Configure URL session for better network handling
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.waitsForConnectivity = true
        
        print("StreamHub app initialized with network configuration")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    // Additional setup when view appears
                    print("ContentView appeared")
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            // Menu commands
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
            }
        }
    }
}

extension Notification.Name {
    static let showAddPlatform = Notification.Name("showAddPlatform")
}
