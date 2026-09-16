import Foundation

enum UserAPI {
    private static let baseURL = "https://apis.quran.foundation"
    private static let clientId = "QURAN_APP_CLIENT_ID"

    struct StreakResponse: Codable {
        let streak: Int?
        let longestStreak: Int?
    }

    struct GoalsResponse: Codable {
        let goals: [UserGoal]?
    }

    struct UserGoal: Codable {
        let id: String?
        let type: String?
        let targetAmount: Int?
        let currentAmount: Int?
    }

    static func fetchStreak(auth: AuthManager) async throws -> StreakResponse {
        let headers = try await authHeaders(auth: auth)
        return try await APIClient.shared.get(
            url: "\(baseURL)/auth/v1/streak",
            headers: headers,
            type: StreakResponse.self
        )
    }

    static func fetchGoals(auth: AuthManager) async throws -> GoalsResponse {
        let headers = try await authHeaders(auth: auth)
        return try await APIClient.shared.get(
            url: "\(baseURL)/auth/v1/goals",
            headers: headers,
            type: GoalsResponse.self
        )
    }

    private static func authHeaders(auth: AuthManager) async throws -> [String: String] {
        let token = try await auth.validAccessToken()
        return [
            "x-client-id": clientId,
            "x-auth-token": token,
        ]
    }
}
