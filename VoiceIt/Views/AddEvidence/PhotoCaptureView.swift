import SwiftUI
import PhotosUI

/// Photo/video capture view
struct PhotoCaptureView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locationService) private var locationService
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var notes = ""
    @State private var isCritical = false
    @State private var includeLocation = false
    @State private var showingCamera = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // Photo selection
                Section {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.voiceitPurple)
                            
                            HStack(spacing: 20) {
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                                }
                                .buttonStyle(.bordered)
                                
                                Button {
                                    showingCamera = true
                                } label: {
                                    Label("Take Photo", systemImage: "camera")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
                
                // Notes
                Section("Notes") {
                    TextField("Add notes about this photo", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Options
                Section("Options") {
                    Toggle("Mark as Critical", isOn: $isCritical)
                    Toggle("Include Location", isOn: $includeLocation)
                }
            }
            .navigationTitle("Photo Evidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePhoto()
                    }
                    .disabled(selectedImage == nil)
                }
            }
            .onChange(of: selectedItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Save Photo
    
    private func savePhoto() {
        guard let image = selectedImage else { return }
        
        Task {
            do {
                // Get location if requested
                var locationSnapshot: LocationSnapshot?
                if includeLocation {
                    locationSnapshot = await locationService.createSnapshot()
                }
                
                // In production, would save encrypted image to disk
                // For now, create placeholder
                let photoEvidence = PhotoEvidence(
                    notes: notes,
                    locationSnapshot: locationSnapshot,
                    isCritical: isCritical,
                    imageFilePath: "placeholder", // Would be actual encrypted file path
                    imageFormat: "heic",
                    width: Int(image.size.width),
                    height: Int(image.size.height)
                )
                
                modelContext.insert(photoEvidence)
                try modelContext.save()
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save photo: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    PhotoCaptureView()
}
