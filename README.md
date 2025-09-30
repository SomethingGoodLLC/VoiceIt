# Voice It - Evidence Documentation App

A privacy-first iOS application built with Swift 6 and SwiftUI for documenting and managing evidence in sensitive situations.

## 📑 Table of Contents

- [🚀 Quick Start](#-quick-start)
  - [Prerequisites](#prerequisites)
  - [Running the App](#running-the-app)
- [🏗️ Architecture (2025 Best Practices)](#️-architecture-2025-best-practices)
  - [Technology Stack](#technology-stack)
  - [Architecture Patterns](#architecture-patterns)
- [📁 Project Structure](#-project-structure)
- [🎨 Design System](#-design-system)
  - [Colors](#colors)
  - [UI Patterns](#ui-patterns)
- [🔐 Security & Privacy](#-security--privacy)
  - [Encryption](#encryption)
  - [Authentication](#authentication)
  - [Privacy](#privacy)
- [🚀 Features](#-features)
  - [Evidence Management](#evidence-management)
  - [Timeline Features](#timeline-features)
  - [Location Tracking](#location-tracking)
  - [Emergency Features](#emergency-features)
  - [Export Options](#export-options)
  - [Support Resources](#support-resources)
  - [Community (Privacy-First Support Network)](#community-privacy-first-support-network)
- [🛠️ Development](#️-development)
  - [Swift 6 Concurrency Guidelines](#swift-6-concurrency-guidelines)
  - [SwiftData Best Practices](#swiftdata-best-practices)
  - [Service Layer Pattern](#service-layer-pattern)
- [🧪 Testing](#-testing)
  - [Unit Tests](#unit-tests-to-be-implemented)
  - [Integration Tests](#integration-tests-to-be-implemented)
  - [Manual Testing Checklist](#manual-testing-checklist)
- [🐛 Troubleshooting](#-troubleshooting)
  - [Build Errors](#build-errors)
  - [Runtime Issues](#runtime-issues)
  - [Simulator Issues](#simulator-issues)
- [📋 Configuration](#-configuration)
  - [Required Capabilities](#required-capabilities)
  - [Info.plist Permissions](#infoplist-permissions-already-configured)
  - [Customization](#customization)
- [🎯 Add Evidence Features](#-add-evidence-features)
  - [Main Interface](#main-interface)
  - [Voice Note Recording](#voice-note-recording)
  - [Photo Capture](#photo-capture)
  - [Video Recording](#video-recording)
  - [Text Entry](#text-entry)
  - [Shared Features](#shared-features-all-evidence-types)
- [📝 TODO](#-todo)
  - [High Priority](#high-priority)
  - [Medium Priority](#medium-priority)
  - [Low Priority](#low-priority)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)
- [🆘 Emergency Resources](#-emergency-resources)

---

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
│   ├── VoiceItApp.swift              # App entry point with service injection
│   └── ContentView.swift              # Main tab container with panic button
├── Models/
│   ├── Evidence/
│   │   ├── EvidenceProtocol.swift     # Common evidence protocol
│   │   ├── VoiceNote.swift            # Audio evidence with transcription
│   │   ├── PhotoEvidence.swift        # Photo evidence with metadata
│   │   ├── VideoEvidence.swift        # Video evidence with thumbnails
│   │   └── TextEntry.swift            # Text notes with templates
│   ├── Community/
│   │   ├── SupportGroup.swift         # Anonymous support groups
│   │   ├── Therapist.swift            # Pro bono therapists
│   │   ├── Lawyer.swift               # Pro bono legal consultations
│   │   └── CommunityArticle.swift     # Educational resources
│   ├── EvidenceCategory.swift         # Evidence categorization
│   ├── LocationSnapshot.swift         # GPS tracking data
│   ├── EmergencyContact.swift         # Emergency contacts with auto-notify
│   └── Resource.swift                 # Support resources
├── Services/
│   ├── EncryptionService.swift        # End-to-end encryption (AES-GCM-256)
│   ├── LocationService.swift          # Modern async/await GPS tracking
│   ├── ExportService.swift            # PDF/JSON exports
│   ├── EmergencyService.swift         # Panic button, 911, SMS alerts
│   ├── ResourceService.swift          # Find nearby resources
│   ├── AuthenticationService.swift    # Biometric security (Face ID/Touch ID)
│   ├── AudioRecordingService.swift    # Audio recording with waveform
│   ├── TranscriptionService.swift     # Speech-to-text transcription
│   ├── FileStorageService.swift       # Encrypted file management
│   ├── StealthModeService.swift       # Stealth mode with decoy screens
│   └── CommunityService.swift         # Community features with @Observable
├── Views/
│   ├── Onboarding/
│   │   └── OnboardingView.swift       # Privacy onboarding flow
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
│   ├── Emergency/
│   │   ├── PanicButtonView.swift      # Floating panic button with haptics
│   │   └── EmergencyContactsView.swift # Emergency contact management
│   ├── Stealth/
│   │   ├── StealthModeContainerView.swift      # Stealth mode wrapper
│   │   ├── StealthModeSettingsView.swift       # Stealth mode configuration
│   │   ├── CalculatorDecoyView.swift           # Calculator decoy screen
│   │   ├── WeatherDecoyView.swift              # Weather decoy screen
│   │   └── NotesDecoyView.swift                # Notes decoy screen
│   ├── Resources/
│   │   ├── ResourcesView.swift        # Support resources
│   │   └── ResourceDetailView.swift   # Resource details
│   └── Community/
│       ├── CommunityView.swift               # Main community navigation hub
│       ├── Components/
│       │   └── SimpleFilterChip.swift        # Filter chip component
│       ├── SupportGroups/
│       │   ├── SupportGroupsListView.swift   # Support groups list
│       │   ├── SupportGroupDetailView.swift  # Group details with posts
│       │   └── CreatePostView.swift          # Create anonymous post
│       ├── Therapy/
│       │   ├── TherapyListView.swift         # Therapists list
│       │   └── TherapistDetailView.swift     # Therapist details with booking
│       ├── Legal/
│       │   ├── LawyersListView.swift         # Lawyers list
│       │   └── LawyerDetailView.swift        # Lawyer details with booking
│       └── Resources/
│           ├── ResourceLibraryView.swift     # Resource library
│           └── ArticleDetailView.swift       # Article/guide details
├── Utilities/
│   ├── KeychainManager.swift          # Secure keychain operations
│   ├── Constants.swift                # App-wide constants
│   └── Extensions/
│       ├── Color+Theme.swift          # App color theme
│       ├── Date+Extensions.swift      # Date utilities
│       └── View+ShakeGesture.swift    # Shake gesture detection
└── Resources/
    └── Info.plist                     # App configuration with permissions
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
- 🚨 **Panic Button**: Persistent floating button with 3-second hold-to-activate
  - Draggable and minimizable for non-intrusive access
  - Hold for 3 seconds with visual progress ring
  - Countdown with "I'm Safe" cancel option
  - Actions upon activation:
    - Captures current GPS location
    - Starts silent audio recording
    - Sends SMS alerts to auto-notify emergency contacts
    - Dials 911 after 3-second countdown
    - Creates automatic evidence entry with timestamp
  - Haptic-only feedback for silent operation
  - Works even when app is in stealth mode
  
- 📞 **Emergency Contacts Management**: Complete contact management system
  - Add unlimited trusted contacts with relationship types
  - Mark primary contact for priority calling
  - Auto-notify flag for automatic SMS alerts
  - Test mode to verify setup without alerting contacts
  - Quick call and message actions via swipe gestures
  - Tracks last contacted timestamp
  - Supports email and notes for additional context
  
- 🕶️ **Stealth Mode**: Advanced privacy protection with decoy screens
  - Three realistic decoy screens:
    - Calculator: Fully functional calculator app
    - Weather: Realistic weather display
    - Notes: Convincing notes app interface
  - Shake device to instantly activate stealth mode
  - Swipe down from top of decoy screen to unlock
  - Biometric (Face ID/Touch ID) or passcode authentication required
  - Auto-hide after configurable inactivity period (1-30 minutes)
  - Automatic activation on app switcher detection (optional)
  - Seamless transition animations
  - All evidence remains encrypted and hidden
  
- 📍 **Location Tracking**: Privacy-preserving GPS tracking
  - Modern async/await CLLocationManager integration
  - Only captures location when:
    - Evidence is created
    - Emergency is activated
    - User explicitly requests it
  - Reverse geocoding for human-readable addresses
  - Low power mode option
  - Per-evidence location toggle
  - Accuracy indicators and timestamp tracking

### Export Options
- 📄 **PDF Export**: Legal-ready PDF documentation with:
  - Professional cover page with document ID and metadata
  - Chronologically ordered evidence entries
  - Full transcriptions, location data, and metadata
  - Cryptographic hash verification for authenticity
  - Unique document watermarks on every page
  - Password protection option
- 📝 **Word Export**: Microsoft Word-compatible RTF documents:
  - Fully editable format for annotations
  - Legal formatting with headers and footers
  - All evidence metadata and content preserved
  - Compatible with Word, Pages, and Google Docs
- 📊 **JSON Export**: Machine-readable format for data analysis
- 🔒 **Encrypted Export**: Password-protected files for maximum security
- ⚙️ **Advanced Export Options**:
  - Date range filtering
  - Evidence type selection (voice, photo, video, text)
  - Include/exclude location data
  - Include/exclude images
  - Password protection (6+ characters)
  - Real-time password validation

### Support Resources
- 🏥 **Find Shelters**: Nearby safe locations
- 📞 **Hotlines**: 24/7 crisis support numbers
- ⚖️ **Legal Aid**: Local legal resources
- 🌐 **Distance-based**: Sorted by proximity

### Community (Privacy-First Support Network)
- 💬 **Anonymous Support Groups**: Join moderated discussions without revealing identity
  - Topics: "First Steps", "Legal Journey", "Healing & Recovery", "Parenting Support", "Financial Independence"
  - Professional moderators (LCSW, attorneys, counselors)
  - Report harmful content
  - Optional pseudonyms (auto-generated: "BravePhoenix421")
  - Privacy notice: "Your identity is never shared"
  
- 🧠 **Free Therapy Sessions**: Pro bono 30-minute video sessions
  - Licensed therapists (PhD, LMFT, PsyD, LCSW)
  - Filter by specialization (Trauma, PTSD, Domestic Violence, Anxiety, etc.)
  - Filter by language support
  - Book time slots directly
  - Discreet calendar reminders
  - Rating/feedback system
  - All sessions are confidential and end-to-end encrypted
  
- ⚖️ **Legal Consultations**: Connect with pro bono lawyers
  - Filter by state/jurisdiction
  - Filter by practice area (Domestic Violence, Restraining Orders, Family Law, Child Custody, etc.)
  - Initial free consultations (30 minutes)
  - Secure document sharing (send evidence exports)
  - Bar-certified attorneys
  - Messaging system for follow-up questions
  
- 📚 **Resource Library**: Educational content and downloadable guides
  - Articles: "Understanding Restraining Orders", "Safety Planning 101", "Court Preparation"
  - Survivor stories (anonymous)
  - Downloadable checklists: "Leaving Safely", "Emergency Bag", "Financial Independence"
  - Expert videos and guides
  - Filter by category (Legal, Safety, Healing, Financial, Childcare, Stories)
  - Filter by content type (Article, Video, Checklist, Guide, Story)
  - Search functionality

**Privacy Features**:
- All interactions are anonymous by default
- Optional pseudonyms for support groups
- End-to-end encrypted messaging
- Local-first data storage with optional sync
- "Delete My Activity" option
- No analytics or tracking
- Clear privacy notices throughout

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

#### Core Functionality
- [ ] Onboarding flow completes
- [ ] Biometric authentication works (Face ID/Touch ID)
- [ ] Evidence creation (all 4 types: voice, photo, video, text)
- [ ] Timeline displays evidence correctly
- [ ] Timeline pull-to-refresh works
- [ ] Timeline swipe actions (share/delete) work
- [ ] Export banner displays correct item count
- [ ] Export options sheet presents correctly
- [ ] Evidence filtering works for all types
- [ ] Resources list loads
- [ ] Location permission handling

#### Safety Features
- [ ] **Panic Button**:
  - [ ] Button is draggable and stays on screen
  - [ ] Minimize/expand button works
  - [ ] Hold for 3 seconds shows progress ring
  - [ ] Haptic feedback occurs during hold
  - [ ] Countdown sheet appears after activation
  - [ ] "I'm Safe" cancel button works
  - [ ] Location captured on activation
  - [ ] Silent recording starts
  - [ ] Emergency contacts receive SMS alerts
  - [ ] 911 dial occurs after countdown
  
- [ ] **Emergency Contacts**:
  - [ ] Add new contact works
  - [ ] Edit existing contact works
  - [ ] Delete contact works
  - [ ] Reorder contacts by dragging
  - [ ] Primary contact badge displays
  - [ ] Auto-notify flag works
  - [ ] Test mode sends test messages
  - [ ] Swipe to call works
  - [ ] Phone number validation works
  
- [ ] **Stealth Mode**:
  - [ ] Shake gesture activates stealth mode
  - [ ] Calculator decoy screen appears and functions
  - [ ] Weather decoy screen appears
  - [ ] Notes decoy screen appears
  - [ ] Swipe down from top shows unlock prompt
  - [ ] Face ID/Touch ID authentication required
  - [ ] Unlock returns to actual app
  - [ ] Auto-hide after inactivity works
  - [ ] Settings allow decoy screen selection
  - [ ] Auto-hide timer configuration works
  
- [ ] **Location Tracking**:
  - [ ] Location captured with evidence
  - [ ] Reverse geocoding provides address
  - [ ] Location permission prompt appears
  - [ ] "When in use" permission works
  - [ ] GPS coordinates accurate
  - [ ] Location toggle per evidence works

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
- [x] **Panic button with hold-to-activate**
- [x] **Emergency contacts management**
- [x] **Stealth mode with decoy screens**
- [x] **Modern async/await location tracking**
- [x] **Comprehensive legal export system** (PDF, Word, JSON)
  - [x] PDF generation with cover pages and watermarks
  - [x] Word-compatible RTF documents
  - [x] Date range filtering
  - [x] Evidence type selection
  - [x] Password protection
  - [x] Cryptographic hash verification
- [x] **Community support network** (Privacy-first)
  - [x] Anonymous support groups with moderation
  - [x] Free therapy sessions with licensed therapists
  - [x] Pro bono legal consultations
  - [x] Resource library with articles, videos, and guides
  - [x] @Observable state management (iOS 18+)
  - [x] Mock data for demonstration

### Medium Priority
- [ ] **Community backend integration**
  - [ ] Real API integration for therapists and lawyers
  - [ ] Live video session infrastructure
  - [ ] Real-time messaging system
  - [ ] Content moderation system
  - [ ] User authentication for professionals
- [ ] Create comprehensive test suite
- [ ] Add data export encryption
- [ ] Implement auto-lock timer
- [ ] Add nearby resources API integration
- [ ] Background location tracking for emergencies
- [ ] Silent video recording option
- [ ] Custom emergency message templates
- [ ] Emergency contact groups

### Low Priority
- [ ] Add localization support
- [ ] Implement accessibility features (VoiceOver, Dynamic Type)
- [ ] Create app icon and launch screen
- [ ] Add App Store assets
- [ ] Additional decoy screens (Music, Maps, etc.)
- [ ] Panic button gesture alternatives
- [ ] Emergency contact import from Contacts app

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