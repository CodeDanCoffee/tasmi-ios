import AuthenticationServices
import CryptoKit
import Observation
import SwiftUI
import UIKit

enum AuthError: LocalizedError {
    case authFailed
    case codeMissing
    case providerError(code: String, description: String?)
    case backendError(String)
    case refreshFailed
    case invalidResponse
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .authFailed:          return "Sign-in was cancelled or failed."
        case .codeMissing:         return "Authorization code was not returned."
        case .providerError(let code, let description):
            if let description, !description.isEmpty { return "\(code): \(description)" }
            return code
        case .backendError(let s): return "Backend error: \(s)"
        case .refreshFailed:       return "Session expired. Please sign in again."
        case .invalidResponse:     return "Unexpected response from server."
        case .notAuthenticated:    return "You are not signed in."
        }
    }
}

@MainActor
@Observable
final class AuthManager: NSObject {
    private(set) var isAuthenticated: Bool = false
    private(set) var isLoading: Bool = false
    var lastError: String?

    var userEmail: String? {
        guard let idToken = KeychainStore.read(KeychainStore.Key.idToken) else { return nil }
        return JWT.claim("email", in: idToken) as? String
    }

    var userName: String? {
        guard let idToken = KeychainStore.read(KeychainStore.Key.idToken) else { return nil }
        if let name = JWT.claim("name", in: idToken) as? String, !name.isEmpty {
            return name
        }
        let given = JWT.claim("given_name", in: idToken) as? String
        let family = JWT.claim("family_name", in: idToken) as? String
        let combined = [given, family].compactMap { $0 }.joined(separator: " ")
        if !combined.isEmpty { return combined }
        if let nickname = JWT.claim("nickname", in: idToken) as? String, !nickname.isEmpty {
            return nickname
        }
        return JWT.claim("preferred_username", in: idToken) as? String
    }

    /// User-set display name override, persisted in UserDefaults.
    var displayName: String? {
        get { UserDefaults.standard.string(forKey: "displayName") }
        set {
            if let v = newValue, !v.trimmingCharacters(in: .whitespaces).isEmpty {
                UserDefaults.standard.set(v.trimmingCharacters(in: .whitespaces), forKey: "displayName")
            } else {
                UserDefaults.standard.removeObject(forKey: "displayName")
            }
        }
    }

    private var authSession: ASWebAuthenticationSession?
    private var pendingCodeVerifier: String?
    private let presentationContext = AuthPresentationContext()

    override init() {
        super.init()
        discardSessionFromOtherIssuer()
        isAuthenticated = KeychainStore.read(KeychainStore.Key.accessToken) != nil
    }

    /// Tokens are only valid against the issuer that minted them. Pointing the
    /// app at a different environment leaves a stale session in the Keychain
    /// that still looks signed in, but every API call fails with a confusing
    /// 401, so drop it and make the user sign in again.
    private func discardSessionFromOtherIssuer() {
        guard KeychainStore.read(KeychainStore.Key.accessToken) != nil else { return }
        let current = AuthConfig.issuer.absoluteString
        guard KeychainStore.read(KeychainStore.Key.issuer) != current else { return }
        signOut()
    }

    // MARK: - Login

    func signIn() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let verifier = PKCE.generateCodeVerifier()
            let challenge = PKCE.codeChallenge(for: verifier)
            self.pendingCodeVerifier = verifier

            let authURL = try buildAuthorizationURL(codeChallenge: challenge)
            let callback = try await present(authURL: authURL)
            let code = try extractCode(from: callback)

            try await exchangeCodeWithBackend(code: code, codeVerifier: verifier)
            self.pendingCodeVerifier = nil

            isAuthenticated = true
        } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
            // user cancelled — silent
        } catch {
            lastError = error.localizedDescription
            isAuthenticated = false
        }
    }

    // MARK: - Logout

    func signOut() {
        KeychainStore.delete(KeychainStore.Key.accessToken)
        KeychainStore.delete(KeychainStore.Key.refreshToken)
        KeychainStore.delete(KeychainStore.Key.idToken)
        KeychainStore.delete(KeychainStore.Key.expiresAt)
        KeychainStore.delete(KeychainStore.Key.issuer)
        isAuthenticated = false
    }

    // MARK: - URL handoff

    /// Called from `.onOpenURL`. `ASWebAuthenticationSession` already
    /// intercepts the callback for the registered scheme, so this is a
    /// no-op fallback for edge cases (universal links, cold-start, etc.).
    @discardableResult
    func resume(with url: URL) -> Bool {
        url.scheme?.lowercased() == AuthConfig.callbackScheme.lowercased()
    }

    // MARK: - Token access

    /// Returns a valid access token, refreshing if needed.
    func validAccessToken() async throws -> String {
        if let token = KeychainStore.read(KeychainStore.Key.accessToken),
           let expiresAtStr = KeychainStore.read(KeychainStore.Key.expiresAt),
           let expiresAt = TimeInterval(expiresAtStr),
           Date().timeIntervalSince1970 < expiresAt - 60 {
            return token
        }
        return try await refreshAccessToken()
    }

    // MARK: - Internals

    private func buildAuthorizationURL(codeChallenge: String) throws -> URL {
        var components = URLComponents(url: AuthConfig.authorizationEndpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: AuthConfig.clientID),
            URLQueryItem(name: "redirect_uri", value: AuthConfig.redirectURI.absoluteString),
            URLQueryItem(name: "scope", value: AuthConfig.scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: UUID().uuidString),
        ]
        guard let url = components?.url else { throw AuthError.authFailed }
        return url
    }

    private func present(authURL: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callback: .customScheme(AuthConfig.callbackScheme)
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: AuthError.authFailed)
                }
            }
            session.presentationContextProvider = presentationContext
            session.prefersEphemeralWebBrowserSession = false
            self.authSession = session
            session.start()
        }
    }

    private func extractCode(from callbackURL: URL) throws -> String {
        let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []

        if let errorCode = items.first(where: { $0.name == "error" })?.value, !errorCode.isEmpty {
            let description = items.first(where: { $0.name == "error_description" })?.value
            throw AuthError.providerError(code: errorCode, description: description)
        }

        guard let code = items.first(where: { $0.name == "code" })?.value, !code.isEmpty else {
            throw AuthError.codeMissing
        }
        return code
    }

    private func exchangeCodeWithBackend(code: String, codeVerifier: String) async throws {
        var req = URLRequest(url: AuthConfig.backendExchangeURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = [
            "code": code,
            "code_verifier": codeVerifier,
            "redirect_uri": AuthConfig.redirectURI.absoluteString,
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AuthError.backendError(String(data: data, encoding: .utf8) ?? "")
        }
        try storeTokens(from: data)
    }

    private func refreshAccessToken() async throws -> String {
        guard let refresh = KeychainStore.read(KeychainStore.Key.refreshToken) else {
            throw AuthError.notAuthenticated
        }
        var req = URLRequest(url: AuthConfig.backendRefreshURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["refresh_token": refresh])

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            signOut()
            throw AuthError.refreshFailed
        }
        try storeTokens(from: data)
        guard let token = KeychainStore.read(KeychainStore.Key.accessToken) else {
            throw AuthError.refreshFailed
        }
        return token
    }

    private func storeTokens(from data: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AuthError.invalidResponse
        }
        if let access = json["access_token"] as? String {
            KeychainStore.save(access, for: KeychainStore.Key.accessToken)
        }
        if let refresh = json["refresh_token"] as? String {
            KeychainStore.save(refresh, for: KeychainStore.Key.refreshToken)
        }
        if let id = json["id_token"] as? String {
            KeychainStore.save(id, for: KeychainStore.Key.idToken)
        }
        if let expiresIn = json["expires_in"] as? TimeInterval {
            let expiresAt = Date().timeIntervalSince1970 + expiresIn
            KeychainStore.save(String(expiresAt), for: KeychainStore.Key.expiresAt)
        }
        KeychainStore.save(AuthConfig.issuer.absoluteString, for: KeychainStore.Key.issuer)
    }
}

// MARK: - JWT

private enum JWT {
    static func claim(_ name: String, in token: String) -> Any? {
        let segments = token.split(separator: ".")
        guard segments.count >= 2 else { return nil }
        let payload = String(segments[1])
        guard let data = base64URLDecode(payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json[name]
    }

    private static func base64URLDecode(_ s: String) -> Data? {
        var str = s.replacingOccurrences(of: "-", with: "+")
                   .replacingOccurrences(of: "_", with: "/")
        let padding = 4 - str.count % 4
        if padding < 4 { str += String(repeating: "=", count: padding) }
        return Data(base64Encoded: str)
    }
}

// MARK: - PKCE

private enum PKCE {
    static func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    static func codeChallenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - Presentation context

private final class AuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
