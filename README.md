# StreamHub

**A unified macOS streaming platform that brings all your favorite streaming services together in one sleek application.**

![StreamHub Logo](https://img.shields.io/badge/macOS-13.0+-blue.svg) ![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg) ![SwiftUI](https://img.shields.io/badge/SwiftUI-Compatible-green.svg) ![License](https://img.shields.io/badge/License-MIT-yellow.svg)

## 🎯 Overview

StreamHub is a native macOS application built with SwiftUI that consolidates multiple streaming platforms into a single, user-friendly interface. No more juggling between browser tabs or different apps - access Netflix, Prime Video, Disney+ Hotstar, JioCinema, and more from one centralized hub.

## ✨ Features

### Current Features
- **🖥️ Native macOS Experience**: Built with SwiftUI for optimal macOS integration
- **🌐 Multi-Platform Support**: Pre-configured access to 7+ popular streaming services
- **➕ Custom Platform Addition**: Add any streaming service with custom URL support
- **🎮 Navigation Controls**: Built-in back, forward, and refresh functionality
- **⌨️ Keyboard Shortcuts**: Full keyboard navigation support (⌘+N, ⌘+[, ⌘+], ⌘+R)
- **🌗 Dark Mode Support**: Seamless dark/light mode adaptation
- **📱 Responsive Design**: Optimized split-view interface with collapsible sidebar
- **🔒 Privacy & Security**: Camera and microphone access for video calls on supported platforms
- **💾 Persistent Sessions**: Maintains login sessions across app restarts
- **🚀 Performance Optimized**: Efficient WebKit integration with hardware acceleration

### Pre-configured Platforms
- Prime Video
- Netflix
- JioCinema
- Disney+ Hotstar
- Zee5
- SonyLiv
- Airtel XStream

## 🚀 Getting Started

### Prerequisites
- macOS 15.5 or later
- Xcode 16.4 or later (for development)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/gitforaniket/StreamHub.git
   cd StreamHub
   ```

2. **Open in Xcode:**
   ```bash
   open StreamHub.xcodeproj
   ```

3. **Build and Run:**
   - Select your target device/simulator
   - Press `⌘+R` or click the Run button

### App Store Installation
*Coming Soon - App Store submission in progress*

## 📖 Usage

### Basic Navigation
1. **Launch StreamHub** from your Applications folder
2. **Select a Platform** from the sidebar to start streaming
3. **Add Custom Platforms** using the "+" button at the bottom of the sidebar
4. **Navigate** using the built-in controls or keyboard shortcuts

### Keyboard Shortcuts
- `⌘+N` - Add new platform
- `⌘+[` - Go back
- `⌘+]` - Go forward
- `⌘+R` - Refresh current page
- `⌘+⌃+F` - Toggle fullscreen

### Adding Custom Platforms
1. Click the "Add Platform" button in the sidebar
2. Enter the platform name and URL
3. Click "Add Platform" to save

## 🛠️ Technical Details

### Architecture
- **Framework**: SwiftUI with AppKit integration
- **Web Engine**: WKWebView with optimized configuration
- **Data Persistence**: UserDefaults for platform management
- **Networking**: URLSession with custom configuration
- **UI Pattern**: MVVM architecture with ObservableObject

### Key Components
- `StreamHubApp.swift` - Main app configuration and setup
- `ContentView.swift` - Primary UI implementation with navigation
- `PlatformManager.swift` - Platform data management
- `WebView.swift` - WebKit integration and navigation handling

## 🔧 Development

### Project Structure
```
StreamHub/
├── StreamHub/
│   ├── StreamHubApp.swift          # App entry point
│   ├── ContentView.swift           # Main UI implementation
│   ├── Info.plist                  # App configuration
│   ├── StreamHub.entitlements      # Security permissions
│   └── Assets.xcassets            # App assets
├── StreamHubTests/                 # Unit tests
├── StreamHubUITests/               # UI tests
└── README.md                       # Documentation
```

### Contributing

We welcome contributions! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** your changes: `git commit -m 'Add amazing feature'`
4. **Push** to the branch: `git push origin feature/amazing-feature`
5. **Open** a Pull Request

### Development Guidelines
- Follow Swift and SwiftUI best practices
- Maintain code documentation
- Write unit tests for new features
- Ensure accessibility compliance
- Test on multiple macOS versions

## 📋 Planned Features

### Near-term Enhancements
- **🔖 Bookmark System**: Save favorite content positions
- **🎵 Mini Player Mode**: Picture-in-picture support
- **📱 iOS Companion App**: iPhone/iPad version
- **🔍 Universal Search**: Search across all platforms
- **👤 Profile Management**: Multiple user profiles
- **📊 Usage Analytics**: Personal viewing statistics
- **🎨 Themes & Customization**: Personalized interface options

### Long-term Vision
- **🤖 AI Recommendations**: Smart content discovery
- **🎮 Gaming Integration**: Cloud gaming platform support
- **🌍 Localization**: Multi-language support
- **☁️ Cloud Sync**: Cross-device synchronization
- **🎬 Offline Support**: Download for offline viewing
- **🔌 Plugin Architecture**: Third-party integrations
- **📺 Apple TV Integration**: Seamless casting support

## 🐛 Known Issues

- Some platforms may require manual login on first access
- Fullscreen mode requires manual exit on certain platforms
- Custom platforms don't persist icons (uses generic globe icon)

## 🤝 Contributing

### How to Contribute
1. Check the [Issues](https://github.com/gitforaniket/StreamHub/issues) page for bugs and feature requests
2. Fork the repository and create a new branch
3. Make your changes and test thoroughly
4. Submit a pull request with a clear description

### Code of Conduct
Please be respectful and constructive in all interactions. We're building this together!

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on how to get started.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Aniket** - *Original Creator & Maintainer*
- GitHub: [@gitforaniket](https://github.com/gitforaniket)
- Project Link: [StreamHub](https://github.com/gitforaniket/StreamHub)

## 🙏 Acknowledgments

- Apple's SwiftUI and WebKit teams for the excellent frameworks
- The open-source community for inspiration and best practices
- Beta testers and contributors who help improve StreamHub

## 📊 Project Stats

- **Language**: Swift 100%
- **Minimum macOS**: 15.5
- **Architecture**: Universal (Intel & Apple Silicon)
- **Development Status**: Active

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/gitforaniket/StreamHub/issues)
- **Discussions**: [GitHub Discussions](https://github.com/gitforaniket/StreamHub/discussions)
- **Wiki**: [Project Wiki](https://github.com/gitforaniket/StreamHub/wiki)

---

**⭐ If you find StreamHub useful, please consider starring the repository!**

*Built with ❤️ for the macOS community*
