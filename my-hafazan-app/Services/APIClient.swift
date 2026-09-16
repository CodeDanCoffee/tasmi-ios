import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case networkError(Error)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .httpError(let code, _): return "HTTP error \(code)"
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .networkError(let error): return error.localizedDescription
        case .unauthorized: return "Unauthorized"
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func get<T: Decodable>(
        url: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        type: T.Type
    ) async throws -> T {
        guard var components = URLComponents(string: url) else {
            throw APIError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = (components.queryItems ?? []) + queryItems
        }
        guard let finalURL = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return try await execute(request, type: type)
    }

    func post<T: Decodable>(
        url: String,
        body: [String: String],
        headers: [String: String] = [:],
        type: T.Type
    ) async throws -> T {
        guard let finalURL = URL(string: url) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyString = body.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return try await execute(request, type: type)
    }

    /// General-purpose request for JSON APIs. `jsonBody` is sent as-is when present.
    func send<T: Decodable>(
        _ method: String,
        url: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        jsonBody: Data? = nil,
        type: T.Type
    ) async throws -> T {
        guard var components = URLComponents(string: url) else {
            throw APIError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = (components.queryItems ?? []) + queryItems
        }
        guard let finalURL = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let jsonBody {
            request.httpBody = jsonBody
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return try await execute(request, type: type)
    }

    private func execute<T: Decodable>(_ request: URLRequest, type: T.Type) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            debugLog(request, status: httpResponse.statusCode, data: data, detail: nil)
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        do {
            return try decoder.decode(type, from: data)
        } catch {
            debugLog(request, status: httpResponse.statusCode, data: data, detail: String(describing: error))
            throw APIError.decodingError(error)
        }
    }

    /// Dumps the failing request/response so the real cause is visible instead
    /// of the generic message the UI shows. Headers are never logged — they
    /// carry the access token.
    private func debugLog(_ request: URLRequest, status: Int, data: Data?, detail: String?) {
        #if DEBUG
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"
        print("[APIClient] \(method) \(url) -> \(status)")
        if let sent = request.httpBody, let body = String(data: sent, encoding: .utf8) {
            print("[APIClient] sent: \(body.prefix(1200))")
        }
        if let detail { print("[APIClient] decode failed: \(detail)") }
        if let data, let body = String(data: data, encoding: .utf8), !body.isEmpty {
            print("[APIClient] body: \(body.prefix(1200))")
        }
        #endif
    }
}
