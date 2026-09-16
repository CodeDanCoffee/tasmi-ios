import Foundation

// MARK: - Comment

/// A comment on a QuranReflect post. Like `Reflection`, only `id` is really
/// guaranteed — the list, create, and edit responses each return a slightly
/// different subset of the rest.
struct Comment: Decodable, Identifiable, Hashable {
    let id: Int
    let postId: Int?
    let authorId: String?
    /// Set when this comment is a reply to another comment.
    let parentId: Int?
    let isPrivate: Bool?
    let body: String?
    let createdAt: String?
    let updatedAt: String?
    let repliesCount: Int?
    let likesCount: Int?
    let reported: Bool?
    let removed: Bool?
    let hidden: Bool?
    let languageName: String?
    /// Same shape as a post author, so the display helpers are shared.
    let author: ReflectionAuthor?

    var isReply: Bool { parentId != nil }

    var postedDate: Date? {
        ISO8601.date(from: createdAt)
    }

    var relativeTimestamp: String? {
        guard let postedDate else { return nil }
        return DateFormatters.relativeString(from: postedDate)
    }

    var trimmedBody: String {
        (body ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Pagination

/// Post comments arrive under `comments`, a comment's replies under `replies`.
/// The envelope is otherwise identical, so one type decodes both rather than
/// duplicating the pagination fields.
struct CommentPage: Decodable {
    let total: Int?
    let currentPage: Int?
    let limit: Int?
    let pages: Int?
    let comments: [Comment]

    private enum CodingKeys: String, CodingKey {
        case total, currentPage, limit, pages, comments, replies
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try container.decodeIfPresent(Int.self, forKey: .total)
        currentPage = try container.decodeIfPresent(Int.self, forKey: .currentPage)
        limit = try container.decodeIfPresent(Int.self, forKey: .limit)
        pages = try container.decodeIfPresent(Int.self, forKey: .pages)
        comments = try container.decodeIfPresent([Comment].self, forKey: .comments)
            ?? container.decodeIfPresent([Comment].self, forKey: .replies)
            ?? []
    }

    var hasMorePages: Bool {
        guard let currentPage, let pages else { return false }
        return currentPage < pages
    }
}

// MARK: - Requests

struct CreateCommentRequest: Encodable {
    let comment: Body

    /// `body`, `postId` and `isPrivate` are all required by the API even
    /// though `isPrivate` documents a default.
    ///
    /// `postId` is a **string** even though the spec declares it a number —
    /// sending a JSON number is rejected with `{"postId": "INVALID"}`. The
    /// QuranReflect web client stringifies it too (`postId: T.toString()`).
    /// `parentId` really is a number, so the inconsistency is deliberate.
    struct Body: Encodable {
        var body: String
        var postId: String
        var isPrivate: Bool
        var parentId: Int?
    }
}

struct EditCommentRequest: Encodable {
    let comment: Body

    struct Body: Encodable {
        var body: String
    }
}

// MARK: - Responses

/// `POST /v1/comments` wraps the new comment in `comment`…
struct CreateCommentResponse: Decodable {
    let comment: Comment?
}

/// …while `PATCH /v1/comments/{id}` wraps the updated one in `data`.
struct EditCommentResponse: Decodable {
    let data: Comment?
}

/// Shared by both toggle-like endpoints: the state *after* the toggle.
struct LikeStateResponse: Decodable {
    let liked: Bool?
}

struct DeleteCommentResponse: Decodable {
    let removed: Bool?
}
