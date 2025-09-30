import SwiftUI
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
            Resource.self
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
        exportService = ExportService(encryptionService: encryptionService)
        emergencyService = EmergencyService()
        resourceService = ResourceService()
        authenticationService = AuthenticationService()
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
        }
    }
}

// MARK: - Environment Keys

extension EnvironmentValues {
    @Entry var encryptionService: EncryptionService = EncryptionService()
    @Entry var locationService: LocationService = LocationService()
    @Entry var exportService: ExportService = ExportService(encryptionService: EncryptionService())
    @Entry var emergencyService: EmergencyService = EmergencyService()
    @Entry var resourceService: ResourceService = ResourceService()
    @Entry var authenticationService: AuthenticationService = AuthenticationService()
}
