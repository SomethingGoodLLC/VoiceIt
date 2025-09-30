import Foundation
import AVFoundation
import Observation

/// Service for handling audio recording with waveform visualization
/// Note: @unchecked Sendable is used because @Observable macro generates mutable storage
/// All public methods ensure thread-safe access to AVAudioRecorder
@Observable
final class AudioRecordingService: NSObject, @unchecked Sendable {
    // MARK: - Properties
    
    private var audioRecorder: AVAudioRecorder?
    private var audioEngine: AVAudioEngine?
    private var recordingURL: URL?
    private var waveformUpdateTimer: Timer?
    
    // Observable state
    private(set) var isRecording = false
    private(set) var isPaused = false
    private(set) var currentLevel: Float = 0.0
    private(set) var duration: TimeInterval = 0.0
    private(set) var waveformSamples: [Float] = Array(repeating: 0.0, count: 30)
    
    // MARK: - Audio Session Setup
    
    /// Configure audio session for recording
    func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try session.setActive(true)
    }
    
    /// Request microphone permission
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Recording Controls
    
    /// Start recording
    func startRecording() async throws -> URL {
        // Request permission
        guard await requestPermission() else {
            throw AudioRecordingError.permissionDenied
        }
        
        // Configure session
        try configureAudioSession()
        
        // Ensure directory exists FIRST
        try Constants.Storage.createDirectories()
        
        // Create recording URL in temp directory (will be moved after encryption)
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "voice_\(timestamp).m4a"
        let recordingPath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        recordingURL = recordingPath
        
        // Configure recorder settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // Create and configure recorder
        audioRecorder = try AVAudioRecorder(url: recordingPath, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.delegate = self
        audioRecorder?.prepareToRecord()
        
        // Start recording
        guard audioRecorder?.record() == true else {
            throw AudioRecordingError.recordingFailed
        }
        
        await MainActor.run {
            isRecording = true
            isPaused = false
            duration = 0.0
        }
        
        // Start metering updates
        startMeteringUpdates()
        
        return recordingPath
    }
    
    /// Pause recording
    func pauseRecording() {
        guard isRecording, !isPaused else { return }
        
        audioRecorder?.pause()
        
        Task { @MainActor in
            isPaused = true
        }
        
        stopMeteringUpdates()
    }
    
    /// Resume recording
    func resumeRecording() {
        guard isRecording, isPaused else { return }
        
        audioRecorder?.record()
        
        Task { @MainActor in
            isPaused = false
        }
        
        startMeteringUpdates()
    }
    
    /// Stop recording and return file URL
    func stopRecording() async -> URL? {
        guard isRecording else { return nil }
        
        // Capture final duration before stopping
        let finalDuration = audioRecorder?.currentTime ?? duration
        
        audioRecorder?.stop()
        stopMeteringUpdates()
        
        await MainActor.run {
            isRecording = false
            isPaused = false
            // Preserve the final duration
            duration = finalDuration
        }
        
        return recordingURL
    }
    
    /// Delete recording file
    func deleteRecording(at url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Metering & Waveform
    
    private func startMeteringUpdates() {
        // Update every 0.05 seconds for smooth waveform
        // Must be on main thread for timer to work
        Task { @MainActor in
            waveformUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.updateMetering()
            }
        }
    }
    
    private func stopMeteringUpdates() {
        Task { @MainActor in
            waveformUpdateTimer?.invalidate()
            waveformUpdateTimer = nil
        }
    }
    
    private func updateMetering() {
        guard let recorder = audioRecorder, isRecording, !isPaused else { return }
        
        recorder.updateMeters()
        
        // Get current level (normalized to 0-1)
        let level = recorder.averagePower(forChannel: 0)
        let normalizedLevel = powf(10.0, level / 20.0) // Convert dB to linear
        
        Task { @MainActor in
            currentLevel = normalizedLevel
            duration = recorder.currentTime
            
            // Update waveform samples (shift and add new)
            waveformSamples.removeFirst()
            waveformSamples.append(normalizedLevel)
        }
    }
    
    // MARK: - Playback
    
    /// Get audio duration from file
    func getAudioDuration(from url: URL) async -> TimeInterval {
        let asset = AVURLAsset(url: url)
        guard let duration = try? await asset.load(.duration) else {
            return 0
        }
        return CMTimeGetSeconds(duration)
    }
    
    /// Get audio file size
    func getFileSize(from url: URL) -> Int64 {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return 0
        }
        return fileSize
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecordingService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                print("Recording finished unsuccessfully")
            }
            isRecording = false
            isPaused = false
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("Recording error: \(error.localizedDescription)")
            }
            isRecording = false
            isPaused = false
        }
    }
}

// MARK: - Errors

enum AudioRecordingError: LocalizedError {
    case permissionDenied
    case recordingFailed
    case audioSessionFailed
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied. Please enable it in Settings."
        case .recordingFailed:
            return "Failed to start recording. Please try again."
        case .audioSessionFailed:
            return "Failed to configure audio session."
        case .fileNotFound:
            return "Recording file not found."
        }
    }
}
