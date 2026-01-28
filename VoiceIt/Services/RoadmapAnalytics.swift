import Foundation

/// Analytics service for tracking roadmap engagement
final class RoadmapAnalytics: @unchecked Sendable {
    static let shared = RoadmapAnalytics()
    
    private let eventsKey = "voiceit_roadmap_events"
    private let queue = DispatchQueue(label: "com.voiceit.roadmapanalytics")
    
    private init() {}
    
    struct Event: Codable, Identifiable {
        let id: UUID
        let featureId: String
        let action: String
        let timestamp: Date
        let anonUserId: String
        
        init(featureId: String, action: String, timestamp: Date, anonUserId: String) {
            self.id = UUID()
            self.featureId = featureId
            self.action = action
            self.timestamp = timestamp
            self.anonUserId = anonUserId
        }
    }
    
    /// Track a user action on a roadmap feature
    func track(featureId: String, action: Action, anonUserId: String) {
        let event = Event(
            featureId: featureId,
            action: action.rawValue,
            timestamp: Date(),
            anonUserId: anonUserId
        )
        
        // Log to console for development
        print("📊 Roadmap Analytics: \(action.rawValue) on \(featureId) by \(anonUserId)")
        
        // Save locally for debug view
        saveLocally(event)
        
        // In a real app, this would POST to a backend
        // For now, we'll just log it. If a backend existed:
        /*
        guard let url = URL(string: "https://api.voiceit.app/roadmap/events") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode(event)
        // ... send request
        */
    }
    
    private func saveLocally(_ event: Event) {
        queue.async { [weak self] in
            guard let self = self else { return }
            var events = self.loadEventsSync()
            events.append(event)
            // Keep only last 100 events to avoid unbounded growth
            if events.count > 100 {
                events = Array(events.suffix(100))
            }
            if let data = try? JSONEncoder().encode(events) {
                UserDefaults.standard.set(data, forKey: self.eventsKey)
            }
        }
    }
    
    /// Load all stored events (for debug view)
    func loadEvents() -> [Event] {
        return loadEventsSync()
    }
    
    private func loadEventsSync() -> [Event] {
        guard let data = UserDefaults.standard.data(forKey: eventsKey),
              let events = try? JSONDecoder().decode([Event].self, from: data) else {
            return []
        }
        return events
    }
    
    /// Clear all stored events (for debug)
    func clearEvents() {
        queue.async { [weak self] in
            guard let self = self else { return }
            UserDefaults.standard.removeObject(forKey: self.eventsKey)
        }
    }
    
    enum Action: String {
        case interested = "interested"
        case skipped = "not_important"
        case sponsorLead = "sponsor_lead"
        case viewDetail = "view_detail"
    }
}
