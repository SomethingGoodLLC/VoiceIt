import Foundation
import SwiftData
import Observation

/// Service for syncing local evidence to backend timeline
@Observable
final class TimelineSyncService: @unchecked Sendable {
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = TimelineSyncService()
    
    /// Whether sync is enabled
    var isSyncEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "timelineSyncEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "timelineSyncEnabled")
        }
    }
    
    /// Last sync timestamp
    var lastSyncDate: Date? {
        get {
            UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastSyncDate")
        }
    }
    
    /// Whether sync is currently in progress
    private(set) var isSyncing = false
    
    /// Sync error if any
    private(set) var syncError: Error?
    
    private let apiService = APIService.shared
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Sync Operations
    
    /// Sync all local evidence to backend
    @MainActor
    func syncAllEvidence(modelContext: ModelContext) async throws {
        guard isSyncEnabled else {
            throw SyncError.syncDisabled
        }
        
        guard apiService.isAuthenticated else {
            throw SyncError.notAuthenticated
        }
        
        guard !isSyncing else {
            throw SyncError.syncInProgress
        }
        
        isSyncing = true
        syncError = nil
        
        defer {
            isSyncing = false
        }
        
        do {
            // Fetch all evidence types
            let textEntries = try modelContext.fetch(FetchDescriptor<TextEntry>())
            let voiceNotes = try modelContext.fetch(FetchDescriptor<VoiceNote>())
            let photos = try modelContext.fetch(FetchDescriptor<PhotoEvidence>())
            let videos = try modelContext.fetch(FetchDescriptor<VideoEvidence>())
            
            // Sync text entries
            for entry in textEntries {
                await syncTextEntry(entry)
            }
            
            // Sync voice notes
            for note in voiceNotes {
                await syncVoiceNote(note)
            }
            
            // Sync photos
            for photo in photos {
                await syncPhoto(photo)
            }
            
            // Sync videos
            for video in videos {
                await syncVideo(video)
            }
            
            lastSyncDate = Date()
            
        } catch {
            syncError = error
            throw error
        }
    }
    
    /// Sync a single evidence item to backend
    @MainActor
    func syncEvidence(_ evidence: any EvidenceProtocol) async throws {
        guard isSyncEnabled else {
            throw SyncError.syncDisabled
        }
        
        guard apiService.isAuthenticated else {
            throw SyncError.notAuthenticated
        }
        
        switch evidence {
        case let textEntry as TextEntry:
            await syncTextEntry(textEntry)
        case let voiceNote as VoiceNote:
            await syncVoiceNote(voiceNote)
        case let photo as PhotoEvidence:
            await syncPhoto(photo)
        case let video as VideoEvidence:
            await syncVideo(video)
        default:
            throw SyncError.unsupportedType
        }
    }
    
    // MARK: - Private Sync Methods
    
    @MainActor
    private func syncTextEntry(_ entry: TextEntry) async {
        var metadata: [String: String] = [
            "isCritical": String(entry.isCritical),
            "wordCount": String(entry.wordCount)
        ]
        
        if !entry.tags.isEmpty {
            metadata["tags"] = entry.tags.joined(separator: ",")
        }
        
        do {
            _ = try await apiService.createTimelineEntry(
                type: "text",
                content: entry.bodyText,
                timestamp: entry.timestamp,
                metadata: metadata
            )
        } catch {
            print("Failed to sync text entry: \(error)")
        }
    }
    
    @MainActor
    private func syncVoiceNote(_ note: VoiceNote) async {
        var metadata: [String: String] = [
            "isCritical": String(note.isCritical),
            "duration": String(format: "%.1f", note.duration)
        ]
        
        if !note.tags.isEmpty {
            metadata["tags"] = note.tags.joined(separator: ",")
        }
        
        if let transcription = note.transcription {
            metadata["transcription"] = transcription
        }
        
        do {
            _ = try await apiService.createTimelineEntry(
                type: "voice",
                content: note.transcription ?? "Voice recording",
                timestamp: note.timestamp,
                metadata: metadata
            )
        } catch {
            print("Failed to sync voice note: \(error)")
        }
    }
    
    @MainActor
    private func syncPhoto(_ photo: PhotoEvidence) async {
        var metadata: [String: String] = [
            "isCritical": String(photo.isCritical)
        ]
        
        if !photo.tags.isEmpty {
            metadata["tags"] = photo.tags.joined(separator: ",")
        }
        
        do {
            _ = try await apiService.createTimelineEntry(
                type: "photo",
                content: photo.notes.isEmpty ? "Photo evidence" : photo.notes,
                timestamp: photo.timestamp,
                metadata: metadata
            )
        } catch {
            print("Failed to sync photo: \(error)")
        }
    }
    
    @MainActor
    private func syncVideo(_ video: VideoEvidence) async {
        var metadata: [String: String] = [
            "isCritical": String(video.isCritical),
            "duration": String(format: "%.1f", video.duration)
        ]
        
        if !video.tags.isEmpty {
            metadata["tags"] = video.tags.joined(separator: ",")
        }
        
        if video.fileSize > 0 {
            metadata["fileSize"] = String(video.fileSize)
        }
        
        do {
            _ = try await apiService.createTimelineEntry(
                type: "video",
                content: video.notes.isEmpty ? "Video evidence" : video.notes,
                timestamp: video.timestamp,
                metadata: metadata
            )
        } catch {
            print("Failed to sync video: \(error)")
        }
    }
    
    // MARK: - Download from Backend
    
    /// Fetch all timeline entries from backend
    func fetchTimelineFromBackend() async throws -> [TimelineEntry] {
        guard isSyncEnabled else {
            throw SyncError.syncDisabled
        }
        
        guard apiService.isAuthenticated else {
            throw SyncError.notAuthenticated
        }
        
        return try await apiService.getTimelineEntries()
    }
}

// MARK: - Sync Errors

enum SyncError: LocalizedError {
    case syncDisabled
    case notAuthenticated
    case syncInProgress
    case unsupportedType
    
    var errorDescription: String? {
        switch self {
        case .syncDisabled:
            return "Timeline sync is disabled. Enable it in Settings."
        case .notAuthenticated:
            return "You must be logged in to sync evidence."
        case .syncInProgress:
            return "Sync is already in progress."
        case .unsupportedType:
            return "This evidence type cannot be synced."
        }
    }
}

