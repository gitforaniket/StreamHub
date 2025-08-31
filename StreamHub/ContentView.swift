import SwiftUI
import WebKit

// MARK: - Data Models
struct StreamingPlatform: Identifiable, Codable {
    let id = UUID()
    var name: String
    var url: String
    var icon: String
    var isCustom: Bool = false
}

// MARK: - WebView
struct WebView: NSViewRepresentable {
    let url: URL
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Enable DRM content
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsMagnification = true
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

// MARK: - Platform Manager
class PlatformManager: ObservableObject {
    @Published var platforms: [StreamingPlatform] = []
    
    init() {
        loadPlatforms()
    }
    
    func loadPlatforms() {
        // Load saved custom platforms
        if let data = UserDefaults.standard.data(forKey: "customPlatforms"),
           let customPlatforms = try? JSONDecoder().decode([StreamingPlatform].self, from: data) {
            platforms = defaultPlatforms() + customPlatforms
        } else {
            platforms = defaultPlatforms()
        }
    }
    
    func defaultPlatforms() -> [StreamingPlatform] {
        return [
            StreamingPlatform(name: "Prime Video", url: "https://www.primevideo.com", icon: "play.rectangle.fill"),
            StreamingPlatform(name: "Netflix", url: "https://www.netflix.com", icon: "tv.fill"),
            StreamingPlatform(name: "JioCinema", url: "https://www.jiocinema.com", icon: "play.circle.fill"),
            StreamingPlatform(name: "Disney+ Hotstar", url: "https://www.hotstar.com", icon: "star.fill"),
            StreamingPlatform(name: "Zee5", url: "https://www.zee5.com", icon: "play.square.fill"),
            StreamingPlatform(name: "SonyLiv", url: "https://www.sonyliv.com", icon: "rectangle.stack.fill"),
            StreamingPlatform(name: "Airtel XStream", url: "https://www.airtelxstream.in", icon: "antenna.radiowaves.left.and.right")
        ]
    }
    
    func addCustomPlatform(name: String, url: String) {
        var urlString = url
        if !url.hasPrefix("http://") && !url.hasPrefix("https://") {
            urlString = "https://\(url)"
        }
        
        let platform = StreamingPlatform(name: name, url: urlString, icon: "globe", isCustom: true)
        platforms.append(platform)
        saveCustomPlatforms()
    }
    
    func removePlatform(_ platform: StreamingPlatform) {
        platforms.removeAll { $0.id == platform.id }
        saveCustomPlatforms()
    }
    
    private func saveCustomPlatforms() {
        let customPlatforms = platforms.filter { $0.isCustom }
        if let data = try? JSONEncoder().encode(customPlatforms) {
            UserDefaults.standard.set(data, forKey: "customPlatforms")
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var platformManager = PlatformManager()
    @State private var selectedPlatform: StreamingPlatform?
    @State private var showingAddPlatform = false
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    @State private var currentURL: URL?
    @State private var showingSidebar = true
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // Platform List
                List(selection: $selectedPlatform) {
                    Section("Streaming Platforms") {
                        ForEach(platformManager.platforms) { platform in
                            HStack {
                                Image(systemName: platform.icon)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 20)
                                Text(platform.name)
                                    .lineLimit(1)
                                Spacer()
                                if platform.isCustom {
                                    Button(action: {
                                        platformManager.removePlatform(platform)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .imageScale(.small)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .tag(platform)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(SidebarListStyle())
                
                // Add Platform Button
                Divider()
                Button(action: { showingAddPlatform = true }) {
                    Label("Add Platform", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color.gray.opacity(0.1))
            }
            .frame(minWidth: 200, idealWidth: 250)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        withAnimation {
                            showingSidebar.toggle()
                        }
                    }) {
                        Image(systemName: "sidebar.left")
                    }
                }
            }
        } detail: {
            // Main Content
            if let platform = selectedPlatform,
               let url = URL(string: platform.url) {
                VStack(spacing: 0) {
                    // Navigation Bar
                    HStack(spacing: 16) {
                        Button(action: goBack) {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(!canGoBack)
                        
                        Button(action: goForward) {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(!canGoForward)
                        
                        Button(action: refresh) {
                            Image(systemName: "arrow.clockwise")
                        }
                        
                        Text(platform.name)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        
                        Button(action: enterFullScreen) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                    
                    // WebView
                    WebView(url: url,
                           canGoBack: $canGoBack,
                           canGoForward: $canGoForward,
                           isLoading: $isLoading)
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "play.tv")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("StreamHub")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Select a streaming platform from the sidebar")
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingAddPlatform) {
            AddPlatformView(platformManager: platformManager)
        }
    }
    
    func goBack() {
        NotificationCenter.default.post(name: .goBack, object: nil)
    }
    
    func goForward() {
        NotificationCenter.default.post(name: .goForward, object: nil)
    }
    
    func refresh() {
        NotificationCenter.default.post(name: .refresh, object: nil)
    }
    
    func enterFullScreen() {
        if let window = NSApplication.shared.keyWindow {
            window.toggleFullScreen(nil)
        }
    }
}

// MARK: - Add Platform View
struct AddPlatformView: View {
    @ObservedObject var platformManager: PlatformManager
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var url = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Custom Platform")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Platform Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Enter platform name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Platform URL")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Enter URL (e.g., www.example.com)", text: $url)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("Add Platform") {
                    if !name.isEmpty && !url.isEmpty {
                        platformManager.addCustomPlatform(name: name, url: url)
                        dismiss()
                    }
                }
                .keyboardShortcut(.return)
                .disabled(name.isEmpty || url.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 400)
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let goBack = Notification.Name("goBack")
    static let goForward = Notification.Name("goForward")
    static let refresh = Notification.Name("refresh")
}
