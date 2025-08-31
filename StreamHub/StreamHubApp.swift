import SwiftUI
import WebKit

@main
struct StreamHubApp: App {
    init() {
        // Enable persistent cookies and login sessions
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always
        
        // Configure WebKit settings
        let dataStore = WKWebsiteDataStore.default()
        dataStore.httpCookieStore.getAllCookies { cookies in
            // Cookies are persisted automatically
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
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
