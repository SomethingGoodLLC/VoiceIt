import Foundation
import AVFoundation
import Observation

/// Service for playing back audio recordings
/// Handles loading encrypted audio files and playback controls
@Observable
@MainActor
final class AudioPlayerService: NSObject {
    // MARK: - Properties
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var currentFileURL: URL?
    
    // Observable state
    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0.0
    private(set) var duration: TimeInterval = 0.0
    private(set) var playbackProgress: Double = 0.0
    
    // MARK: - Audio Session Setup
    
    /// Configure audio session for playback
    func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
    }
    
    // MARK: - Playback Controls
    
    /// Load audio file for playback
    func loadAudio(from url: URL) async throws {
        // Stop current playback if any
        stop()
        
        // Configure audio session
        try configureAudioSession()
        
        // Create audio player
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        
        currentFileURL = url
        duration = audioPlayer?.duration ?? 0.0
        currentTime = 0.0
        playbackProgress = 0.0
    }
    
    /// Play audio
    func play() {
        guard let player = audioPlayer else { return }
        
        player.play()
        isPlaying = true
        startPlaybackTimer()
    }
    
    /// Pause audio
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopPlaybackTimer()
    }
    
    /// Stop audio and reset
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0.0
        playbackProgress = 0.0
        stopPlaybackTimer()
    }
    
    /// Toggle play/pause
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    /// Seek to specific time
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        player.currentTime = min(max(0, time), duration)
        updatePlaybackState()
    }
    
    /// Seek to progress (0.0 to 1.0)
    func seek(toProgress progress: Double) {
        let time = duration * progress
        seek(to: time)
    }
    
    /// Skip forward by seconds
    func skipForward(_ seconds: TimeInterval = 15) {
        guard let player = audioPlayer else { return }
        seek(to: player.currentTime + seconds)
    }
    
    /// Skip backward by seconds
    func skipBackward(_ seconds: TimeInterval = 15) {
        guard let player = audioPlayer else { return }
        seek(to: player.currentTime - seconds)
    }
    
    // MARK: - Playback Timer
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updatePlaybackState()
            }
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func updatePlaybackState() {
        guard let player = audioPlayer else { return }
        
        currentTime = player.currentTime
        
        if duration > 0 {
            playbackProgress = currentTime / duration
        }
    }
    
    // MARK: - Cleanup
    
    /// Clean up decrypted temporary file
    func cleanup() {
        stop()
        audioPlayer = nil
        
        // Clean up temporary decrypted file if it exists
        if let url = currentFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        currentFileURL = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            currentTime = 0.0
            playbackProgress = 0.0
            stopPlaybackTimer()
            
            // Reset to beginning
            audioPlayer?.currentTime = 0
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("Audio playback error: \(error.localizedDescription)")
            }
            isPlaying = false
            stopPlaybackTimer()
        }
    }
}

// MARK: - Errors

enum AudioPlayerError: LocalizedError {
    case fileNotFound
    case loadFailed
    case playbackFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Audio file not found."
        case .loadFailed:
            return "Failed to load audio file."
        case .playbackFailed:
            return "Failed to play audio."
        }
    }
}

