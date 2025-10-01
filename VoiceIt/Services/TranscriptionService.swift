import Foundation
import Speech
import AVFoundation
import Observation

/// Transcription modes available
enum TranscriptionMode: String, CaseIterable, Codable {
    case apple      // SFSpeechRecognizer (requires internet for some languages)
    case whisper    // Local Whisper model (fully offline)
    case auto       // Try Whisper first, fallback to Apple
    
    var displayName: String {
        switch self {
        case .apple: return "Apple Speech Recognition"
        case .whisper: return "Offline (Whisper)"
        case .auto: return "Auto (Whisper preferred)"
        }
    }
    
    var icon: String {
        switch self {
        case .apple: return "cloud"
        case .whisper: return "lock.fill"
        case .auto: return "sparkles"
        }
    }
    
    var badge: String {
        switch self {
        case .apple: return "☁️"
        case .whisper: return "🔒"
        case .auto: return "✨"
        }
    }
}

/// Transcription method actually used
enum TranscriptionMethod: String, Codable {
    case apple
    case whisper
    case none
    
    var displayName: String {
        switch self {
        case .apple: return "Apple Speech Recognition"
        case .whisper: return "Offline Whisper v3 Small"
        case .none: return "No transcription"
        }
    }
    
    var badge: String {
        switch self {
        case .apple: return "☁️"
        case .whisper: return "🔒"
        case .none: return "⚠️"
        }
    }
}

/// Service for speech recognition and transcription with Whisper support
@Observable
final class TranscriptionService: @unchecked Sendable {
    // MARK: - Properties
    
    var mode: TranscriptionMode {
        get {
            if let saved = UserDefaults.standard.string(forKey: "transcriptionMode"),
               let mode = TranscriptionMode(rawValue: saved) {
                return mode
            }
            return .auto
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "transcriptionMode")
        }
    }
    
    var isWhisperModelDownloaded: Bool {
        whisperModelService.isModelDownloaded
    }
    
    var whisperModelSize: Int64 {
        whisperModelService.modelSize
    }
    
    var lastUsedMethod: TranscriptionMethod = .none
    
    // Private properties
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    let whisperModelService = WhisperModelService()
    
    // MARK: - Initialization
    
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    // MARK: - Permission
    
    /// Request speech recognition permission
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    // MARK: - Live Transcription
    
    /// Start live transcription from microphone
    func startLiveTranscription(onUpdate: @escaping @Sendable (String) -> Void) async throws {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw TranscriptionError.requestFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true // Privacy: on-device only
        
        // Get input node
        let inputNode = audioEngine.inputNode
        
        // Create recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                Task { @MainActor in
                    onUpdate(transcription)
                }
            }
            
            if error != nil {
                self.stopLiveTranscription()
            }
        }
        
        // Configure audio tap
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    /// Stop live transcription
    func stopLiveTranscription() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    // MARK: - File Transcription
    
    /// Transcribe audio file using the configured mode
    func transcribeAudioFile(at url: URL, onProgress: (@Sendable (Double) -> Void)? = nil) async throws -> (text: String, method: TranscriptionMethod) {
        switch mode {
        case .whisper:
            return try await transcribeWithWhisper(url: url, onProgress: onProgress)
            
        case .apple:
            let text = try await transcribeWithApple(url: url)
            lastUsedMethod = .apple
            return (text, .apple)
            
        case .auto:
            // Try Whisper first if available, fallback to Apple
            print("🔄 Auto mode: isWhisperModelDownloaded = \(isWhisperModelDownloaded)")
            if isWhisperModelDownloaded {
                print("   → Using Whisper")
                do {
                    return try await transcribeWithWhisper(url: url, onProgress: onProgress)
                } catch {
                    print("   → Whisper failed, falling back to Apple")
                    print("Whisper transcription failed, falling back to Apple: \(error)")
                    let text = try await transcribeWithApple(url: url)
                    lastUsedMethod = .apple
                    return (text, .apple)
                }
            } else {
                print("   → Whisper not available, using Apple")
                let text = try await transcribeWithApple(url: url)
                lastUsedMethod = .apple
                return (text, .apple)
            }
        }
    }
    
    // MARK: - Private Transcription Methods
    
    /// Transcribe using Apple's SFSpeechRecognizer
    private func transcribeWithApple(url: URL) async throws -> String {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw TranscriptionError.recognizerNotAvailable
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = true // Privacy: on-device only
        request.shouldReportPartialResults = false
        
        return try await withCheckedThrowingContinuation { continuation in
            speechRecognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
    
    /// Transcribe using Whisper model
    private func transcribeWithWhisper(url: URL, onProgress: (@Sendable (Double) -> Void)?) async throws -> (text: String, method: TranscriptionMethod) {
        guard isWhisperModelDownloaded else {
            throw TranscriptionError.whisperModelNotAvailable
        }
        
        let text = try await whisperModelService.transcribe(audioURL: url, onProgress: onProgress)
        lastUsedMethod = .whisper
        return (text, .whisper)
    }
    
    /// Check if speech recognition is available
    var isAvailable: Bool {
        speechRecognizer?.isAvailable ?? false
    }
    
    /// Get supported locales for speech recognition
    static var supportedLocales: Set<Locale> {
        SFSpeechRecognizer.supportedLocales()
    }
}

// MARK: - Errors

enum TranscriptionError: LocalizedError {
    case permissionDenied
    case recognizerNotAvailable
    case requestFailed
    case audioEngineFailed
    case whisperModelNotAvailable
    case whisperTranscriptionFailed
    case audioConversionFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition permission denied. Please enable it in Settings."
        case .recognizerNotAvailable:
            return "Speech recognition is not available on this device."
        case .requestFailed:
            return "Failed to create transcription request."
        case .audioEngineFailed:
            return "Failed to start audio engine."
        case .whisperModelNotAvailable:
            return "Whisper model not downloaded. Please download it in Settings > Transcription."
        case .whisperTranscriptionFailed:
            return "Whisper transcription failed. Please try again or use Apple Speech Recognition."
        case .audioConversionFailed:
            return "Failed to convert audio to required format for transcription."
        }
    }
}
