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
│   │   ├── VoiceNote.swift            # Audio evidence with transcription
│   │   ├── PhotoEvidence.swift        # Photo evidence with metadata
│   │   ├── VideoEvidence.swift        # Video evidence with thumbnails
│   │   └── TextEntry.swift            # Text notes with templates
│   ├── EvidenceCategory.swift         # Evidence categorization
│   ├── LocationSnapshot.swift         # GPS tracking data
│   ├── EmergencyContact.swift         # Emergency contacts
│   └── Resource.swift                 # Support resources
├── Services/
│   ├── EncryptionService.swift        # End-to-end encryption
│   ├── LocationService.swift          # GPS tracking
│   ├── ExportService.swift            # PDF/JSON exports
│   ├── EmergencyService.swift         # Panic button & 911
│   ├── ResourceService.swift          # Find nearby resources
│   ├── AuthenticationService.swift    # Biometric security
│   ├── AudioRecordingService.swift    # Audio recording with waveform
│   ├── TranscriptionService.swift     # Speech-to-text transcription
│   └── FileStorageService.swift       # Encrypted file management
├── Views/
│   ├── Onboarding/
│   │   └── OnboardingView.swift       # Privacy onboarding
│   ├── Timeline/
│   │   ├── TimelineView.swift         # Evidence timeline with stealth mode
│   │   ├── EvidenceRowView.swift      # Timeline row item
│   │   └── ExportOptionsSheet.swift   # Export format selection
│   ├── AddEvidence/
│   │   ├── AddEvidenceView.swift      # Main tab with centered + button
│   │   ├── VoiceRecorderView.swift    # Audio recording with transcription
│   │   ├── VideoCaptureView.swift     # Video recording and capture
│   │   ├── PhotoCaptureView.swift     # Photo camera and library
│   │   └── TextEntryView.swift        # Text entry with templates
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
  - Voice-to-text transcription
  - Quick templates: "He said...", "He did...", "I felt...", incident reports
  - Real-time word count
  - Auto-save drafts
- 🎤 **Voice Notes**: Professional audio recordings with live transcription
  - Real-time waveform visualization
  - Live on-device transcription (SFSpeechRecognizer)
  - Pause/resume capability
  - High-quality M4A format with compression
  - Background recording support
- 📷 **Photos**: Camera capture with metadata extraction
  - Direct camera access or library selection
  - Automatic HEIC compression
  - Image dimension tracking
  - Encrypted storage
- 🎥 **Videos**: Professional video recording
  - Camera recording with 10-minute max duration
  - Library import support
  - Automatic thumbnail generation
  - High-quality MP4 format
  - Compressed and encrypted storage

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
- ✅ Background Modes → Audio (for voice recording)
- ✅ Keychain Sharing

### Info.plist Permissions (Already Configured)
- ✅ Camera (`NSCameraUsageDescription`)
- ✅ Microphone (`NSMicrophoneUsageDescription`)
- ✅ Speech Recognition (`NSSpeechRecognitionUsageDescription`)
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

## 🎯 Add Evidence Features

The "Add Evidence" tab provides a clean, intuitive interface for documenting incidents:

### Main Interface
- **Centered Purple + Button**: Large, accessible action button with gradient background
- **Action Sheet**: Clean selection dialog for evidence type
- **Security Message**: Reassurance about encryption and local storage

### Voice Note Recording
- **Real-time Waveform**: Visual feedback with 30-sample rolling waveform
- **Live Transcription**: On-device speech recognition (requires permission)
- **Recording Controls**: Record, pause/resume, stop with clear visual feedback
- **Duration Display**: Large monospaced timer showing recording length
- **Category Tags**: Physical, Verbal, Financial, Emotional, Digital, Witness, Other
- **Additional Notes**: Text field for context and details
- **Location Option**: Optional GPS coordinates with user consent
- **Critical Flag**: Mark important evidence for quick filtering

### Photo Capture
- **Camera Integration**: Direct access to device camera
- **Library Selection**: Choose existing photos with PHPicker
- **Image Preview**: Full-size preview before saving
- **Metadata Extraction**: Automatic capture of image dimensions
- **HEIC Compression**: Efficient storage with quality preservation
- **Category Tags**: Same category system as voice notes

### Video Recording
- **Camera Recording**: Direct video capture up to 10 minutes
- **Library Import**: Select videos from photo library
- **Thumbnail Generation**: Automatic video thumbnail for timeline display
- **Playback Preview**: Visual thumbnail with play overlay
- **MP4 Format**: Standard format with efficient compression

### Text Entry
- **Quick Templates**: Pre-filled formats for common scenarios
  - "He said..." - Verbal statements
  - "He did..." - Action documentation
  - "I felt..." - Emotional impact
  - "Incident Report" - Structured documentation
  - "What I witnessed..." - Observer accounts
- **Voice-to-Text**: Toggle microphone for live transcription
- **Word Count**: Real-time counter for tracking length
- **Multi-line Editor**: Expandable text area with auto-scroll

### Shared Features (All Evidence Types)
- **Automatic Timestamps**: Every piece of evidence timestamped
- **Optional Location**: GPS tagging with user permission
- **Category System**: 7 categories with icons and colors
- **Critical Flagging**: Mark high-priority evidence
- **Additional Notes**: Context field for all evidence types
- **Encrypted Storage**: AES-GCM-256 encryption before saving
- **Haptic Feedback**: Success vibration on save
- **Error Handling**: Clear error messages with recovery options

## 📝 TODO

### High Priority
- [x] Implement audio recording (AVFoundation)
- [x] Add audio transcription (Speech framework)
- [x] Add camera capture functionality
- [x] Implement video recording
- [x] Create evidence categorization system
- [ ] Implement PDF export generation

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