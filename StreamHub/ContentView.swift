import SwiftUI
import WebKit

// MARK: - Data Models
struct StreamingPlatform: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var url: String
    var icon: String
    var isCustom: Bool = false
    
    // Implement Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Implement Equatable conformance (required by Hashable)
    static func == (lhs: StreamingPlatform, rhs: StreamingPlatform) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - WebView with Navigation Support
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
        
        // Configure preferences
        let preferences = configuration.preferences
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // Configure media playback
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Enable additional features for better compatibility
        if #available(macOS 10.15, *) {
            preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
            preferences.setValue(true, forKey: "developerExtrasEnabled")
        }
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsMagnification = true
        
        // Set up notification observers
        context.coordinator.setupNotificationObservers(for: webView)
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        private var webView: WKWebView?
        private var observers: [NSObjectProtocol] = []
        
        init(_ parent: WebView) {
            self.parent = parent
            super.init()
        }
        
        deinit {
            // Clean up observers
            observers.forEach { NotificationCenter.default.removeObserver($0) }
        }
        
        func setupNotificationObservers(for webView: WKWebView) {
            self.webView = webView
            
            // Clean up existing observers
            observers.forEach { NotificationCenter.default.removeObserver($0) }
            observers.removeAll()
            
            // Go Back
            let backObserver = NotificationCenter.default.addObserver(
                forName: .goBack,
                object: nil,
                queue: .main
            ) { _ in
                webView.goBack()
            }
            observers.append(backObserver)
            
            // Go Forward
            let forwardObserver = NotificationCenter.default.addObserver(
                forName: .goForward,
                object: nil,
                queue: .main
            ) { _ in
                webView.goForward()
            }
            observers.append(forwardObserver)
            
            // Refresh
            let refreshObserver = NotificationCenter.default.addObserver(
                forName: .refresh,
                object: nil,
                queue: .main
            ) { _ in
                webView.reload()
            }
            observers.append(refreshObserver)
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                print("WebView navigation failed: \(error.localizedDescription)")
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                print("WebView provisional navigation failed: \(error.localizedDescription)")
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow all navigation
            decisionHandler(.allow)
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

// MARK: - Sidebar View (Extracted to reduce complexity)
struct SidebarView: View {
    @ObservedObject var platformManager: PlatformManager
    @Binding var selectedPlatform: StreamingPlatform?
    @Binding var showingAddPlatform: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Platform List
            List(selection: $selectedPlatform) {
                Section("Streaming Platforms") {
                    ForEach(platformManager.platforms) { platform in
                        PlatformRow(platform: platform, platformManager: platformManager)
                            .tag(platform)
                    }
                }
            }
            .listStyle(SidebarListStyle())
            
            // Add Platform Button
            Divider()
            
            AddPlatformButton(showingAddPlatform: $showingAddPlatform)
        }
        .frame(minWidth: 200, idealWidth: 250)
    }
}

// MARK: - Platform Row (Extracted to reduce complexity)
struct PlatformRow: View {
    let platform: StreamingPlatform
    @ObservedObject var platformManager: PlatformManager
    
    var body: some View {
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
        .padding(.vertical, 4)
    }
}

// MARK: - Add Platform Button (Extracted to reduce complexity)
struct AddPlatformButton: View {
    @Binding var showingAddPlatform: Bool
    
    var body: some View {
        Button(action: { showingAddPlatform = true }) {
            Label("Add Platform", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.gray.opacity(0.1))
    }
}

// MARK: - Navigation Bar (Extracted to reduce complexity)
struct NavigationBar: View {
    let platform: StreamingPlatform
    let canGoBack: Bool
    let canGoForward: Bool
    let isLoading: Bool
    let onGoBack: () -> Void
    let onGoForward: () -> Void
    let onRefresh: () -> Void
    let onFullScreen: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onGoBack) {
                Image(systemName: "chevron.left")
            }
            .disabled(!canGoBack)
            
            Button(action: onGoForward) {
                Image(systemName: "chevron.right")
            }
            .disabled(!canGoForward)
            
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            
            Text(platform.name)
                .font(.headline)
                .frame(maxWidth: .infinity)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            }
            
            Button(action: onFullScreen) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Welcome View (Extracted to reduce complexity)
struct WelcomeView: View {
    var body: some View {
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

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var platformManager = PlatformManager()
    @State private var selectedPlatform: StreamingPlatform?
    @State private var showingAddPlatform = false
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    @State private var showingSidebar = true
    
    var body: some View {
        NavigationSplitView {
            SidebarView(
                platformManager: platformManager,
                selectedPlatform: $selectedPlatform,
                showingAddPlatform: $showingAddPlatform
            )
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar) {
                        Image(systemName: "sidebar.left")
                    }
                }
            }
        } detail: {
            DetailView(
                selectedPlatform: selectedPlatform,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                isLoading: $isLoading
            )
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingAddPlatform) {
            AddPlatformView(platformManager: platformManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddPlatform)) { _ in
            showingAddPlatform = true
        }
    }
    
    private func toggleSidebar() {
        withAnimation {
            showingSidebar.toggle()
        }
    }
}

// MARK: - Detail View (Extracted to reduce complexity)
struct DetailView: View {
    let selectedPlatform: StreamingPlatform?
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    
    var body: some View {
        if let platform = selectedPlatform,
           let url = URL(string: platform.url) {
            VStack(spacing: 0) {
                NavigationBar(
                    platform: platform,
                    canGoBack: canGoBack,
                    canGoForward: canGoForward,
                    isLoading: isLoading,
                    onGoBack: goBack,
                    onGoForward: goForward,
                    onRefresh: refresh,
                    onFullScreen: enterFullScreen
                )
                
                Divider()
                
                WebView(
                    url: url,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    isLoading: $isLoading
                )
            }
        } else {
            WelcomeView()
        }
    }
    
    private func goBack() {
        NotificationCenter.default.post(name: .goBack, object: nil)
    }
    
    private func goForward() {
        NotificationCenter.default.post(name: .goForward, object: nil)
    }
    
    private func refresh() {
        NotificationCenter.default.post(name: .refresh, object: nil)
    }
    
    private func enterFullScreen() {
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
            
            ButtonRow(
                name: name,
                url: url,
                onCancel: { dismiss() },
                onAdd: {
                    platformManager.addCustomPlatform(name: name, url: url)
                    dismiss()
                }
            )
        }
        .padding(30)
        .frame(width: 400)
    }
}

// MARK: - Button Row (Extracted to reduce complexity)
struct ButtonRow: View {
    let name: String
    let url: String
    let onCancel: () -> Void
    let onAdd: () -> Void
    
    private var isFormValid: Bool {
        !name.isEmpty && !url.isEmpty
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button("Cancel", action: onCancel)
                .keyboardShortcut(.escape)
            
            Button("Add Platform", action: onAdd)
                .keyboardShortcut(.return)
                .disabled(!isFormValid)
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let goBack = Notification.Name("goBack")
    static let goForward = Notification.Name("goForward")
    static let refresh = Notification.Name("refresh")
    static let showAddPlatform = Notification.Name("showAddPlatform")
}
