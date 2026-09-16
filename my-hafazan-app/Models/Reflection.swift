import Foundation

// MARK: - Feed envelope

struct ReflectionFeed: Decodable {
    let total: Int?
    let currentPage: Int?
    let limit: Int?
    let pages: Int?
    let data: [Reflection]

    var hasMorePages: Bool {
        guard let currentPage, let pages else { return false }
        return currentPage < pages
    }
}

// MARK: - Post

/// A QuranReflect post. Only `id` is guaranteed by the API; the feed and the
/// create response return overlapping-but-different subsets of the rest.
struct Reflection: Decodable, Identifiable, Hashable {
    let id: Int
    let authorId: String?
    let body: String?
    let draft: Bool?
    let verified: Bool?
    let createdAt: String?
    let publishedAt: String?
    let viewsCount: Int?
    /// Seconds, and fractional — decoding this as `Int` fails the whole feed.
    let estimatedReadingTime: Double?
    let languageName: String?
    let postTypeName: String?
    let author: ReflectionAuthor?
    let references: [ReflectionReference]?
    let tags: [ReflectionTag]?
    /// Engagement, as of the moment the feed was fetched. `isLiked` is
    /// per-user, so it's only meaningful on an authenticated request.
    let likesCount: Int?
    let commentsCount: Int?
    let isLiked: Bool?

    var postedDate: Date? {
        ISO8601.date(from: publishedAt) ?? ISO8601.date(from: createdAt)
    }

    var relativeTimestamp: String? {
        guard let postedDate else { return nil }
        return DateFormatters.relativeString(from: postedDate)
    }

    var trimmedBody: String {
        (body ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ReflectionAuthor: Decodable, Hashable {
    let id: String?
    let username: String?
    let firstName: String?
    let lastName: String?
    let verified: Bool?
    let avatarUrls: AvatarURLs?

    struct AvatarURLs: Decodable, Hashable {
        let small: String?
        let medium: String?
        let large: String?
    }

    var displayName: String {
        let full = [firstName, lastName]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        if !full.isEmpty { return full }
        if let username, !username.isEmpty { return username }
        return "Someone"
    }

    var initials: String {
        let parts = displayName.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init).joined()
        return letters.isEmpty ? "?" : letters.uppercased()
    }

    var avatarURL: URL? {
        guard let raw = avatarUrls?.medium ?? avatarUrls?.small ?? avatarUrls?.large,
              !raw.isEmpty else { return nil }
        return URL(string: raw)
    }
}

struct ReflectionReference: Decodable, Hashable {
    let id: String?
    let chapterId: Int?
    let from: Int?
    let to: Int?

    /// e.g. "Al-Fatihah 1–7"
    var label: String {
        guard let chapterId else { return "Qur'an" }
        let name = ChapterNames.englishName(for: chapterId) ?? "Surah \(chapterId)"
        guard let from, from > 0 else { return name }
        guard let to, to > from else { return "\(name) \(from)" }
        return "\(name) \(from)\u{2013}\(to)"
    }

    var arabicName: String? {
        guard let chapterId else { return nil }
        return ChapterNames.arabicName(for: chapterId)
    }
}

struct ReflectionTag: Decodable, Hashable {
    let id: Int?
    let name: String?
    let language: String?
}

// MARK: - Create

struct CreateReflectionRequest: Encodable {
    let post: Post

    struct Post: Encodable {
        var body: String
        var draft: Bool
        var references: [Reference]
        var mentions: [Mention] = []
        var tags: [String]?
    }

    struct Reference: Encodable {
        let chapterId: Int
        let from: Int
        let to: Int
    }

    struct Mention: Encodable {
        let marker: String
        let userId: String
        let displayName: String
    }
}

struct CreateReflectionResponse: Decodable {
    let data: Reflection?
}

// MARK: - Date parsing

enum ISO8601 {
    private static let withFractionalSeconds: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let plain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func date(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return withFractionalSeconds.date(from: string) ?? plain.date(from: string)
    }
}
