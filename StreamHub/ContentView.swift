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

// MARK: - WebView with Enhanced Fullscreen Support
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
        
        // Use default data store with persistent storage
        let dataStore = WKWebsiteDataStore.default()
        configuration.websiteDataStore = dataStore
        
        // Configure preferences for better compatibility
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // Enable fullscreen for HTML5 videos and other elements
        if #available(macOS 12.3, *) {
            preferences.isElementFullscreenEnabled = true
        }
        
        configuration.preferences = preferences
        
        // Allow all media to play without user interaction
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Configure process pool for better performance
        configuration.processPool = WKProcessPool()
        
        // Enhanced user content controller for fullscreen handling
        let userContentController = WKUserContentController()
        
        // FIXED: Enhanced JavaScript for proper fullscreen positioning
        let fullscreenScript = """
        (function() {
            console.log('StreamHub: Initializing fullscreen support');
            
            let isFullscreenActive = false;
            let originalVideoStyles = new Map();
            let fullscreenCheckInterval;
            
            // Function to apply fullscreen styles aggressively
            function applyFullscreenStyles(element) {
                console.log('StreamHub: Applying fullscreen styles to', element.tagName);
                
                // Store original styles if not already stored
                if (!originalVideoStyles.has(element)) {
                    originalVideoStyles.set(element, {
                        position: element.style.position,
                        top: element.style.top,
                        left: element.style.left,
                        width: element.style.width,
                        height: element.style.height,
                        objectFit: element.style.objectFit,
                        zIndex: element.style.zIndex,
                        backgroundColor: element.style.backgroundColor,
                        transform: element.style.transform,
                        margin: element.style.margin,
                        padding: element.style.padding,
                        cssText: element.style.cssText
                    });
                }
                
                // Apply fullscreen styles with maximum specificity
                const fullscreenStyles = [
                    'position: fixed !important',
                    'top: 0px !important',
                    'left: 0px !important',
                    'width: 100vw !important',
                    'height: 100vh !important',
                    'max-width: 100vw !important',
                    'max-height: 100vh !important',
                    'min-width: 100vw !important',
                    'min-height: 100vh !important',
                    'object-fit: contain !important',
                    'z-index: 2147483647 !important',
                    'background-color: black !important',
                    'transform: none !important',
                    'margin: 0px !important',
                    'padding: 0px !important',
                    'border: none !important',
                    'outline: none !important',
                    'box-sizing: border-box !important'
                ].join('; ');
                
                element.style.cssText = fullscreenStyles;
                
                // Force reflow multiple times
                element.offsetHeight;
                element.offsetWidth;
                
                isFullscreenActive = true;
                
                // Start aggressive style enforcement
                if (fullscreenCheckInterval) {
                    clearInterval(fullscreenCheckInterval);
                }
                
                fullscreenCheckInterval = setInterval(() => {
                    if (document.webkitFullscreenElement === element || document.fullscreenElement === element) {
                        // Reapply styles if they've been changed
                        if (element.style.position !== 'fixed' || 
                            element.style.top !== '0px' || 
                            element.style.left !== '0px' ||
                            element.style.width !== '100vw' ||
                            element.style.height !== '100vh') {
                            element.style.cssText = fullscreenStyles;
                        }
                    } else {
                        // Element is no longer in fullscreen, stop checking
                        clearInterval(fullscreenCheckInterval);
                        restoreOriginalStyles(element);
                    }
                }, 100);
            }
            
            // Function to restore original styles
            function restoreOriginalStyles(element) {
                console.log('StreamHub: Restoring original styles');
                
                if (fullscreenCheckInterval) {
                    clearInterval(fullscreenCheckInterval);
                }
                
                if (originalVideoStyles.has(element)) {
                    const original = originalVideoStyles.get(element);
                    if (original.cssText) {
                        element.style.cssText = original.cssText;
                    } else {
                        // Restore individual properties
                        Object.keys(original).forEach(key => {
                            if (key !== 'cssText') {
                                element.style[key] = original[key] || '';
                            }
                        });
                    }
                    originalVideoStyles.delete(element);
                }
                
                isFullscreenActive = false;
            }
            
            // Enhanced fullscreen event handlers
            function setupFullscreenHandlers() {
                console.log('StreamHub: Setting up fullscreen handlers');
                
                const videos = document.querySelectorAll('video');
                videos.forEach(video => {
                    // Mark as handled to avoid duplicate setup
                    if (video.hasAttribute('data-streamhub-fullscreen-setup')) {
                        return;
                    }
                    video.setAttribute('data-streamhub-fullscreen-setup', 'true');
                    
                    // Override webkit fullscreen request
                    const originalWebkitRequestFS = video.webkitRequestFullscreen;
                    if (originalWebkitRequestFS) {
                        video.webkitRequestFullscreen = function() {
                            console.log('StreamHub: Webkit fullscreen requested');
                            const result = originalWebkitRequestFS.call(this);
                            
                            // Apply styles with multiple attempts
                            [10, 50, 100, 200, 500].forEach(delay => {
                                setTimeout(() => {
                                    if (document.webkitFullscreenElement === this) {
                                        applyFullscreenStyles(this);
                                    }
                                }, delay);
                            });
                            
                            return result;
                        };
                    }
                    
                    // Override standard fullscreen request
                    const originalRequestFS = video.requestFullscreen;
                    if (originalRequestFS) {
                        video.requestFullscreen = function() {
                            console.log('StreamHub: Standard fullscreen requested');
                            const result = originalRequestFS.call(this);
                            
                            [10, 50, 100, 200, 500].forEach(delay => {
                                setTimeout(() => {
                                    if (document.fullscreenElement === this) {
                                        applyFullscreenStyles(this);
                                    }
                                }, delay);
                            });
                            
                            return result;
                        };
                    }
                    
                    // Add direct event listeners to videos
                    video.addEventListener('webkitfullscreenchange', function() {
                        handleFullscreenChange(this);
                    });
                    
                    video.addEventListener('fullscreenchange', function() {
                        handleFullscreenChange(this);
                    });
                });
                
                // Global fullscreen change handler
                function handleFullscreenChange(targetElement) {
                    console.log('StreamHub: Fullscreen change detected');
                    
                    const webkitElement = document.webkitFullscreenElement;
                    const standardElement = document.fullscreenElement;
                    const fullscreenElement = webkitElement || standardElement || targetElement;
                    
                    if (fullscreenElement && (webkitElement || standardElement)) {
                        // Entering fullscreen - apply styles multiple times
                        console.log('StreamHub: Entering fullscreen for', fullscreenElement.tagName);
                        [0, 10, 50, 100, 200, 300, 500, 1000].forEach(delay => {
                            setTimeout(() => {
                                if (document.webkitFullscreenElement === fullscreenElement || 
                                    document.fullscreenElement === fullscreenElement) {
                                    applyFullscreenStyles(fullscreenElement);
                                }
                            }, delay);
                        });
                    } else if (isFullscreenActive) {
                        // Exiting fullscreen - restore all videos
                        console.log('StreamHub: Exiting fullscreen');
                        videos.forEach(video => {
                            restoreOriginalStyles(video);
                        });
                    }
                }
                
                // Document-level fullscreen listeners with enhanced handling
                ['webkitfullscreenchange', 'fullscreenchange'].forEach(eventType => {
                    document.addEventListener(eventType, function(event) {
                        handleFullscreenChange(event.target);
                    });
                });
                
                // Handle other fullscreen elements (divs, containers, etc.)
                const allPotentialFullscreenElements = document.querySelectorAll('div, section, main, article, video, iframe');
                allPotentialFullscreenElements.forEach(element => {
                    if (!element.hasAttribute('data-streamhub-fullscreen-setup')) {
                        element.setAttribute('data-streamhub-fullscreen-setup', 'true');
                        
                        element.addEventListener('webkitfullscreenchange', function() {
                            if (document.webkitFullscreenElement === this) {
                                applyFullscreenStyles(this);
                            }
                        });
                        
                        element.addEventListener('fullscreenchange', function() {
                            if (document.fullscreenElement === this) {
                                applyFullscreenStyles(this);
                            }
                        });
                    }
                });
            }
            
            // MutationObserver to handle dynamically added content
            const observer = new MutationObserver(function(mutations) {
                let shouldSetupHandlers = false;
                
                mutations.forEach(function(mutation) {
                    mutation.addedNodes.forEach(function(node) {
                        if (node.nodeType === 1) { // Element node
                            if (node.tagName === 'VIDEO' || 
                                (node.querySelector && node.querySelector('video')) ||
                                node.tagName === 'DIV' ||
                                node.tagName === 'IFRAME') {
                                shouldSetupHandlers = true;
                            }
                        }
                    });
                });
                
                if (shouldSetupHandlers) {
                    setTimeout(setupFullscreenHandlers, 200);
                }
            });
            
            // Initialize when DOM is ready
            function initialize() {
                console.log('StreamHub: Initializing fullscreen handlers');
                setupFullscreenHandlers();
                
                if (document.body) {
                    observer.observe(document.body, {
                        childList: true,
                        subtree: true,
                        attributes: true,
                        attributeFilter: ['style', 'class']
                    });
                }
            }
            
            // Multiple initialization points
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', initialize);
            } else {
                initialize();
            }
            
            // Also initialize on window load
            window.addEventListener('load', function() {
                setTimeout(initialize, 500);
            });
            
            // Handle page visibility changes
            document.addEventListener('visibilitychange', function() {
                if (!document.hidden) {
                    setTimeout(setupFullscreenHandlers, 500);
                }
            });
            
            // Periodic check for new elements (as fallback)
            setInterval(function() {
                const newVideos = document.querySelectorAll('video:not([data-streamhub-fullscreen-setup])');
                const newElements = document.querySelectorAll('div:not([data-streamhub-fullscreen-setup]), iframe:not([data-streamhub-fullscreen-setup])');
                
                if (newVideos.length > 0 || newElements.length > 0) {
                    console.log('StreamHub: Found new elements, setting up handlers');
                    setupFullscreenHandlers();
                }
            }, 3000);
            
            console.log('StreamHub: Fullscreen script initialization complete');
        })();
        """
        
        let script = WKUserScript(source: fullscreenScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(script)
        
        // Add a second script that runs earlier for immediate setup
        let earlyScript = WKUserScript(source: fullscreenScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(earlyScript)
        
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Enhanced user agent for better compatibility
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15"
        
        // Enable navigation gestures and zooming
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsMagnification = true
        
        // Set autoresizing mask for proper layout
        webView.autoresizingMask = [.width, .height]
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure the webView's enclosing scroll view
        if let scrollView = webView.enclosingScrollView {
            scrollView.hasVerticalScroller = false
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = true
        }
        
        // Set up notification observers
        context.coordinator.setupNotificationObservers(for: webView)
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.updateURL(url, in: webView)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebView
        private var webView: WKWebView?
        private var observers: [NSObjectProtocol] = []
        private var lastLoadedURL: URL?
        private var isCurrentlyLoading = false
        private var loadTask: DispatchWorkItem?
        
        init(_ parent: WebView) {
            self.parent = parent
            super.init()
        }
        
        deinit {
            observers.forEach { NotificationCenter.default.removeObserver($0) }
            loadTask?.cancel()
        }
        
        func updateURL(_ url: URL, in webView: WKWebView) {
            loadTask?.cancel()
            
            guard lastLoadedURL?.absoluteString != url.absoluteString else {
                return
            }
            
            loadTask = DispatchWorkItem { [weak self] in
                guard let self = self, !self.isCurrentlyLoading else { return }
                
                print("Loading URL: \(url.absoluteString)")
                self.lastLoadedURL = url
                self.isCurrentlyLoading = true
                
                let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
                webView.load(request)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: loadTask!)
        }
        
        func setupNotificationObservers(for webView: WKWebView) {
            self.webView = webView
            
            observers.forEach { NotificationCenter.default.removeObserver($0) }
            observers.removeAll()
            
            let backObserver = NotificationCenter.default.addObserver(
                forName: .goBack,
                object: nil,
                queue: .main
            ) { _ in
                if webView.canGoBack {
                    webView.goBack()
                }
            }
            observers.append(backObserver)
            
            let forwardObserver = NotificationCenter.default.addObserver(
                forName: .goForward,
                object: nil,
                queue: .main
            ) { _ in
                if webView.canGoForward {
                    webView.goForward()
                }
            }
            observers.append(forwardObserver)
            
            let refreshObserver = NotificationCenter.default.addObserver(
                forName: .refresh,
                object: nil,
                queue: .main
            ) { _ in
                webView.reload()
            }
            observers.append(refreshObserver)
        }
        
        // MARK: - WKNavigationDelegate
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("Started loading: \(webView.url?.absoluteString ?? "unknown")")
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("Finished loading: \(webView.url?.absoluteString ?? "unknown")")
            
            // Inject additional fullscreen fix after page load
            let postLoadFullscreenFix = """
            (function() {
                console.log('StreamHub: Post-load fullscreen setup');
                
                // Force immediate setup on all existing videos
                const videos = document.querySelectorAll('video');
                videos.forEach(video => {
                    console.log('StreamHub: Setting up video element');
                    
                    // Enhanced method override with better error handling
                    if (video.webkitRequestFullscreen && !video.hasAttribute('data-streamhub-enhanced')) {
                        video.setAttribute('data-streamhub-enhanced', 'true');
                        
                        const originalWebkitRequestFS = video.webkitRequestFullscreen.bind(video);
                        video.webkitRequestFullscreen = function() {
                            console.log('StreamHub: Enhanced webkit fullscreen requested');
                            
                            try {
                                const result = originalWebkitRequestFS();
                                
                                // Aggressive style application with multiple timings
                                const delays = [0, 16, 33, 50, 100, 150, 200, 300, 500, 750, 1000];
                                delays.forEach(delay => {
                                    setTimeout(() => {
                                        if (document.webkitFullscreenElement === this) {
                                            const styles = 'position: fixed !important; top: 0px !important; left: 0px !important; width: 100vw !important; height: 100vh !important; object-fit: contain !important; z-index: 2147483647 !important; background-color: black !important; transform: none !important; margin: 0px !important; padding: 0px !important; max-width: 100vw !important; max-height: 100vh !important; min-width: 100vw !important; min-height: 100vh !important;';
                                            this.style.cssText = styles;
                                            this.offsetHeight; // Force reflow
                                        }
                                    }, delay);
                                });
                                
                                return result;
                            } catch (error) {
                                console.error('StreamHub: Error in fullscreen request', error);
                                return originalWebkitRequestFS();
                            }
                        };
                    }
                    
                    // Enhanced standard fullscreen override
                    if (video.requestFullscreen && !video.hasAttribute('data-streamhub-standard-enhanced')) {
                        video.setAttribute('data-streamhub-standard-enhanced', 'true');
                        
                        const originalRequestFS = video.requestFullscreen.bind(video);
                        video.requestFullscreen = function() {
                            console.log('StreamHub: Enhanced standard fullscreen requested');
                            
                            try {
                                const result = originalRequestFS();
                                
                                const delays = [0, 16, 33, 50, 100, 150, 200, 300, 500, 750, 1000];
                                delays.forEach(delay => {
                                    setTimeout(() => {
                                        if (document.fullscreenElement === this) {
                                            const styles = 'position: fixed !important; top: 0px !important; left: 0px !important; width: 100vw !important; height: 100vh !important; object-fit: contain !important; z-index: 2147483647 !important; background-color: black !important; transform: none !important; margin: 0px !important; padding: 0px !important; max-width: 100vw !important; max-height: 100vh !important; min-width: 100vw !important; min-height: 100vh !important;';
                                            this.style.cssText = styles;
                                            this.offsetHeight; // Force reflow
                                        }
                                    }, delay);
                                });
                                
                                return result;
                            } catch (error) {
                                console.error('StreamHub: Error in standard fullscreen request', error);
                                return originalRequestFS();
                            }
                        };
                    }
                });
                
                // Enhanced global event listeners
                function globalFullscreenHandler(event) {
                    console.log('StreamHub: Global fullscreen event');
                    const element = document.webkitFullscreenElement || document.fullscreenElement;
                    
                    if (element) {
                        // Apply styles immediately and with delays
                        const styles = 'position: fixed !important; top: 0px !important; left: 0px !important; width: 100vw !important; height: 100vh !important; object-fit: contain !important; z-index: 2147483647 !important; background-color: black !important; transform: none !important; margin: 0px !important; padding: 0px !important; max-width: 100vw !important; max-height: 100vh !important; min-width: 100vw !important; min-height: 100vh !important;';
                        
                        element.style.cssText = styles;
                        element.offsetHeight; // Force reflow
                        
                        // Apply with delays as well
                        [50, 100, 200, 500].forEach(delay => {
                            setTimeout(() => {
                                if (document.webkitFullscreenElement === element || document.fullscreenElement === element) {
                                    element.style.cssText = styles;
                                    element.offsetHeight;
                                }
                            }, delay);
                        });
                    }
                }
                
                // Remove existing listeners and add new ones
                ['webkitfullscreenchange', 'fullscreenchange'].forEach(eventType => {
                    document.removeEventListener(eventType, globalFullscreenHandler);
                    document.addEventListener(eventType, globalFullscreenHandler);
                });
                
                console.log('StreamHub: Post-load setup complete');
            })();
            """
            
            webView.evaluateJavaScript(postLoadFullscreenFix) { result, error in
                if let error = error {
                    print("Error injecting post-load fullscreen script: \(error)")
                } else {
                    print("Post-load fullscreen script injected successfully")
                }
            }
            
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
                self.isCurrentlyLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("Navigation failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.isCurrentlyLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let nsError = error as NSError
            print("Provisional navigation failed: \(error.localizedDescription) (Code: \(nsError.code))")
            
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.isCurrentlyLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            decisionHandler(.allow)
        }
        
        // MARK: - Enhanced WKUIDelegate for fullscreen support
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
        
        // Handle JavaScript alerts, confirms, and prompts
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Alert"
                alert.informativeText = message
                alert.addButton(withTitle: "OK")
                alert.runModal()
                completionHandler()
            }
        }
        
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Confirm"
                alert.informativeText = message
                alert.addButton(withTitle: "OK")
                alert.addButton(withTitle: "Cancel")
                let response = alert.runModal()
                completionHandler(response == .alertFirstButtonReturn)
            }
        }
        
        // Handle media capture permissions (for video calls)
        @available(macOS 12.0, *)
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }
        
        // Handle general permission requests
        func webView(_ webView: WKWebView, requestPermissionFor permissionRequest: WKPermissionRequest, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
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

// MARK: - Sidebar View
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

// MARK: - Platform Row
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

// MARK: - Add Platform Button
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

// MARK: - Navigation Bar
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

// MARK: - Welcome View
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
            
            Text("Enhanced fullscreen support enabled!")
                .font(.caption)
                .foregroundColor(.green)
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

// MARK: - Detail View
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
                .clipped()
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

// MARK: - Button Row
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
}
