import SwiftUI
import SwiftData

/// Sheet for selecting export options
struct ExportOptionsSheet: View {
    // MARK: - Properties
    
    let evidence: [any EvidenceProtocol]
    
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: ExportFormat = .pdf
    @State private var includeImages = true
    @State private var isExporting = false
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
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
                
                // Options
                Section {
                    if exportFormat == .pdf {
                        Toggle(isOn: $includeImages) {
                            Label("Include Images", systemImage: "photo.on.rectangle")
                        }
                    }
                } header: {
                    Text("Options")
                }
                
                // Export button
                Section {
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
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(
                        LinearGradient(
                            colors: [Color.voiceitPurple, Color.voiceitPurpleLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .disabled(isExporting || evidence.isEmpty)
                }
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
    
    private func performExport() async {
        isExporting = true
        defer { isExporting = false }
        
        do {
            // Simulate export process (replace with actual ExportService call)
            try await Task.sleep(for: .seconds(1))
            
            // For now, create a temporary URL
            // TODO: Integrate with ExportService
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("VoiceIt_Export_\(Date().formatted(.iso8601)).\(exportFormat.fileExtension)")
            
            // Create dummy file
            try "Export placeholder".write(to: tempURL, atomically: true, encoding: .utf8)
            
            exportURL = tempURL
            showingShareSheet = true
            
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Export Format

enum ExportFormat: String, CaseIterable {
    case pdf = "PDF Document"
    case json = "JSON Data"
    case encrypted = "Encrypted Archive"
    
    var icon: String {
        switch self {
        case .pdf:
            return "doc.fill"
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
