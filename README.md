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
- [♿ Accessibility](#-accessibility)
  - [VoiceOver Support](#voiceover-support)
  - [Dynamic Type](#dynamic-type)
  - [Accessibility Features](#accessibility-features)
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
- [☁️ Backend Integration (Optional Cloud Sync)](#️-backend-integration-optional-cloud-sync)
  - [Current Status](#current-status)
  - [What's Implemented](#whats-implemented)
  - [How to Use](#how-to-use)
  - [API Endpoints](#api-endpoints)
  - [Privacy & Security](#privacy--security-1)
- [📝 TODO](#-todo)
  - [High Priority](#high-priority)
  - [Medium Priority](#medium-priority)
  - [Low Priority](#low-priority)
- [🌐 Future Backend Requirements](#-future-backend-requirements)
  - [Community Features Backend](#community-features-backend)
  - [Optional Cloud Sync](#optional-cloud-sync)
  - [Professional Services Integration](#professional-services-integration)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)
- [🆘 Emergency Resources](#-emergency-resources)
- [📚 Appendix](#-appendix)
  - [Evidence Preview & Change Tracking Implementation](#evidence-preview--change-tracking-implementation)

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

## ♿ Accessibility

VoiceIt is designed to be fully accessible to all users, following Apple's Human Interface Guidelines.

### VoiceOver Support

**Comprehensive Screen Reader Support:**
- All UI elements have descriptive labels and hints
- Evidence rows announce complete information (type, timestamp, location, tags, notes)
- Custom announcements for important actions ("Evidence saved", "Emergency activated")
- Grouped elements for logical navigation
- Custom swipe actions with clear labels

**Key VoiceOver Features:**
- Timeline evidence items: Full context including duration, file size, critical status
- Panic button: "Press and hold for 3 seconds to activate emergency mode"
- Settings toggles: Announce state changes ("Face ID enabled")
- Emergency contacts: Relationship and auto-notify status read aloud

### Dynamic Type

**Full Dynamic Type Support:**
- Text scales from Extra Small to AAAExtra Large
- Layouts adapt to larger text sizes
- Multi-line text wraps naturally
- Minimum scale factor ensures readability
- All fonts use system Dynamic Type sizes

### Accessibility Features

**Built-in Accessibility:**
- ✅ VoiceOver labels on all interactive elements
- ✅ Accessibility hints for complex gestures
- ✅ Accessibility identifiers for UI testing
- ✅ Dynamic Type support (XS to AAAExtra Large)
- ✅ High contrast text and colors (WCAG AA compliant)
- ✅ Reduced motion support
- ✅ Semantic content attributes
- ✅ Custom accessibility announcements
- ✅ Grouped accessibility elements
- ✅ Touch target sizes (minimum 44x44 points)

**Privacy-Sensitive Content:**
- Password fields marked as private
- Evidence content can be hidden in sensitive contexts
- Screenshot protection for sensitive screens

**Testing:**
- Enable VoiceOver: Settings → Accessibility → VoiceOver
- Test Dynamic Type: Settings → Accessibility → Display & Text Size
- See [ACCESSIBILITY.md](ACCESSIBILITY.md) for full testing guide

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
- 🖼️ **Inline Photo Preview**: Tap photo evidence to expand full-size preview directly in timeline
  - Smooth expand/collapse animation
  - On-demand image loading (decryption only when needed)
  - View notes and metadata inline
  - Quick access to full details view
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

## ☁️ Backend Integration (Optional Cloud Sync)

The app now supports **optional** backend integration with `https://voiceitnow.org` for account creation and future cloud sync capabilities.

### Current Status

**⚠️ Authentication Only (January 2025)**

✅ **Working Now:**
- User signup and login
- Token-based authentication
- Secure token storage in Keychain
- Account management UI

🚧 **Coming Soon:**
- Cloud evidence sync (backend endpoints pending)
- Cross-device synchronization
- Cloud backup

The sync functionality displays a "Coming Soon" badge in Settings until backend timeline endpoints are implemented.

### What's Implemented

#### 1. APIService (`Services/APIService.swift`)
Complete API client for backend communication:

**Authentication:**
```swift
// Sign up
let response = try await APIService.shared.signUp(
    email: "user@example.com",
    password: "password123",
    name: "Jane Doe"
)

// Login
let response = try await APIService.shared.login(
    email: "user@example.com",
    password: "password123"
)

// Logout
APIService.shared.logout()
```

**Features:**
- Automatic token storage in iOS Keychain (encrypted)
- User session management
- Token verification
- Password reset requests
- Swift 6 concurrency compliant

#### 2. TimelineSyncService (`Services/TimelineSyncService.swift`)
Service ready for syncing evidence to backend once endpoints are available:

```swift
// Sync all evidence (when endpoints ready)
try await TimelineSyncService.shared.syncAllEvidence(modelContext: modelContext)

// Sync single item
try await TimelineSyncService.shared.syncEvidence(evidence)
```

**Features:**
- Optional sync (disabled by default)
- Syncs all evidence types (text, voice, photo, video)
- Preserves metadata (tags, critical flag, timestamps)
- SwiftData-safe with @MainActor
- Last sync timestamp tracking

#### 3. AccountManagementView (`Views/Settings/AccountManagementView.swift`)
Beautiful SwiftUI interface for account management:

**Login Screen:**
- Email and password fields
- "Forgot Password" option
- Switch to signup
- "Skip for Now" option

**Signup Screen:**
- Name (optional), email, password
- Password confirmation with live validation
- Privacy reassurance message

**Logged In Screen:**
- User account information
- Sync toggle (disabled with "Coming Soon" badge)
- Logout button

#### 4. Settings Integration
New "Cloud Sync (Optional)" section with:
- "Coming Soon" badge
- Authentication status indicator
- Quick access to account management

### How to Use

#### For Users

**Accessing Account Management:**
1. Open **Settings** tab
2. Tap **"Cloud Sync (Optional)"** → **"Sign In / Sign Up"**

**Creating an Account:**
1. Enter email and password (6+ characters)
2. Optionally add your name
3. Tap "Create Account"
4. Token automatically saved to Keychain

**Logging In:**
1. Enter email and password
2. Tap "Log In"
3. Stay signed in across app restarts

**Logging Out:**
1. In account settings, tap "Log Out"
2. Token cleared from Keychain
3. App continues working in local-only mode

#### For Developers

**Accessing Services:**
```swift
import SwiftUI

struct MyView: View {
    @Environment(\.apiService) private var apiService
    @Environment(\.timelineSyncService) private var syncService
    
    var body: some View {
        // Use services
    }
}
```

**Check Auth Status:**
```swift
if APIService.shared.isAuthenticated {
    print("Logged in as: \(APIService.shared.currentUser?.email ?? "")")
}
```

### API Endpoints

#### Currently Implemented on Backend

**Authentication:**
- `POST /api/auth/signup` - Create new account
- `POST /api/auth/login` - Sign in
- `POST /api/auth/logout` - Sign out
- `POST /api/auth/verify` - Verify token
- `POST /api/auth/forgot-password` - Request password reset

**Waitlist:**
- `POST /api/app/waitlist` - Join waitlist

#### Needed for Cloud Sync (Coming Soon)

**Timeline Endpoints:**
```
GET  /api/timeline/entries
POST /api/timeline/entries
```

**Expected Request/Response:**
```swift
// POST /api/timeline/entries
{
  "type": "voice|text|photo|video",
  "content": "Evidence content or transcription",
  "timestamp": "2025-01-08T10:30:00Z",
  "metadata": {
    "isCritical": "true",
    "tags": "physical,verbal",
    "duration": "45.2"
  }
}

// Response
{
  "success": true,
  "entry": {
    "id": "uuid",
    "userId": "user-uuid",
    "type": "voice",
    "content": "...",
    "timestamp": "...",
    "metadata": {...},
    "createdAt": "..."
  }
}
```

### Privacy & Security

#### What Stays Local (Always)
- ✅ All evidence data encrypted on device
- ✅ Biometric authentication (Face ID/Touch ID)
- ✅ Passcode stored in Keychain (local only)
- ✅ Location data and encryption keys
- ✅ Actual media files (photos, videos, audio)

#### What Syncs to Backend (When Available)
When sync is enabled:
- Evidence metadata (type, timestamp, tags, critical flag)
- Text content from entries (encrypted in transit)
- Transcriptions from voice notes
- Evidence notes and descriptions

**Note:** Actual media files are **not uploaded** in current implementation.

#### Security Features
- 🔒 Auth tokens stored in iOS Keychain (encrypted)
- 🔒 HTTPS/TLS for all API requests
- 🔒 Token-based authentication (Bearer token)
- 🔒 30-second request timeout
- 🔒 Sync is **opt-in** (disabled by default)
- 🔒 User can log out anytime (token cleared immediately)
- 🔒 App works 100% offline without backend

#### Architecture Benefits
- **Local-First**: App fully functional without internet
- **Privacy-First**: Cloud sync is optional, not required
- **Modular**: Backend integration cleanly separated
- **Secure**: No user data sent without explicit consent

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
- [x] **Implement accessibility features** (VoiceOver, Dynamic Type)
  - [x] VoiceOver labels and hints for all UI elements
  - [x] Dynamic Type support (XS to AAAExtra Large)
  - [x] Accessibility announcements for state changes
  - [x] Semantic content attributes
  - [x] Accessibility identifiers for testing
  - [x] High contrast colors (WCAG AA compliant)
  - [x] Touch target sizes (44x44 minimum)
  - [x] Comprehensive accessibility documentation
- [ ] Create app icon and launch screen
- [ ] Add App Store assets
- [ ] Additional decoy screens (Music, Maps, etc.)
- [ ] Panic button gesture alternatives
- [ ] Emergency contact import from Contacts app

## 🌐 Future Backend Requirements

Currently, VoiceIt operates **100% locally** with all data stored on-device. However, several features would benefit from optional backend infrastructure. This section outlines where and why backend services would be needed.

### Community Features Backend

**Current Status**: Mock data for demonstration  
**Backend Required For**: Full community functionality

#### 1. Support Groups Backend

**Location**: `VoiceIt/Services/CommunityService.swift` (lines ~50-150)

**Required Backend Services**:
```
Backend Endpoint Structure:

POST   /api/v1/groups                    # Create support group
GET    /api/v1/groups                    # List all groups
GET    /api/v1/groups/:id                # Get group details
GET    /api/v1/groups/:id/posts          # Get group posts
POST   /api/v1/groups/:id/posts          # Create post (anonymous)
POST   /api/v1/posts/:id/report          # Report inappropriate content
GET    /api/v1/groups/:id/moderators     # Get moderator info
```

**Database Schema Needed**:
```sql
-- Support Groups
CREATE TABLE support_groups (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    description TEXT,
    topic VARCHAR(100),
    member_count INT,
    moderator_name VARCHAR(255),
    moderator_credentials VARCHAR(255),
    created_at TIMESTAMP,
    is_active BOOLEAN
);

-- Posts (Anonymous)
CREATE TABLE group_posts (
    id UUID PRIMARY KEY,
    group_id UUID REFERENCES support_groups(id),
    author_pseudonym VARCHAR(100), -- Auto-generated, no real identity
    content TEXT,
    created_at TIMESTAMP,
    is_moderated BOOLEAN,
    reported_count INT
);

-- Content Moderation
CREATE TABLE post_reports (
    id UUID PRIMARY KEY,
    post_id UUID REFERENCES group_posts(id),
    reason VARCHAR(255),
    reported_at TIMESTAMP,
    status VARCHAR(50) -- 'pending', 'reviewed', 'removed'
);
```

**Privacy Requirements**:
- Zero-knowledge architecture: Backend never knows real user identities
- Pseudonyms generated client-side with no linkage to user accounts
- E2E encryption for posts (optional)
- No IP logging or tracking
- Moderation done by certified professionals (LCSW, attorneys)

**Technology Recommendations**:
- **Backend**: Node.js/Express, Python/FastAPI, or Ruby/Rails
- **Database**: PostgreSQL with row-level security
- **Real-time**: WebSockets for live group updates
- **Moderation**: Admin dashboard for moderators
- **Hosting**: Privacy-focused providers (e.g., OVH, Hetzner)

---

#### 2. Therapy Sessions Backend

**Location**: `VoiceIt/Services/CommunityService.swift` (lines ~150-250)

**Required Backend Services**:
```
Backend Endpoint Structure:

GET    /api/v1/therapists                # List available therapists
GET    /api/v1/therapists/:id            # Get therapist details
GET    /api/v1/therapists/:id/slots      # Get available time slots
POST   /api/v1/sessions/book             # Book session (anonymous)
GET    /api/v1/sessions/:id              # Get session details
POST   /api/v1/sessions/:id/cancel       # Cancel session
POST   /api/v1/sessions/:id/feedback     # Submit rating/feedback
GET    /api/v1/sessions/upcoming         # Get user's upcoming sessions
```

**Database Schema Needed**:
```sql
-- Therapists
CREATE TABLE therapists (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    credentials VARCHAR(255), -- PhD, LMFT, PsyD, LCSW
    specializations TEXT[],   -- Array of specialties
    languages TEXT[],         -- Supported languages
    bio TEXT,
    rating DECIMAL(3,2),
    review_count INT,
    session_duration_minutes INT DEFAULT 30,
    is_pro_bono BOOLEAN DEFAULT true,
    is_active BOOLEAN,
    created_at TIMESTAMP
);

-- Available Time Slots
CREATE TABLE therapist_availability (
    id UUID PRIMARY KEY,
    therapist_id UUID REFERENCES therapists(id),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    is_booked BOOLEAN DEFAULT false,
    timezone VARCHAR(50)
);

-- Sessions (Anonymized)
CREATE TABLE therapy_sessions (
    id UUID PRIMARY KEY,
    therapist_id UUID REFERENCES therapists(id),
    anonymous_user_token VARCHAR(255), -- Hashed user identifier
    scheduled_time TIMESTAMP,
    duration_minutes INT,
    status VARCHAR(50), -- 'scheduled', 'completed', 'cancelled', 'no-show'
    video_room_id VARCHAR(255), -- For video conferencing
    rating INT,
    feedback TEXT,
    created_at TIMESTAMP
);
```

**Integration Requirements**:
- **Video Conferencing**: Zoom API, Twilio Video, or Jitsi (open source)
- **Scheduling**: Calendar integration (iCal export)
- **Notifications**: Push notifications for reminders (via APNs)
- **Payments**: If transitioning to paid model (Stripe)

**Privacy Requirements**:
- Session links are single-use and expire after session
- No video/audio recording without explicit consent
- End-to-end encryption for video (WebRTC)
- Therapist-patient confidentiality maintained
- HIPAA compliance if operating in US

---

#### 3. Legal Consultations Backend

**Location**: `VoiceIt/Services/CommunityService.swift` (lines ~250-350)

**Required Backend Services**:
```
Backend Endpoint Structure:

GET    /api/v1/lawyers                   # List available lawyers
GET    /api/v1/lawyers/:id               # Get lawyer details
POST   /api/v1/consultations/request     # Request consultation
GET    /api/v1/consultations/:id         # Get consultation details
POST   /api/v1/consultations/:id/upload  # Upload documents (encrypted)
GET    /api/v1/consultations/:id/files   # List shared files
POST   /api/v1/messages                  # Send secure message
GET    /api/v1/messages/:consultation_id # Get message thread
```

**Database Schema Needed**:
```sql
-- Lawyers
CREATE TABLE lawyers (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    bar_number VARCHAR(100),
    state_jurisdiction VARCHAR(50),
    practice_areas TEXT[], -- Domestic Violence, Family Law, etc.
    bio TEXT,
    rating DECIMAL(3,2),
    review_count INT,
    offers_free_consultation BOOLEAN DEFAULT true,
    consultation_duration_minutes INT DEFAULT 30,
    is_active BOOLEAN,
    verified_at TIMESTAMP,
    created_at TIMESTAMP
);

-- Consultations (Anonymized)
CREATE TABLE legal_consultations (
    id UUID PRIMARY KEY,
    lawyer_id UUID REFERENCES lawyers(id),
    anonymous_user_token VARCHAR(255),
    scheduled_time TIMESTAMP,
    status VARCHAR(50), -- 'requested', 'confirmed', 'completed', 'declined'
    case_type VARCHAR(100),
    brief_description TEXT, -- Encrypted
    created_at TIMESTAMP
);

-- Secure Document Sharing
CREATE TABLE shared_documents (
    id UUID PRIMARY KEY,
    consultation_id UUID REFERENCES legal_consultations(id),
    file_name VARCHAR(255),
    file_size_bytes BIGINT,
    encrypted_url TEXT, -- S3 presigned URL or similar
    uploaded_by VARCHAR(50), -- 'user' or 'lawyer'
    uploaded_at TIMESTAMP,
    expires_at TIMESTAMP -- Auto-delete after case closure
);

-- Secure Messaging
CREATE TABLE consultation_messages (
    id UUID PRIMARY KEY,
    consultation_id UUID REFERENCES legal_consultations(id),
    sender_type VARCHAR(50), -- 'user' or 'lawyer'
    message_content TEXT, -- End-to-end encrypted
    sent_at TIMESTAMP,
    read_at TIMESTAMP
);
```

**Security Requirements**:
- End-to-end encryption for all messages and documents
- Attorney-client privilege protection
- Automatic document expiration (30-90 days)
- Zero-knowledge file storage (client-side encryption)
- Audit logs for compliance

**Technology Recommendations**:
- **File Storage**: S3-compatible with client-side encryption (MinIO, Backblaze B2)
- **Encryption**: AES-256 with per-consultation keys
- **Messaging**: Signal Protocol or similar E2E encryption
- **Compliance**: SOC 2 compliance for legal industry

---

#### 4. Resource Library Backend

**Location**: `VoiceIt/Services/CommunityService.swift` (lines ~350-450)

**Required Backend Services**:
```
Backend Endpoint Structure:

GET    /api/v1/articles                  # List articles
GET    /api/v1/articles/:id              # Get article content
GET    /api/v1/articles/search           # Search articles
GET    /api/v1/downloads/:id             # Download checklist/guide
POST   /api/v1/articles/:id/analytics    # Track article views (anonymous)
```

**Database Schema Needed**:
```sql
-- Articles
CREATE TABLE community_articles (
    id UUID PRIMARY KEY,
    title VARCHAR(255),
    subtitle VARCHAR(500),
    author VARCHAR(255),
    author_credentials VARCHAR(255),
    content TEXT,
    article_type VARCHAR(50), -- 'article', 'video', 'checklist', 'guide', 'story'
    category VARCHAR(50), -- 'legal', 'safety', 'healing', 'financial', 'childcare'
    reading_time_minutes INT,
    view_count INT DEFAULT 0,
    published_at TIMESTAMP,
    updated_at TIMESTAMP,
    is_featured BOOLEAN,
    tags TEXT[]
);

-- Downloadable Resources
CREATE TABLE downloadable_resources (
    id UUID PRIMARY KEY,
    article_id UUID REFERENCES community_articles(id),
    title VARCHAR(255),
    file_type VARCHAR(50), -- 'pdf', 'docx', 'checklist'
    file_url TEXT,
    file_size_bytes BIGINT,
    download_count INT DEFAULT 0
);
```

**Technology**: Simple CMS or headless CMS (Strapi, Directus, or Ghost)

---

### Optional Cloud Sync

**Current Status**: 100% local storage  
**Backend Required For**: Cross-device sync and encrypted cloud backup

**Why Users Might Want This**:
- Backup evidence in case device is lost/destroyed
- Access evidence from multiple devices
- Transfer evidence when upgrading phones

**Privacy-First Cloud Sync Architecture**:

```
Backend Endpoint Structure:

POST   /api/v1/auth/register             # Register anonymous account
POST   /api/v1/auth/login                # Login with device token
POST   /api/v1/sync/upload               # Upload encrypted evidence
GET    /api/v1/sync/download             # Download encrypted evidence
DELETE /api/v1/sync/wipe                 # Remote wipe all data
GET    /api/v1/sync/status               # Get sync status
```

**Database Schema**:
```sql
-- Anonymous User Accounts
CREATE TABLE user_accounts (
    id UUID PRIMARY KEY,
    device_token VARCHAR(255) UNIQUE, -- Hashed device ID
    encrypted_master_key TEXT, -- User's master key, encrypted with device password
    storage_used_bytes BIGINT DEFAULT 0,
    last_sync_at TIMESTAMP,
    created_at TIMESTAMP
);

-- Encrypted Evidence Blobs
CREATE TABLE encrypted_evidence (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES user_accounts(id),
    evidence_id UUID, -- Client-side evidence ID
    encrypted_blob BYTEA, -- Fully encrypted evidence
    blob_size_bytes BIGINT,
    evidence_type VARCHAR(50),
    uploaded_at TIMESTAMP,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP -- Soft delete
);
```

**Zero-Knowledge Requirements**:
- Client encrypts all data before upload
- Server never has decryption keys
- Server only stores encrypted blobs
- Metadata is also encrypted
- User can remote wipe all data

**Technology Recommendations**:
- **Backend**: Go (for performance), Rust (for security)
- **Storage**: Object storage with encryption at rest
- **Database**: PostgreSQL with full disk encryption
- **Hosting**: Privacy-focused (Switzerland, Iceland data centers)

**Implementation Location**:
- Create new `CloudSyncService.swift` in `VoiceIt/Services/`
- Add settings in `SettingsView.swift` under Privacy section
- Implement E2E encryption in `EncryptionService.swift`

---

### Professional Services Integration

**Backend Required For**: Real therapist/lawyer provider networks

#### Third-Party Integrations Needed

1. **Therapist Network API**:
   - Integration with platforms like BetterHelp API, TalkSpace API
   - Verify therapist credentials via national databases
   - Real-time availability calendars

2. **Legal Network API**:
   - Integration with LegalZoom, Avvo, or state bar associations
   - Verify bar certifications
   - Pro bono matching algorithms

3. **Video Conferencing**:
   - Zoom SDK, Twilio Video, or Jitsi
   - HIPAA-compliant video for therapy sessions
   - Recording controls with consent

4. **Payment Processing** (If moving beyond free tier):
   - Stripe for payments
   - Sliding scale payment options
   - Pro bono voucher system

**Implementation Note**: These would require separate API contracts and likely backend middleware to coordinate between VoiceIt and third-party services.

---

### Deployment Architecture Recommendation

```
┌─────────────────────────────────────────────────┐
│                 iOS App (VoiceIt)               │
│            100% Local Evidence Storage          │
└─────────────┬───────────────────────────────────┘
              │
              │ HTTPS/TLS 1.3
              │
┌─────────────▼───────────────────────────────────┐
│           API Gateway (NGINX/Traefik)           │
│          Rate Limiting + DDoS Protection        │
└─────────────┬───────────────────────────────────┘
              │
    ┌─────────┴─────────┬──────────────┬──────────┐
    │                   │              │          │
┌───▼─────────┐  ┌──────▼──────┐  ┌───▼────┐  ┌─▼─────────┐
│ Community   │  │  Sync       │  │ Search │  │ Analytics │
│ Service     │  │  Service    │  │ Service│  │ Service   │
│ (Node.js)   │  │  (Go)       │  │ (ES)   │  │ (Optional)│
└─────┬───────┘  └──────┬──────┘  └────────┘  └───────────┘
      │                 │
┌─────▼─────────────────▼─────────────────────────┐
│         PostgreSQL (Primary Database)           │
│         - Encrypted at rest                     │
│         - Row-level security                    │
│         - Regular backups to cold storage       │
└─────────────────────────────────────────────────┘
                      │
            ┌─────────┴──────────┐
            │                    │
      ┌─────▼─────┐      ┌──────▼──────┐
      │  S3/MinIO │      │    Redis    │
      │  Encrypted│      │   Cache     │
      │   Storage │      │             │
      └───────────┘      └─────────────┘
```

**Estimated Backend Costs** (for 10,000 active users):
- **Infrastructure**: $200-500/month (Digital Ocean, Hetzner)
- **Database**: $100/month (Managed PostgreSQL)
- **Storage**: $50/month (Object storage for files)
- **CDN**: $50/month (CloudFlare or similar)
- **Total**: ~$400-700/month

**Development Estimate**: 3-6 months for full community backend

---

### Privacy-First Backend Principles

All backend services MUST follow these principles:

1. **Zero-Knowledge Architecture**: Server never decrypts user evidence
2. **No Analytics by Default**: No tracking, no user profiling
3. **Minimal Data Collection**: Only collect what's absolutely necessary
4. **Open Source**: Backend code should be open source for audit
5. **GDPR/CCPA Compliant**: Right to deletion, data portability
6. **Regular Security Audits**: Third-party penetration testing
7. **Transparency Reports**: Publish data on any government requests
8. **Data Residency**: Allow users to choose data location
9. **No Third-Party Trackers**: No Google Analytics, Facebook pixels, etc.
10. **Encryption Everywhere**: TLS 1.3, E2E encryption, encrypted backups

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

## 📚 Appendix

### Evidence Preview & Change Tracking Implementation

**Last Updated**: October 7, 2025

This section documents the evidence preview and change tracking system that allows users to view detailed evidence previews and maintains a complete audit trail of all modifications.

#### Overview

Users can now:
- **Click any evidence item** in the timeline to view full details
- **Edit text entries** while preserving all previous versions
- **View change history** for all evidence types
- **See full-size photo previews** with metadata
- **Track modifications** with timestamps and descriptions

#### Key Features

1. **Expandable Detail Views**
   - Tap any evidence item to navigate to `EvidenceDetailView`
   - Photos display full-size with decryption on-demand
   - Text entries show complete content with word count
   - Voice notes display transcription and audio information
   - Video evidence shows thumbnails and metadata

2. **Comprehensive Change Tracking**
   - All modifications recorded with timestamps
   - Before/after content comparison
   - Optional change descriptions
   - Visual timeline of changes
   - Immutable history (cannot be deleted)

3. **Text Entry Editing**
   - Full-screen editor with live preview
   - Side-by-side comparison of changes
   - Word count tracking (additions/removals)
   - Optional context descriptions
   - Original content always preserved

4. **Legal Integrity**
   - Complete audit trail for legal documentation
   - Tamper-evident history
   - Timestamped modifications
   - Encrypted along with evidence
   - Automatic cascade delete with evidence

#### Technical Implementation

**New Models:**
- `ChangeHistory.swift` - Tracks all evidence modifications
  - Stores previous and new content
  - Links to parent evidence via relationships
  - Supports all evidence types

**New Views:**
- `EvidenceDetailView.swift` - Main detail view for all evidence types
- `ChangeHistoryView.swift` - Visual timeline component
- `EditTextEntrySheet.swift` - Text editing interface

**Modified Models:**
- All evidence models (`TextEntry`, `PhotoEvidence`, `VoiceNote`, `VideoEvidence`) now include:
  - `changeHistory: [ChangeHistory]` relationship
  - `updateNotes(_:)` method for tracking note changes
  - `updateBodyText(_:description:)` method (TextEntry only)
  - Automatic creation history entry on initialization

**Modified Views:**
- `TimelineView.swift` - Added `NavigationLink` to detail views

#### Change Types Tracked

- **Created**: Initial evidence creation
- **Content Modified**: Text content changed (preserves original)
- **Note Added**: First note added to evidence
- **Note Modified**: Note updated
- **Tag Added**: Tag added to evidence
- **Tag Removed**: Tag removed from evidence
- **Marked Critical**: Evidence flagged as critical
- **Unmarked Critical**: Critical status removed

#### Data Flow

```swift
// Creating evidence
TextEntry(bodyText: "Initial content")
  → Automatically adds "Created" change history entry

// Editing text entry
textEntry.updateBodyText("Updated content", description: "Added more details")
  → Stores original: "Initial content"
  → Stores new: "Updated content"
  → Creates "Content Modified" history entry with timestamp

// Viewing history
EvidenceDetailView → ChangeHistoryView
  → Displays all changes in chronological order
  → Shows before/after comparison for modifications
```

#### Security & Privacy

- All change history is **encrypted** with the evidence
- History uses **cascade delete** (deleted with evidence)
- No ability to modify or delete history (audit integrity)
- Timestamps use device local time
- Changes stored in **SwiftData** with evidence models

#### File Organization

```
VoiceIt/
├── Models/Evidence/
│   ├── ChangeHistory.swift          [NEW]
│   ├── TextEntry.swift              [MODIFIED]
│   ├── PhotoEvidence.swift          [MODIFIED]
│   ├── VoiceNote.swift              [MODIFIED]
│   └── VideoEvidence.swift          [MODIFIED]
└── Views/Timeline/
    ├── EvidenceDetailView.swift     [NEW]
    ├── TimelineView.swift           [MODIFIED]
    └── Components/
        ├── ChangeHistoryView.swift  [NEW]
        └── EditTextEntrySheet.swift [NEW]
```

#### User Experience Flow

1. **Viewing Evidence Details**:
   - **Photos**: Tap to expand inline preview on timeline page (new!)
     - View full-size image without navigation
     - See notes and metadata
     - Option to view full details if needed
   - **Other evidence**: Tap to navigate to detail view
   - See full content preview with metadata
   - Scroll to view change history timeline
   - Location and tags displayed if available

2. **Editing Text Entries**:
   - Tap "Edit" button in detail view
   - Modify text in full-screen editor
   - See real-time comparison of changes
   - Add optional change description
   - Save → Original preserved in history

3. **Change History Timeline**:
   - Visual timeline with color-coded icons
   - Newest changes at top
   - Before/after comparison for modifications
   - Timestamps and optional descriptions
   - Icons indicate change type

#### Migration Notes

⚠️ **Breaking Change**: Existing evidence will not have change history.

- Old evidence shows only current state
- New evidence created after this update has full tracking
- Consider adding migration script to backfill creation history
- No data loss - only missing historical change records

#### Performance Considerations

- Images loaded **on-demand** in detail view (not in timeline)
- Change history **lazy loaded** via SwiftData relationships
- No performance impact on timeline scrolling
- Cascade delete prevents orphaned history records

#### Build Status

✅ **Build Successful** - October 7, 2025  
✅ **No Linter Errors**  
✅ **XcodeGen Integration** - Auto-includes new files  
✅ **Swift 6 Concurrency** - Fully compliant

#### Future Enhancements

Potential improvements:
- Edit notes/captions on photos and videos
- Text diff highlighting in change comparison
- Revert to previous version capability
- Export change history in PDF/Word documents
- Image comparison overlays (before/after edits)

---

**Built with Swift 6, SwiftUI, and a commitment to user safety and privacy.**