import Foundation

/// QuranReflect posts ("reflections") on the Quran Foundation user API.
///
/// Base URL is `{gateway}/quran-reflect`; every endpoint is authenticated with
/// the `x-auth-token` / `x-client-id` header pair rather than a Bearer token.
enum ReflectionsAPI {
    private static let baseURL = AuthConfig.quranReflectBaseURL

    /// Feed tabs the app exposes. The API supports more; these are the ones
    /// that make sense without rooms or a social graph.
    enum Tab: String, CaseIterable, Identifiable {
        case trending
        case following
        /// Every public post, newest first. `trending` is the curated explore
        /// set, so it silently drops posts that haven't gained traction — use
        /// this one whenever the point is to find *all* matches for a filter.
        case newest

        var id: String { rawValue }

        var title: String {
            switch self {
            case .trending:  return "Trending"
            case .following: return "Following"
            case .newest:    return "Newest"
            }
        }
    }

    /// Reflections written by the signed-in user.
    static let myPostsTab = "my_reflections"

    /// The hashtag the app's own community feed is built around, matched by
    /// name without the leading `#`. This is the casing we publish with.
    static let tasmiTag = "tasmi"

    /// Every casing to match when *reading* the feed. Tag matching is
    /// case-sensitive, so `#tasmi` and `#Tasmi` are two distinct tags as far as
    /// the API is concerned — a casing missing from this list means those posts
    /// simply don't come back. Sent together under `filter[tagsOperator]=OR`.
    static let tasmiTags = [tasmiTag, "Tasmi", "TASMI"]

    // MARK: - Reads

    /// `tags` filters to posts carrying *any* of the given tag names (the API
    /// takes them comma-separated, without the leading `#`).
    static func fetchFeed(
        auth: AuthManager,
        tab: Tab = .trending,
        sortBy: String = "latest",
        tags: [String] = [],
        page: Int = 1,
        limit: Int = 20
    ) async throws -> ReflectionFeed {
        var queryItems = [
            URLQueryItem(name: "tab", value: tab.rawValue),
            URLQueryItem(name: "sortBy", value: sortBy),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
        ]

        if !tags.isEmpty {
            queryItems.append(URLQueryItem(name: "filter[tags]", value: tags.joined(separator: ",")))
            if tags.count > 1 {
                queryItems.append(URLQueryItem(name: "filter[tagsOperator]", value: "OR"))
            }
        }

        return try await APIClient.shared.send(
            "GET",
            url: "\(baseURL)/v1/posts/feed",
            queryItems: queryItems,
            headers: try await authHeaders(auth: auth),
            type: ReflectionFeed.self
        )
    }

    static func fetchMyPosts(
        auth: AuthManager,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> ReflectionFeed {
        try await APIClient.shared.send(
            "GET",
            url: "\(baseURL)/v1/posts/my-posts",
            queryItems: [
                URLQueryItem(name: "tab", value: myPostsTab),
                URLQueryItem(name: "sortBy", value: "latest"),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)"),
            ],
            headers: try await authHeaders(auth: auth),
            type: ReflectionFeed.self
        )
    }

    // MARK: - Writes

    /// Publishes a reflection. `references` anchors it to an ayah range so it
    /// surfaces on those verses in QuranReflect and Quran.com.
    @discardableResult
    static func createPost(
        auth: AuthManager,
        body: String,
        references: [CreateReflectionRequest.Reference],
        tags: [String] = [],
        draft: Bool = false
    ) async throws -> Reflection? {
        let payload = CreateReflectionRequest(
            post: .init(
                body: body,
                draft: draft,
                references: references,
                tags: tags.isEmpty ? nil : tags
            )
        )

        let response = try await APIClient.shared.send(
            "POST",
            url: "\(baseURL)/v1/posts",
            headers: try await authHeaders(auth: auth),
            jsonBody: try JSONEncoder().encode(payload),
            type: CreateReflectionResponse.self
        )
        return response.data
    }

    // MARK: - Likes

    /// Flips the like on a post and returns the state it landed in — the API
    /// has no separate like/unlike, only this toggle.
    @discardableResult
    static func toggleLike(auth: AuthManager, postId: Int) async throws -> Bool {
        let response = try await APIClient.shared.send(
            "POST",
            url: "\(baseURL)/v1/posts/\(postId)/toggle-like",
            headers: try await authHeaders(auth: auth),
            type: LikeStateResponse.self
        )
        return response.liked ?? false
    }

    /// Whether the signed-in user has already liked this post.
    static func likedState(auth: AuthManager, postId: Int) async throws -> Bool {
        let response = try await APIClient.shared.send(
            "GET",
            url: "\(baseURL)/v1/posts/\(postId)/liked",
            headers: try await authHeaders(auth: auth),
            type: LikeStateResponse.self
        )
        return response.liked ?? false
    }

    @discardableResult
    static func toggleCommentLike(auth: AuthManager, commentId: Int) async throws -> Bool {
        let response = try await APIClient.shared.send(
            "POST",
            url: "\(baseURL)/v1/comments/\(commentId)/toggle-like",
            headers: try await authHeaders(auth: auth),
            type: LikeStateResponse.self
        )
        return response.liked ?? false
    }

    // MARK: - Comments

    /// Top-level comments on a post. Replies hang off each comment and are
    /// fetched separately via `fetchReplies`.
    static func fetchComments(
        auth: AuthManager,
        postId: Int,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> CommentPage {
        try await APIClient.shared.send(
            "GET",
            url: "\(baseURL)/v1/posts/\(postId)/comments",
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)"),
            ],
            headers: try await authHeaders(auth: auth),
            type: CommentPage.self
        )
    }

    static func fetchReplies(
        auth: AuthManager,
        commentId: Int,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> CommentPage {
        try await APIClient.shared.send(
            "GET",
            url: "\(baseURL)/v1/comments/\(commentId)/replies",
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)"),
            ],
            headers: try await authHeaders(auth: auth),
            type: CommentPage.self
        )
    }

    /// Passing `parentId` makes this a reply to that comment rather than a
    /// top-level comment on the post.
    @discardableResult
    static func createComment(
        auth: AuthManager,
        postId: Int,
        body: String,
        parentId: Int? = nil,
        isPrivate: Bool = false
    ) async throws -> Comment? {
        let payload = CreateCommentRequest(
            comment: .init(body: body, postId: String(postId), isPrivate: isPrivate, parentId: parentId)
        )

        let response = try await APIClient.shared.send(
            "POST",
            url: "\(baseURL)/v1/comments",
            headers: try await authHeaders(auth: auth),
            jsonBody: try JSONEncoder().encode(payload),
            type: CreateCommentResponse.self
        )
        return response.comment
    }

    @discardableResult
    static func editComment(
        auth: AuthManager,
        commentId: Int,
        body: String
    ) async throws -> Comment? {
        let payload = EditCommentRequest(comment: .init(body: body))

        let response = try await APIClient.shared.send(
            "PATCH",
            url: "\(baseURL)/v1/comments/\(commentId)",
            headers: try await authHeaders(auth: auth),
            jsonBody: try JSONEncoder().encode(payload),
            type: EditCommentResponse.self
        )
        return response.data
    }

    /// Deletion is a `GET` on `/delete`, not a `DELETE` on the resource — the
    /// API really is shaped this way, so don't "fix" it to match REST.
    @discardableResult
    static func deleteComment(auth: AuthManager, commentId: Int) async throws -> Bool {
        let response = try await APIClient.shared.send(
            "GET",
            url: "\(baseURL)/v1/comments/\(commentId)/delete",
            headers: try await authHeaders(auth: auth),
            type: DeleteCommentResponse.self
        )
        return response.removed ?? false
    }

    // MARK: - Auth

    private static func authHeaders(auth: AuthManager) async throws -> [String: String] {
        let token = try await auth.validAccessToken()
        return [
            "x-auth-token": token,
            "x-client-id": AuthConfig.clientID,
        ]
    }
}
