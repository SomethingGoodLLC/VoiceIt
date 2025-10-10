@preconcurrency import SwiftUI
import SwiftData

@main
struct VoiceItApp: App {
    // MARK: - Properties
    
    /// SwiftData model container with encryption
    let modelContainer: ModelContainer
    
    /// Service dependencies
    private let encryptionService: EncryptionService
    private let locationService: LocationService
    private let exportService: ExportService
    private let emergencyService: EmergencyService
    private let resourceService: ResourceService
    private let authenticationService: AuthenticationService
    private let fileStorageService: FileStorageService
    private let stealthModeService: StealthModeService
    private let audioRecordingService: AudioRecordingService
    private let communityService: CommunityService
    private let notificationService: NotificationService
    private let apiService: APIService
    private let timelineSyncService: TimelineSyncService
    
    // MARK: - Initialization
    
    init() {
        // Configure SwiftData schema
        let schema = Schema([
            VoiceNote.self,
            PhotoEvidence.self,
            VideoEvidence.self,
            TextEntry.self,
            LocationSnapshot.self,
            EmergencyContact.self,
            Resource.self,
            SupportGroup.self,
            SupportGroupPost.self,
            Therapist.self,
            TherapySession.self,
            Lawyer.self,
            LegalConsultation.self,
            CommunityArticle.self
        ])
        
        // Configure model container with encryption
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        // Initialize services
        encryptionService = EncryptionService()
        locationService = LocationService()
        emergencyService = EmergencyService()
        resourceService = ResourceService()
        authenticationService = AuthenticationService()
        fileStorageService = FileStorageService(encryptionService: encryptionService)
        exportService = ExportService(encryptionService: encryptionService, fileStorageService: fileStorageService)
        stealthModeService = StealthModeService()
        audioRecordingService = AudioRecordingService()
        communityService = CommunityService()
        notificationService = NotificationService()
        apiService = APIService.shared
        timelineSyncService = TimelineSyncService.shared
        
        // Create required storage directories
        do {
            try Constants.Storage.createDirectories()
        } catch {
            print("Warning: Failed to create storage directories: \(error)")
        }
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(\.encryptionService, encryptionService)
                .environment(\.locationService, locationService)
                .environment(\.exportService, exportService)
                .environment(\.emergencyService, emergencyService)
                .environment(\.resourceService, resourceService)
                .environment(\.authenticationService, authenticationService)
                .environment(\.fileStorageService, fileStorageService)
                .environment(\.stealthModeService, stealthModeService)
                .environment(\.audioRecordingService, audioRecordingService)
                .environment(\.communityService, communityService)
                .environment(\.notificationService, notificationService)
                .environment(\.apiService, apiService)
                .environment(\.timelineSyncService, timelineSyncService)
        }
    }
}

// MARK: - Environment Keys

extension EnvironmentValues {
    @Entry var encryptionService: EncryptionService = EncryptionService()
    @Entry var locationService: LocationService = LocationService()
    @Entry var emergencyService: EmergencyService = EmergencyService()
    @Entry var resourceService: ResourceService = ResourceService()
    @Entry var authenticationService: AuthenticationService = AuthenticationService()
    // Modern Swift 6: Can't use closures in @Entry, set actual instance in app init
    @Entry var fileStorageService: FileStorageService = FileStorageService(encryptionService: EncryptionService())
    @Entry var exportService: ExportService = ExportService(
        encryptionService: EncryptionService(),
        fileStorageService: FileStorageService(encryptionService: EncryptionService())
    )
    @Entry var stealthModeService: StealthModeService = StealthModeService()
    @Entry var audioRecordingService: AudioRecordingService = AudioRecordingService()
    @Entry var notificationService: NotificationService = NotificationService()
    @Entry var apiService: APIService = APIService.shared
    @Entry var timelineSyncService: TimelineSyncService = TimelineSyncService.shared
}

@available(iOS 18, *)
extension EnvironmentValues {
    @Entry var communityService: CommunityService = CommunityService()
}
