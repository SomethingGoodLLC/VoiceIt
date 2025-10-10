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
        get {
            KeychainManager.shared.retrieveString(key: .authToken)
        }
        set {
            if let token = newValue {
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
    
    private init() {}
    
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


