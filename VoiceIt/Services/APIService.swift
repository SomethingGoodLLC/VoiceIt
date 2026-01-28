import Foundation
import Observation

/// Service for backend API communication
@Observable
final class APIService: @unchecked Sendable {
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = APIService()
    
    /// Current authentication token
    var authToken: String? {
        didSet {
            if let token = authToken {
                try? KeychainManager.shared.save(token.data(using: .utf8) ?? Data(), key: .authToken)
            } else {
                try? KeychainManager.shared.delete(key: .authToken)
            }
        }
    }
    
    /// Current authenticated user
    private(set) var currentUser: User?
    
    /// Whether user is authenticated with backend
    var isAuthenticated: Bool {
        authToken != nil
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load token from keychain on startup
        self.authToken = KeychainManager.shared.retrieveString(key: .authToken)
    }
    
    // MARK: - Authentication
    
    /// Sign up a new user
    func signUp(email: String, password: String, name: String?) async throws -> AuthResponse {
        let url = URL(string: "\(Constants.API.baseURL)\(Constants.API.Endpoints.signup)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.Network.requestTimeout
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "name": name ?? ""
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let authResponse = try decoder.decode(AuthResponse.self, from: data)
        
        // Store token
        if let token = authResponse.token {
            await MainActor.run {
                self.authToken = token
                self.currentUser = authResponse.user
            }
        }
        
        return authResponse
    }
    
    /// Log in existing user
    func login(email: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(Constants.API.baseURL)\(Constants.API.Endpoints.login)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.Network.requestTimeout
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            // Try to decode error message
            if let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: data),
               let message = errorResponse.message {
                throw APIError.serverError(message)
            }
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let authResponse = try decoder.decode(AuthResponse.self, from: data)
        
        // Store token
        if let token = authResponse.token {
            await MainActor.run {
                self.authToken = token
                self.currentUser = authResponse.user
            }
        }
        
        return authResponse
    }
    
    /// Verify current token
    func verifyToken() async throws -> AuthResponse {
        guard let token = authToken else {
            throw APIError.noToken
        }
        
        let url = URL(string: "\(Constants.API.baseURL)\(Constants.API.Endpoints.verifyToken)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.Network.requestTimeout
        
        let body: [String: Any] = ["token": token]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            // Token invalid, clear it
            await MainActor.run {
                self.authToken = nil
                self.currentUser = nil
            }
            throw APIError.invalidToken
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let authResponse = try decoder.decode(AuthResponse.self, from: data)
        
        await MainActor.run {
            self.currentUser = authResponse.user
        }
        
        return authResponse
    }
    
    /// Request password reset
    func forgotPassword(email: String) async throws -> AuthResponse {
        let url = URL(string: "\(Constants.API.baseURL)\(Constants.API.Endpoints.forgotPassword)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.Network.requestTimeout
        
        let body: [String: Any] = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(AuthResponse.self, from: data)
    }
    
    /// Log out
    func logout() {
        authToken = nil
        currentUser = nil
    }
    
    // MARK: - Analytics
    
    /// Track app open event (fire and forget - doesn't throw errors)
    func trackAppOpen() {
        guard let token = authToken else { return }
        
        Task {
            do {
                let url = URL(string: "\(Constants.API.baseURL)\(Constants.API.Endpoints.trackAppOpen)")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.timeoutInterval = 10 // Short timeout for analytics
                
                let body: [String: Any] = [
                    "timestamp": ISO8601DateFormatter().string(from: Date()),
                    "platform": "ios",
                    "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 App open tracked: \(httpResponse.statusCode)")
                }
            } catch {
                // Silently fail - analytics shouldn't block the app
                print("⚠️ Failed to track app open: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Timeline
    
    /// Get all timeline entries from backend
    func getTimelineEntries() async throws -> [TimelineEntry] {
        guard let token = authToken else {
            throw APIError.noToken
        }
        
        let url = URL(string: "\(Constants.API.baseURL)\(Constants.API.Endpoints.timelineEntries)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = Constants.Network.requestTimeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let timelineResponse = try decoder.decode(TimelineResponse.self, from: data)
        return timelineResponse.entries ?? []
    }
    
    /// Create a new timeline entry on backend
    func createTimelineEntry(
        type: String,
        content: String,
        timestamp: Date? = nil,
        metadata: [String: String]? = nil
    ) async throws -> TimelineEntry {
        guard let token = authToken else {
            throw APIError.noToken
        }
        
        let url = URL(string: "\(Constants.API.baseURL)\(Constants.API.Endpoints.timelineEntries)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = Constants.Network.requestTimeout
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        
        let body: [String: Any] = [
            "type": type,
            "content": content,
            "timestamp": ISO8601DateFormatter().string(from: timestamp ?? Date()),
            "metadata": metadata ?? [:]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        struct CreateResponse: Codable {
            let success: Bool
            let entry: TimelineEntry
        }
        
        let createResponse = try decoder.decode(CreateResponse.self, from: data)
        return createResponse.entry
    }
    
    // MARK: - Waitlist
    
    /// Join waitlist
    func joinWaitlist(email: String, phone: String?) async throws {
        let url = URL(string: "\(Constants.API.baseURL)\(Constants.API.Endpoints.waitlist)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.Network.requestTimeout
        
        let body: [String: Any] = [
            "email": email,
            "phone": phone ?? "",
            "source": "ios"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
    }
    
    // MARK: - Roadmap
    
    /// Submit a vote for a roadmap feature
    func submitRoadmapVote(
        featureId: String,
        voteType: String, // "interested" or "not_important"
        anonUserId: String
    ) async throws -> RoadmapVoteResponse {
        let url = URL(string: "\(Constants.API.baseURL)\(Constants.API.Endpoints.roadmapVote)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.Network.requestTimeout
        
        let body: [String: Any] = [
            "feature_id": featureId,
            "vote_type": voteType,
            "anon_user_id": anonUserId,
            "source": "ios",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(RoadmapVoteResponse.self, from: data)
            
        case 400...499:
            if let errorResponse = try? JSONDecoder().decode(RoadmapVoteResponse.self, from: data),
               let message = errorResponse.message {
                throw APIError.serverError(message)
            }
            throw APIError.serverError("Invalid vote request.")
            
        case 500...599:
            throw APIError.serverError("Server error. Please try again later.")
            
        default:
            throw APIError.invalidResponse
        }
    }
    
    /// Get vote counts for all roadmap features
    func getRoadmapVoteCounts() async throws -> [String: RoadmapVoteCounts] {
        let url = URL(string: "\(Constants.API.baseURL)\(Constants.API.Endpoints.roadmapVoteCounts)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = Constants.Network.requestTimeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let countsResponse = try decoder.decode(RoadmapVoteCountsResponse.self, from: data)
        
        return countsResponse.counts
    }
    
    /// Submit a sponsor referral for a roadmap feature
    func submitSponsorReferral(
        featureId: String,
        yourName: String,
        yourEmail: String,
        yourPhone: String?,
        sponsorName: String,
        sponsorEmail: String?,
        sponsorPhone: String?,
        relationship: String?,
        comments: String?,
        anonUserId: String
    ) async throws -> SponsorReferralResponse {
        let url = URL(string: "\(Constants.API.baseURL)\(Constants.API.Endpoints.roadmapSponsorReferral)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.Network.requestTimeout
        
        let body: [String: Any?] = [
            "feature_id": featureId,
            "referrer": [
                "name": yourName,
                "email": yourEmail,
                "phone": yourPhone
            ],
            "sponsor": [
                "name": sponsorName,
                "email": sponsorEmail,
                "phone": sponsorPhone
            ],
            "relationship": relationship,
            "comments": comments,
            "anon_user_id": anonUserId,
            "source": "ios",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Remove nil values
        let cleanedBody = body.compactMapValues { $0 }
        request.httpBody = try JSONSerialization.data(withJSONObject: cleanedBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Handle different status codes
        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(SponsorReferralResponse.self, from: data)
            
        case 400...499:
            // Client error - try to parse error message
            if let errorResponse = try? JSONDecoder().decode(SponsorReferralResponse.self, from: data),
               let message = errorResponse.message {
                throw APIError.serverError(message)
            }
            throw APIError.serverError("Invalid request. Please check your information.")
            
        case 500...599:
            throw APIError.serverError("Server error. Please try again later.")
            
        default:
            throw APIError.invalidResponse
        }
    }
}

// MARK: - Response Models

struct AuthResponse: Codable {
    let success: Bool
    let message: String?
    let token: String?
    let user: User?
}

struct User: Codable {
    let id: String
    let email: String
    let name: String?
}

struct TimelineEntry: Codable {
    let id: String
    let userId: String
    let type: String // 'voice', 'text', 'photo', 'video'
    let content: String
    let timestamp: String
    let metadata: [String: String]?
    let createdAt: String
}

struct TimelineResponse: Codable {
    let success: Bool
    let entries: [TimelineEntry]?
    let message: String?
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidResponse
    case noToken
    case invalidToken
    case serverError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .noToken:
            return "No authentication token found. Please log in."
        case .invalidToken:
            return "Authentication token is invalid or expired. Please log in again."
        case .serverError(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Roadmap Models

struct RoadmapVoteResponse: Codable {
    let success: Bool
    let message: String?
    let voteId: String?
}

struct RoadmapVoteCounts: Codable {
    let interested: Int
    let skipped: Int
}

struct RoadmapVoteCountsResponse: Codable {
    let success: Bool
    let counts: [String: RoadmapVoteCounts]
}

struct SponsorReferralResponse: Codable {
    let success: Bool
    let message: String?
    let referralId: String?
}

