import SwiftUI
import Combine

/// Manages the state of roadmap features and user votes
@MainActor
class RoadmapStore: ObservableObject {
    @Published var features: [RoadmapFeature] = RoadmapFeature.initialFeatures
    @Published var userVotes: [String: VoteType] = [:]
    @Published var voteCounts: [String: VoteCounts] = [:]
    
    private let userDefaults = UserDefaults.standard
    private let votesKey = "voiceit_roadmap_votes"
    private let countsKey = "voiceit_roadmap_counts" // Local simulation of global counts
    private let userIdKey = "voiceit_anon_user_id"
    
    var anonUserId: String {
        if let id = userDefaults.string(forKey: userIdKey) {
            return id
        }
        let newId = UUID().uuidString
        userDefaults.set(newId, forKey: userIdKey)
        return newId
    }
    
    enum VoteType: String, Codable {
        case interested
        case skipped
    }
    
    struct VoteCounts: Codable {
        var interested: Int
        var skipped: Int
    }
    
    init() {
        loadVotes()
        loadCounts()
        
        // Fetch real counts from backend on init
        Task {
            await fetchVoteCounts()
        }
    }
    
    // MARK: - Actions
    
    func vote(featureId: String, type: VoteType) {
        // Optimistic UI update (immediate)
        userVotes[featureId] = type
        saveVotes()
        
        // Update local counts optimistically
        var current = voteCounts[featureId] ?? VoteCounts(interested: 0, skipped: 0)
        if type == .interested {
            current.interested += 1
        } else {
            current.skipped += 1
        }
        voteCounts[featureId] = current
        saveCounts()
        
        // Track local analytics
        let action: RoadmapAnalytics.Action = type == .interested ? .interested : .skipped
        RoadmapAnalytics.shared.track(featureId: featureId, action: action, anonUserId: anonUserId)
        
        // Submit to backend asynchronously (don't block UI)
        Task {
            await submitVoteToBackend(featureId: featureId, type: type)
        }
    }
    
    /// Submit vote to backend (fire and forget - silent failure)
    private func submitVoteToBackend(featureId: String, type: VoteType) async {
        do {
            let voteTypeString = type == .interested ? "interested" : "not_important"
            let response = try await APIService.shared.submitRoadmapVote(
                featureId: featureId,
                voteType: voteTypeString,
                anonUserId: anonUserId
            )
            
            print("✅ Vote submitted to backend: \(featureId) -> \(voteTypeString)")
            if let voteId = response.voteId {
                print("   Vote ID: \(voteId)")
            }
            
            // Refresh counts after successful vote
            await fetchVoteCounts()
            
        } catch {
            // Silent failure - vote is already saved locally
            print("⚠️ Failed to submit vote to backend (vote saved locally): \(error.localizedDescription)")
        }
    }
    
    /// Fetch real vote counts from backend
    func fetchVoteCounts() async {
        do {
            let backendCounts = try await APIService.shared.getRoadmapVoteCounts()
            
            // Convert backend format to local format
            var convertedCounts: [String: VoteCounts] = [:]
            for (featureId, counts) in backendCounts {
                convertedCounts[featureId] = VoteCounts(
                    interested: counts.interested,
                    skipped: counts.skipped
                )
            }
            
            // Update published property (will trigger UI update)
            self.voteCounts = convertedCounts
            saveCounts() // Cache locally
            
            print("✅ Fetched vote counts from backend: \(convertedCounts.count) features")
            
        } catch {
            // Keep local counts on error
            print("⚠️ Failed to fetch counts from backend (using cached): \(error.localizedDescription)")
        }
    }
    
    func recordSponsorLead(featureId: String) {
        RoadmapAnalytics.shared.track(featureId: featureId, action: .sponsorLead, anonUserId: anonUserId)
    }
    
    func hasVoted(on featureId: String) -> Bool {
        return userVotes[featureId] != nil
    }
    
    func getCounts(for featureId: String) -> VoteCounts {
        // Return stored counts. In real app, would fetch from API.
        if let counts = voteCounts[featureId] {
            return counts
        }
        return VoteCounts(interested: 0, skipped: 0)
    }
    
    // MARK: - Persistence
    
    private func loadVotes() {
        guard let data = userDefaults.data(forKey: votesKey),
              let votes = try? JSONDecoder().decode([String: VoteType].self, from: data) else {
            return
        }
        self.userVotes = votes
    }
    
    private func saveVotes() {
        if let data = try? JSONEncoder().encode(userVotes) {
            userDefaults.set(data, forKey: votesKey)
        }
    }
    
    private func loadCounts() {
        guard let data = userDefaults.data(forKey: countsKey),
              let counts = try? JSONDecoder().decode([String: VoteCounts].self, from: data) else {
            return
        }
        self.voteCounts = counts
    }
    
    private func saveCounts() {
        if let data = try? JSONEncoder().encode(voteCounts) {
            userDefaults.set(data, forKey: countsKey)
        }
    }
}
