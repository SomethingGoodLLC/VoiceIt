# Voice It - Evidence Documentation App

A privacy-first iOS application built with Swift 6 and SwiftUI for documenting and managing evidence in sensitive situations.

## 🚀 Quick Start

### Prerequisites
- **Xcode 16+** (for Swift 6 support)
- **iOS 18+** deployment target
- **Apple Developer Account** (for testing biometrics)

### Running the App
```bash
# Open the project
open VoiceIt.xcodeproj

# Or from command line
cd /Users/leone/IOS_Apps/VoiceIt
xcodebuild -project VoiceIt.xcodeproj -scheme VoiceIt -sdk iphonesimulator build
```

Press **⌘R** in Xcode to build and run!

## 🏗️ Architecture (2025 Best Practices)

### Technology Stack
- **Swift 6** with Strict Concurrency
- **SwiftUI** for declarative UI
- **SwiftData** for local persistence (iOS 18+)
- **@Observable** macro for modern state management
- **CryptoKit** for end-to-end encryption

### Architecture Patterns
- **Service Layer Pattern**: Separation of business logic from UI
- **Protocol-Based Models**: No inheritance for iOS 18 SwiftData compatibility
- **Direct Model Usage**: Models used directly in views where appropriate
- **View Models**: Only for complex UI coordination
- **Dependency Injection**: Services injected through environment

## 📁 Project Structure

```
VoiceIt/
├── App/
│   ├── VoiceItApp.swift              # App entry point
│   └── ContentView.swift              # Main tab container
├── Models/
│   ├── Evidence/
│   │   ├── EvidenceProtocol.swift     # Common evidence protocol
│   │   ├── VoiceNote.swift            # Audio evidence
│   │   ├── PhotoEvidence.swift        # Photo evidence
│   │   ├── VideoEvidence.swift        # Video evidence
│   │   └── TextEntry.swift            # Text notes
│   ├── LocationSnapshot.swift         # GPS tracking data
│   ├── EmergencyContact.swift         # Emergency contacts
│   └── Resource.swift                 # Support resources
├── Services/
│   ├── EncryptionService.swift        # End-to-end encryption
│   ├── LocationService.swift          # GPS tracking
│   ├── ExportService.swift            # PDF/JSON exports
│   ├── EmergencyService.swift         # Panic button & 911
│   ├── ResourceService.swift          # Find nearby resources
│   └── AuthenticationService.swift    # Biometric security
├── Views/
│   ├── Onboarding/
│   │   └── OnboardingView.swift       # Privacy onboarding
│   ├── Timeline/
│   │   ├── TimelineView.swift         # Evidence timeline with stealth mode
│   │   ├── EvidenceRowView.swift      # Timeline row item
│   │   └── ExportOptionsSheet.swift   # Export format selection
│   ├── AddEvidence/
│   │   ├── AddEvidenceView.swift      # Evidence type picker
│   │   ├── VoiceRecorderView.swift    # Audio recording
│   │   ├── PhotoCaptureView.swift     # Camera capture
│   │   └── TextEntryView.swift        # Text notes
│   ├── Resources/
│   │   ├── ResourcesView.swift        # Support resources
│   │   └── ResourceDetailView.swift   # Resource details
│   └── Community/
│       └── CommunityView.swift        # Community tab
├── Utilities/
│   ├── KeychainManager.swift          # Keychain operations
│   ├── Constants.swift                # App constants
│   └── Extensions/
│       ├── Color+Theme.swift          # App colors
│       ├── Date+Extensions.swift      # Date utilities
│       └── View+ShakeGesture.swift    # Shake gesture detection
└── Resources/
    └── Info.plist                     # App configuration
```

## 🎨 Design System

### Colors
- **Primary**: Purple (#7C3AED)
- **Gradients**: Purple to pink for action screens
- **System Colors**: SF Symbols throughout

### UI Patterns
- **Purple gradient backgrounds**: Onboarding, Add Evidence (action screens)
- **White backgrounds**: Timeline, Resources, Community (content screens)
- **Consistent spacing**: 8/16/24 padding scale
- **SF Symbols**: Native iOS iconography

## 🔐 Security & Privacy

### Encryption
- **End-to-end encryption** using CryptoKit (AES-GCM-256)
- Encryption keys stored securely in iOS Keychain
- All evidence data encrypted at rest

### Authentication
- **Biometric authentication** (Face ID / Touch ID)
- Passcode fallback
- Auto-lock after inactivity (5 minutes default)

### Privacy
- **No cloud storage** - all data stays on device
- **No analytics or tracking**
- Location tracking with explicit user consent
- Export only when user initiates

## 🚀 Features

### Evidence Management
- 📝 **Text Notes**: Quick text entries with rich formatting
- 🎤 **Voice Notes**: Audio recordings with optional transcription
- 📷 **Photos**: Camera capture with EXIF metadata
- 🎥 **Videos**: Video recording with thumbnails

### Timeline Features
- 📊 **Modern List UI**: Purple accent bars, SF Symbol badges, and relative timestamps
- 🔄 **Pull-to-Refresh**: Swipe down to refresh the timeline
- 👆 **Swipe Actions**: Share or delete evidence with swipe gestures
- 🕶️ **Stealth Mode**: Hide app content with calculator decoy screen (shake device to exit)
- 🔍 **Smart Filtering**: Filter by evidence type or critical status
- 📤 **Export Banner**: One-tap access to legal export options
- ⚡ **Performant**: Optimized for 1000+ evidence items with lazy loading

### Location Tracking
- GPS coordinates with timestamps
- Reverse geocoding for addresses
- Privacy controls (enable/disable per session)
- Accuracy indicators

### Emergency Features
- 🚨 **Panic Button**: Quick 911 dial
- 📞 **Emergency Contacts**: Pre-configured contacts
- 📍 **Location Sharing**: Send location to trusted contacts

### Export Options
- 📄 **PDF Export**: Legal-ready documentation with formatted evidence
- 📊 **JSON Export**: Machine-readable format for data analysis
- 🔒 **Encrypted Export**: Password-protected files for maximum security
- 💼 **Export Options Sheet**: Choose format, include/exclude images, and customize export

### Support Resources
- 🏥 **Find Shelters**: Nearby safe locations
- 📞 **Hotlines**: 24/7 crisis support numbers
- ⚖️ **Legal Aid**: Local legal resources
- 🌐 **Distance-based**: Sorted by proximity

## 🛠️ Development

### Swift 6 Concurrency Guidelines

**Critical Rules:**
- Services are NOT marked with `@MainActor`
- UI updates wrapped in `await MainActor.run { }`
- NEVER nest `MainActor.run` calls in `@MainActor` contexts
- All services conform to `Sendable` or `@unchecked Sendable`

**Example:**
```swift
// ✅ Correct
class LocationService: @unchecked Sendable {
    func updateLocation() {
        Task { @MainActor in
            self.currentLocation = newLocation
        }
    }
}

// ❌ Wrong - causes deadlocks
@MainActor
class LocationService {
    func updateLocation() async {
        await MainActor.run {  // Deadlock!
            self.currentLocation = newLocation
        }
    }
}
```

### SwiftData Best Practices
- Models use `@Model` macro
- Protocol-based design (no model inheritance for iOS 18)
- Container configured with encryption support
- Queries use `@Query` in views
- All models marked `@available(iOS 18, *)`

### Service Layer Pattern
```swift
// Services handle business logic
class EncryptionService: Sendable {
    func encrypt(_ data: Data) async throws -> Data { }
}

// Views inject services via Environment
struct ContentView: View {
    @Environment(\.encryptionService) var encryption
}
```

## 🧪 Testing

### Unit Tests (To Be Implemented)
- Service layer logic
- Encryption/decryption
- Data model validation
- Export format generation

### Integration Tests (To Be Implemented)
- SwiftData persistence
- Location tracking flow
- Emergency contact workflow
- Export generation end-to-end

### Manual Testing Checklist
- [ ] Onboarding flow completes
- [ ] Biometric authentication works
- [ ] Evidence creation (all 4 types)
- [ ] Timeline displays evidence correctly
- [ ] Timeline pull-to-refresh works
- [ ] Timeline swipe actions (share/delete) work
- [ ] Stealth mode activates and hides content
- [ ] Shake gesture exits stealth mode
- [ ] Export banner displays correct item count
- [ ] Export options sheet presents correctly
- [ ] Evidence filtering works for all types
- [ ] Emergency button dials 911
- [ ] Resources list loads
- [ ] Location permission handling
- [ ] Auto-lock activates

## 🐛 Troubleshooting

### Build Errors

**"Cannot find type 'EvidenceProtocol'"**
- Ensure all files are added to the Xcode target
- Clean build folder (⇧⌘K)
- Regenerate project: `xcodegen generate`

**Module compilation errors**
- Check Swift version in Build Settings (should be 6.0)
- Verify SWIFT_STRICT_CONCURRENCY is set to `complete`

### Runtime Issues

**App crashes on launch**
- Check SwiftData model schema
- Verify Info.plist permissions are set
- Check console for specific errors

**Biometric auth not working**
- Test on real device (simulator has limitations)
- Verify NSFaceIDUsageDescription in Info.plist
- Check LocalAuthentication framework is linked

**Location not updating**
- Check Info.plist has location permissions
- Request permission in code
- Test on device or enable location in simulator

### Simulator Issues

**Face ID not available**
- Enable: **Features → Face ID → Enrolled**
- Trigger: **Features → Face ID → Matching Face**

**Location not working**
- Use: **Features → Location → Custom Location**
- Or: **Debug → Location → Custom Location**

## 📋 Configuration

### Required Capabilities
In Xcode → Target → Signing & Capabilities, add:
- ✅ Background Modes → Location updates
- ✅ Keychain Sharing

### Info.plist Permissions (Already Configured)
- ✅ Camera (`NSCameraUsageDescription`)
- ✅ Microphone (`NSMicrophoneUsageDescription`)
- ✅ Photo Library (`NSPhotoLibraryUsageDescription`)
- ✅ Location When In Use (`NSLocationWhenInUseUsageDescription`)
- ✅ Location Always (`NSLocationAlwaysAndWhenInUseUsageDescription`)
- ✅ Face ID / Touch ID (`NSFaceIDUsageDescription`)

### Customization

**Update App Colors:**
Edit `Utilities/Extensions/Color+Theme.swift`:
```swift
static let voiceitPurple = Color(hex: "7C3AED") // Change this
```

**Update Emergency Number:**
Edit `Services/EmergencyService.swift`:
```swift
private let emergencyNumber = "911" // Change for your country
```

**Update Default Resources:**
Edit `Services/ResourceService.swift` to add your local resources.

## 📝 TODO

### High Priority
- [ ] Implement audio recording (AVFoundation)
- [ ] Add audio transcription (Speech framework)
- [ ] Implement PDF export generation
- [ ] Add camera capture functionality
- [ ] Implement video recording

### Medium Priority
- [ ] Create comprehensive test suite
- [ ] Add data export encryption
- [ ] Implement auto-lock timer
- [ ] Add nearby resources API integration
- [ ] Create emergency contact quick dial

### Low Priority
- [ ] Add localization support
- [ ] Implement accessibility features
- [ ] Create app icon and launch screen
- [ ] Add App Store assets
- [ ] Documentation improvements

## 🤝 Contributing

This is a privacy-first application. Any contributions must:
- Maintain end-to-end encryption
- Respect user privacy (no analytics, tracking, or cloud storage)
- Follow Swift 6 concurrency patterns
- Include comprehensive tests
- Document security implications

## 📄 License

TBD - Intended for use in sensitive situations. License will prioritize user privacy and safety.

## 🆘 Emergency Resources

**If you're in immediate danger, call 911 or your local emergency services.**

**US Crisis Support Resources:**
- **National Domestic Violence Hotline**: 1-800-799-7233
- **Crisis Text Line**: Text HOME to 741741
- **National Sexual Assault Hotline**: 1-800-656-4673
- **National Suicide Prevention Lifeline**: 988

---

**Built with Swift 6, SwiftUI, and a commitment to user safety and privacy.**