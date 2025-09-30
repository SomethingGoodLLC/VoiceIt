import SwiftUI
@preconcurrency import SwiftData

/// Sheet for selecting export options with date range and advanced settings
struct ExportOptionsSheet: View {
    // MARK: - Properties
    
    let evidence: [any EvidenceProtocol]
    
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: ExportFormat = .pdf
    @State private var includeImages = true
    @State private var includeLocation = true
    @State private var isExporting = false
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Date range filtering
    @State private var useDateRange = false
    @State private var startDate = Date().addingTimeInterval(-30 * 24 * 3600) // 30 days ago
    @State private var endDate = Date()
    
    // Evidence type filtering
    @State private var includeVoiceNotes = true
    @State private var includePhotos = true
    @State private var includeVideos = true
    @State private var includeTextEntries = true
    
    // Password protection
    @State private var usePassword = false
    @State private var password = ""
    @State private var confirmPassword = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                // Summary section
                Section {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(Color.voiceitPurple)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(evidence.count) Evidence Items")
                                .font(.headline)
                            
                            Text("Ready for export")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Export Summary")
                }
                
                // Format selection
                Section {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Label(format.rawValue, systemImage: format.icon)
                                .tag(format)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Export Format")
                } footer: {
                    Text(exportFormat.description)
                }
                
                // Date Range
                Section {
                    Toggle(isOn: $useDateRange) {
                        Label("Filter by Date Range", systemImage: "calendar")
                    }
                    
                    if useDateRange {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                        DatePicker("End Date", selection: $endDate, displayedComponents: [.date])
                    }
                } header: {
                    Text("Date Range")
                } footer: {
                    if useDateRange {
                        Text("Only evidence between these dates will be included.")
                    }
                }
                
                // Evidence Types
                Section {
                    Toggle(isOn: $includeVoiceNotes) {
                        Label("Voice Notes", systemImage: "mic.circle.fill")
                    }
                    Toggle(isOn: $includePhotos) {
                        Label("Photos", systemImage: "camera.fill")
                    }
                    Toggle(isOn: $includeVideos) {
                        Label("Videos", systemImage: "video.circle.fill")
                    }
                    Toggle(isOn: $includeTextEntries) {
                        Label("Text Entries", systemImage: "doc.text.fill")
                    }
                } header: {
                    Text("Evidence Types to Include")
                }
                
                // Options
                Section {
                    if exportFormat == .pdf || exportFormat == .word {
                        Toggle(isOn: $includeImages) {
                            Label("Include Images", systemImage: "photo.on.rectangle")
                        }
                        Toggle(isOn: $includeLocation) {
                            Label("Include Location Data", systemImage: "location.fill")
                        }
                    }
                } header: {
                    Text("Content Options")
                }
                
                // Password Protection
                if exportFormat == .pdf {
                    Section {
                        Toggle(isOn: $usePassword) {
                            Label("Password Protection", systemImage: "lock.fill")
                        }
                        
                        if usePassword {
                            SecureField("Password", text: $password)
                            SecureField("Confirm Password", text: $confirmPassword)
                            
                            if !password.isEmpty && !confirmPassword.isEmpty {
                                if password == confirmPassword {
                                    Label("Passwords match", systemImage: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                } else {
                                    Label("Passwords don't match", systemImage: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                        .font(.caption)
                                }
                            }
                        }
                    } header: {
                        Text("Security")
                    } footer: {
                        if usePassword {
                            Text("The export file will be encrypted with this password. Keep it safe - it cannot be recovered.")
                        }
                    }
                }
            }
            
            // Sticky Export button at bottom
            Button {
                Task {
                    await performExport()
                }
            } label: {
                HStack {
                    Spacer()
                    
                    if isExporting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Label("Export Timeline", systemImage: "arrow.up.doc.fill")
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.voiceitPurple, Color.voiceitPurpleLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .disabled(isExporting || evidence.isEmpty)
            .opacity(isExporting || evidence.isEmpty ? 0.6 : 1)
            }
            .navigationTitle("Export Evidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Export Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Export Action
    
    @MainActor
    private func performExport() async {
        // Validation
        if usePassword && password != confirmPassword {
            errorMessage = "Passwords don't match"
            showingError = true
            return
        }
        
        if usePassword && password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            showingError = true
            return
        }
        
        isExporting = true
        defer { isExporting = false }
        
        do {
            // Create export options
            var options = ExportService.ExportOptions.defaultOptions
            options.startDate = useDateRange ? startDate : nil
            options.endDate = useDateRange ? endDate : nil
            options.includeVoiceNotes = includeVoiceNotes
            options.includePhotos = includePhotos
            options.includeVideos = includeVideos
            options.includeTextEntries = includeTextEntries
            options.includeLocation = includeLocation
            options.includeImages = includeImages
            options.password = usePassword ? password : nil
            
            // Modern Swift 6: Copy SwiftData models on MainActor before sending
            // SwiftData hasn't fully adopted Sendable yet, so we make an explicit copy
            let evidenceCopy: [any EvidenceProtocol] = evidence
            
            let encryptionService = EncryptionService()
            let fileStorageService = FileStorageService(encryptionService: encryptionService)
            let exportService = ExportService(
                encryptionService: encryptionService,
                fileStorageService: fileStorageService
            )
            
            let url: URL
            switch exportFormat {
            case .pdf:
                // Use the copy to satisfy Swift 6 concurrency (copy is made on MainActor)
                url = try await exportService.generatePDF(evidence: evidenceCopy, options: options)
            case .word:
                url = try await exportService.generateWordDocument(evidence: evidenceCopy, options: options)
            case .json:
                url = try await exportService.generateJSON(evidence: evidenceCopy, options: options)
            case .encrypted:
                url = try await exportService.generateJSON(evidence: evidenceCopy, options: options)
            }
            
            exportURL = url
            showingShareSheet = true
            
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private var filteredEvidenceCount: Int {
        var count = evidence.count
        
        if useDateRange {
            count = evidence.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }.count
        }
        
        return count
    }
}

// MARK: - Export Format

enum ExportFormat: String, CaseIterable {
    case pdf = "PDF Document"
    case word = "Word Document"
    case json = "JSON Data"
    case encrypted = "Encrypted Archive"
    
    var icon: String {
        switch self {
        case .pdf:
            return "doc.fill"
        case .word:
            return "doc.text.fill"
        case .json:
            return "curlybraces"
        case .encrypted:
            return "lock.shield.fill"
        }
    }
    
    var description: String {
        switch self {
        case .pdf:
            return "Legal-ready PDF with formatted evidence and metadata. Suitable for court submissions."
        case .word:
            return "Microsoft Word-compatible RTF document. Easy to edit and annotate."
        case .json:
            return "Machine-readable JSON format with all evidence data. Useful for data analysis."
        case .encrypted:
            return "Password-protected encrypted archive. Maximum security for sensitive evidence."
        }
    }
    
    var fileExtension: String {
        switch self {
        case .pdf:
            return "pdf"
        case .word:
            return "rtf"
        case .json:
            return "json"
        case .encrypted:
            return "enc"
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

// MARK: - Preview

#Preview {
    ExportOptionsSheet(evidence: [])
}
