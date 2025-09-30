import SwiftUI
import AVFoundation
import PhotosUI

/// Video capture view with camera integration
struct VideoCaptureView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locationService) private var locationService
    @Environment(\.encryptionService) private var encryptionService
    
    @State private var fileStorageService: FileStorageService?
    @State private var cameraViewModel = CameraViewModel()
    
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var videoURL: URL?
    @State private var notes = ""
    @State private var selectedCategories: [EvidenceCategory] = []
    @State private var isCritical = false
    @State private var includeLocation = false
    
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    @State private var showingCamera = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Video preview or selection
                    videoSection
                    
                    // Categories
                    if videoURL != nil {
                        categoriesSection
                        notesSection
                        optionsSection
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Video Evidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            saveVideo()
                        }
                        .disabled(videoURL == nil)
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(videoURL: $videoURL, viewModel: cameraViewModel)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                fileStorageService = FileStorageService(encryptionService: encryptionService)
            }
        }
    }
    
    // MARK: - Video Section
    
    private var videoSection: some View {
        VStack(spacing: 16) {
            if let url = videoURL {
                // Video preview (using thumbnail)
                VideoThumbnailView(url: url)
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                
                // Video info
                HStack {
                    Image(systemName: "video.fill")
                        .foregroundStyle(.secondary)
                    
                    Text("Video selected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button("Change") {
                        videoURL = nil
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal)
            } else {
                // Selection options
                VStack(spacing: 20) {
                    Image(systemName: "video.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(Color.voiceitPurple)
                    
                    Text("Add Video Evidence")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Button {
                            showingCamera = true
                        } label: {
                            Label("Record Video", systemImage: "video.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(.voiceitPurple)
                        
                        PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
                            Label("Choose from Library", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
                .padding(40)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
        .onChange(of: selectedVideoItem) { oldValue, newValue in
            loadVideoFromPicker(newValue)
        }
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Categories", systemImage: "tag.fill")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(EvidenceCategory.allCases) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategories.contains(category)
                    ) {
                        toggleCategory(category)
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Additional Notes", systemImage: "note.text")
                .font(.headline)
            
            TextField("Describe what this video shows...", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }
    
    // MARK: - Options Section
    
    private var optionsSection: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $isCritical) {
                Label("Mark as Critical", systemImage: "exclamationmark.triangle.fill")
            }
            .padding()
            
            Divider()
            
            Toggle(isOn: $includeLocation) {
                Label("Include Location", systemImage: "location.fill")
            }
            .padding()
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }
    
    // MARK: - Load Video
    
    private func loadVideoFromPicker(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            do {
                guard let movie = try await item.loadTransferable(type: VideoTransferable.self) else {
                    throw FileStorageError.fileNotFound
                }
                
                await MainActor.run {
                    videoURL = movie.url
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load video: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    // MARK: - Save Video
    
    private func saveVideo() {
        guard let url = videoURL else { return }
        
        isSaving = true
        
        Task {
            do {
                // Get location if requested
                var locationSnapshot: LocationSnapshot?
                if includeLocation {
                    locationSnapshot = await locationService.createSnapshot()
                }
                
                // Save and encrypt video file
                guard let fileStorage = fileStorageService else {
                    throw FileStorageError.encryptionFailed
                }
                
                let (filePath, fileSize, duration, thumbnailPath) = try await fileStorage.saveVideoFile(url)
                
                // Create video evidence
                let videoEvidence = VideoEvidence(
                    notes: notes,
                    locationSnapshot: locationSnapshot,
                    tags: selectedCategories.map { $0.rawValue },
                    isCritical: isCritical,
                    videoFilePath: filePath,
                    thumbnailFilePath: thumbnailPath,
                    duration: duration,
                    videoFormat: "mp4",
                    fileSize: fileSize
                )
                
                await MainActor.run {
                    modelContext.insert(videoEvidence)
                }
                
                try modelContext.save()
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save video: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func toggleCategory(_ category: EvidenceCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.removeAll { $0 == category }
        } else {
            selectedCategories.append(category)
        }
    }
}

// MARK: - Video Thumbnail View

struct VideoThumbnailView: View {
    let url: URL
    @State private var thumbnail: UIImage?
    
    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.secondary.opacity(0.3)
                ProgressView()
            }
            
            // Play overlay
            Image(systemName: "play.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.white)
                .shadow(radius: 10)
        }
        .task {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try await imageGenerator.image(at: .zero).image
            await MainActor.run {
                thumbnail = UIImage(cgImage: cgImage)
            }
        } catch {
            print("Failed to generate thumbnail: \(error)")
        }
    }
}

// MARK: - Video Transferable

struct VideoTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let copy = FileManager.default.temporaryDirectory.appendingPathComponent(received.file.lastPathComponent)
            
            if FileManager.default.fileExists(atPath: copy.path) {
                try FileManager.default.removeItem(at: copy)
            }
            
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var videoURL: URL?
    @Environment(\.dismiss) private var dismiss
    let viewModel: CameraViewModel
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeHigh
        picker.videoMaximumDuration = 600 // 10 minutes
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let url = info[.mediaURL] as? URL {
                parent.videoURL = url
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Camera View Model

@Observable
final class CameraViewModel {
    var hasPermission = false
    
    func checkPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
}

#Preview {
    VideoCaptureView()
        .modelContainer(for: [VideoEvidence.self], inMemory: true)
}
