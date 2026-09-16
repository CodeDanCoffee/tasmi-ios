import Foundation

enum AuthConfig {
    static let issuer = URL(string: "https://oauth2.quran.foundation")!

    static let authorizationEndpoint = URL(string: "https://oauth2.quran.foundation/oauth2/auth")!

    static let backendExchangeURL = URL(string: "https://api.tasmi.cloud/auth/exchange")!
    static let backendRefreshURL  = URL(string: "https://api.tasmi.cloud/auth/refresh")!

    static let clientID = "7a183a3e-bac6-4072-8481-93251b71bc02"

    static let redirectURI = URL(string: "com.tasmi.app://oauth/callback")!
    static let callbackScheme = "com.tasmi.app"

    /// Mirrors the scope list approved for this client in the Quran Foundation
    /// Developer Console — that console, not the public scope docs, is the
    /// source of truth (some approved scopes, e.g. "sync", aren't documented).
    /// "post" is the parent scope granting full QuranReflect post access; it
    /// implies its children (post.create, post.delete, post.export, post.like,
    /// post.log, post.read, post.report, …), so they need not be listed.
    static let scopes = [
        "openid", "profile", "offline_access",
        "post",
        "bookmark", "comment", "streak", "sync", "tag", "user",
    ]

    static let userAPIBaseURL = URL(string: "https://apis.quran.foundation")!

    /// QuranReflect (reflections/posts) service, mounted under the same gateway.
    static let quranReflectBaseURL = "https://apis.quran.foundation/quran-reflect"
}
