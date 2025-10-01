import Foundation
import AVFoundation
import Observation
import WhisperKit

/// Service for managing Whisper model download, storage, and transcription using WhisperKit
@Observable
final class WhisperModelService: @unchecked Sendable {
    // MARK: - Properties
    
    var isModelDownloaded: Bool = false
    
    var modelSize: Int64 {
        // If model marker exists, return expected Whisper model size for UI display
        // In production with WhisperKit, this would return actual model directory size
        if isModelDownloaded {
            return WhisperModelService.expectedModelSize
        }
        return 0
    }
    
    var downloadProgress: Double = 0.0
    var isDownloading: Bool = false
    var downloadError: Error?
    
    // WhisperKit instance
    private var whisperKit: WhisperKit?
    
    // MARK: - Constants
    
    /// Expected model size in bytes (~500MB for Whisper small)
    static let expectedModelSize: Int64 = 500_000_000 // 500 MB
    
    /// Model name to download (for WhisperKit)
    private let modelName = "openai_whisper-small"
    
    /// Model storage path - WhisperKit uses its own structure
    /// WhisperKit saves to: /models/argmaxinc/whisperkit-coreml/openai_whisper-small
    private var modelPath: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        // Go up one level from Documents to the app container, then into models
        return documentsPath.deletingLastPathComponent()
            .appendingPathComponent("models")
            .appendingPathComponent("argmaxinc")
            .appendingPathComponent("whisperkit-coreml")
            .appendingPathComponent(modelName)
    }
    
    // MARK: - Initialization
    
    init() {
        // Check if model is already downloaded
        checkModelExists()
    }
    
    // MARK: - Download Management
    
    /// Check if model exists on disk
    private func checkModelExists() {
        let fm = FileManager.default
        print("🔍 Checking model at path: \(modelPath.path)")
        print("   Path exists: \(fm.fileExists(atPath: modelPath.path))")
        
        if fm.fileExists(atPath: modelPath.path) {
            if let contents = try? fm.contentsOfDirectory(atPath: modelPath.path),
               !contents.isEmpty {
                print("   ✅ Model found! Contents count: \(contents.count)")
                isModelDownloaded = true
                return
            }
        }
        print("   ❌ Model not found")
        isModelDownloaded = false
    }
    
    /// Download Whisper model with progress tracking using WhisperKit
    func downloadModel() async throws {
        guard !isDownloading else { return }
        
        isDownloading = true
        downloadProgress = 0.0
        downloadError = nil
        
        defer {
            isDownloading = false
        }
        
        do {
            downloadProgress = 0.1
            
            // Initialize WhisperKit with model download
            whisperKit = try await WhisperKit(
                model: modelName,
                downloadBase: modelPath.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),
                verbose: true,
                logLevel: .info,
                prewarm: false,
                load: false,
                download: true
            )
            
            downloadProgress = 0.8
            
            // Load the model
            try await whisperKit?.loadModels()
            
            downloadProgress = 1.0
            
            // Update download status
            isModelDownloaded = true
            
            // Debug: Check where WhisperKit actually saved the model
            if let modelPath = whisperKit?.modelFolder {
                print("✅ Whisper model download complete!")
                print("   WhisperKit model folder: \(modelPath)")
                print("   Our expected path: \(self.modelPath.path)")
                
                // Check if the paths match
                if modelPath.path != self.modelPath.path {
                    print("   ⚠️ PATH MISMATCH! WhisperKit saved to a different location")
                }
            } else {
                print("✅ Whisper model download complete!")
            }
            
        } catch {
            downloadError = error
            whisperKit = nil
            throw error
        }
    }
    
    /// Delete downloaded model to reclaim space
    func deleteModel() throws {
        guard isModelDownloaded else { return }
        try FileManager.default.removeItem(at: modelPath)
        whisperKit = nil
        isModelDownloaded = false
    }
    
    // MARK: - Audio Conversion
    
    /// Convert M4A audio to WAV format (16kHz, mono) for WhisperKit
    private func convertToWAV(audioURL: URL) async throws -> URL {
        let asset = AVAsset(url: audioURL)
        
        guard let reader = try? AVAssetReader(asset: asset) else {
            throw TranscriptionError.whisperTranscriptionFailed
        }
        
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard let audioTrack = audioTracks.first else {
            throw TranscriptionError.whisperTranscriptionFailed
        }
        
        // Output settings for WAV (16kHz, mono, PCM)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        let readerOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
        reader.add(readerOutput)
        
        // Create WAV file
        let wavURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("wav")
        
        guard let writer = try? AVAssetWriter(url: wavURL, fileType: .wav) else {
            throw TranscriptionError.whisperTranscriptionFailed
        }
        
        let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: outputSettings)
        writer.add(writerInput)
        
        reader.startReading()
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        await withCheckedContinuation { continuation in
            writerInput.requestMediaDataWhenReady(on: DispatchQueue.global()) {
                while writerInput.isReadyForMoreMediaData {
                    if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                        writerInput.append(sampleBuffer)
                    } else {
                        writerInput.markAsFinished()
                        writer.finishWriting {
                            continuation.resume()
                        }
                        break
                    }
                }
            }
        }
        
        return wavURL
    }
    
    // MARK: - Transcription
    
    /// Transcribe audio file using Whisper model with WhisperKit
    /// - Parameters:
    ///   - audioURL: URL of the audio file to transcribe
    ///   - onProgress: Optional progress callback (0.0 to 1.0)
    /// - Returns: Transcribed text
    func transcribe(audioURL: URL, onProgress: (@Sendable (Double) -> Void)? = nil) async throws -> String {
        guard isModelDownloaded else {
            throw TranscriptionError.whisperModelNotAvailable
        }
        
        onProgress?(0.1)
        
        // Initialize WhisperKit if needed
        if whisperKit == nil {
            whisperKit = try await WhisperKit(
                model: modelName,
                downloadBase: modelPath.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),
                verbose: false,
                logLevel: .error
            )
        }
        
        guard let whisperKit = whisperKit else {
            throw TranscriptionError.whisperTranscriptionFailed
        }
        
        onProgress?(0.3)
        
        // Convert M4A to WAV for WhisperKit (it doesn't support M4A directly)
        print("   🎤 Converting audio to WAV format for WhisperKit...")
        let wavURL = try await convertToWAV(audioURL: audioURL)
        
        // Transcribe audio
        print("   🎤 Starting WhisperKit transcription of: \(wavURL.path)")
        let results = try await whisperKit.transcribe(audioPath: wavURL.path)
        print("   ✅ WhisperKit transcription completed with \(results.count) segments")
        
        // Clean up WAV file
        try? FileManager.default.removeItem(at: wavURL)
        
        onProgress?(0.9)
        
        // Extract text from all segments
        let transcription = results.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        
        onProgress?(1.0)
        
        if transcription.isEmpty {
            throw TranscriptionError.whisperTranscriptionFailed
        }
        
        return transcription
    }
    
    // MARK: - Private Helpers
    
    /// Verify model file integrity
    private func verifyModelIntegrity() throws {
        guard isModelDownloaded else {
            throw WhisperError.invalidModel
        }
        
        // WhisperKit handles model validation internally
        // Additional custom validation can be added here if needed
    }
}

// MARK: - Whisper Errors

enum WhisperError: LocalizedError {
    case downloadFailed
    case invalidModel
    case modelCorrupted
    case insufficientStorage
    
    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "Failed to download Whisper model. Please check your internet connection and try again."
        case .invalidModel:
            return "Downloaded model is invalid or corrupted. Please try downloading again."
        case .modelCorrupted:
            return "Whisper model is corrupted. Please delete and re-download the model."
        case .insufficientStorage:
            return "Not enough storage space. Whisper model requires approximately 500MB."
        }
    }
}

