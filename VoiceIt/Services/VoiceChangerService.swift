import Foundation
import AVFoundation
import Observation

/// Service for the Voice Changer decoy
/// Handles recording and playback with audio effects (pitch, reverb)
/// Completely separate from the main evidence recording system
@Observable
final class VoiceChangerService: NSObject, @unchecked Sendable {
    // MARK: - Properties
    
    private var audioEngine: AVAudioEngine?
    private var audioPlayerNode: AVAudioPlayerNode?
    private var audioRecorder: AVAudioRecorder?
    private var audioFile: AVAudioFile?
    
    // Effects
    private var pitchControl: AVAudioUnitTimePitch?
    private var reverbControl: AVAudioUnitReverb?
    
    // State
    var isRecording = false
    var isPlaying = false
    var hasRecording = false
    
    // Effect Parameters
    var pitch: Float = 0.0 { // -2400 to 2400 cents
        didSet {
            pitchControl?.pitch = pitch
        }
    }
    
    var reverb: Float = 0.0 { // 0 to 100 wet/dry
        didSet {
            reverbControl?.wetDryMix = reverb
        }
    }
    
    // Temp file URL
    private var recordingURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("decoy_recording.m4a")
    }
    
    // MARK: - Recording
    
    func startRecording() throws {
        // Setup session
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
        
        // Setup recorder settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // Create recorder
        audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
        audioRecorder?.prepareToRecord()
        audioRecorder?.record()
        
        isRecording = true
        isPlaying = false
        hasRecording = false
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        hasRecording = true
    }
    
    // MARK: - Playback
    
    func playRecording() throws {
        guard FileManager.default.fileExists(atPath: recordingURL.path) else { return }
        
        // Stop any existing playback
        stopPlayback()
        
        // Setup engine
        audioEngine = AVAudioEngine()
        audioPlayerNode = AVAudioPlayerNode()
        pitchControl = AVAudioUnitTimePitch()
        reverbControl = AVAudioUnitReverb()
        
        guard let engine = audioEngine,
              let player = audioPlayerNode,
              let pitchNode = pitchControl,
              let reverbNode = reverbControl else { return }
        
        // Attach nodes
        engine.attach(player)
        engine.attach(pitchNode)
        engine.attach(reverbNode)
        
        // Configure effects
        pitchNode.pitch = pitch
        reverbNode.loadFactoryPreset(.mediumHall)
        reverbNode.wetDryMix = reverb
        
        // Connect nodes
        engine.connect(player, to: pitchNode, format: nil)
        engine.connect(pitchNode, to: reverbNode, format: nil)
        engine.connect(reverbNode, to: engine.mainMixerNode, format: nil)
        
        // Prepare file
        audioFile = try AVAudioFile(forReading: recordingURL)
        guard let file = audioFile else { return }
        
        // Schedule playback
        player.scheduleFile(file, at: nil) { [weak self] in
            Task { @MainActor in
                self?.isPlaying = false
            }
        }
        
        // Start engine
        try engine.start()
        player.play()
        
        isPlaying = true
    }
    
    func stopPlayback() {
        audioPlayerNode?.stop()
        audioEngine?.stop()
        isPlaying = false
    }
    
    // MARK: - Presets
    
    @MainActor
    func applyPreset(_ preset: VoiceEffectPreset) {
        pitch = preset.pitch
        reverb = preset.reverb
    }
}

enum VoiceEffectPreset: String, CaseIterable {
    case normal = "Normal"
    case chipmunk = "Chipmunk"
    case monster = "Monster"
    case robot = "Robot"
    case echo = "Cave"
    
    var pitch: Float {
        switch self {
        case .normal: return 0
        case .chipmunk: return 1000
        case .monster: return -1000
        case .robot: return -500
        case .echo: return 0
        }
    }
    
    var reverb: Float {
        switch self {
        case .normal: return 0
        case .chipmunk: return 0
        case .monster: return 20
        case .robot: return 60
        case .echo: return 80
        }
    }
    
    var icon: String {
        switch self {
        case .normal: return "person.fill"
        case .chipmunk: return "hare.fill"
        case .monster: return "pawprint.fill"
        case .robot: return "gearshape.fill"
        case .echo: return "waveform"
        }
    }
    
    var color: String { // Use system colors for now
        switch self {
        case .normal: return "blue"
        case .chipmunk: return "orange"
        case .monster: return "purple"
        case .robot: return "gray"
        case .echo: return "teal"
        }
    }
}
