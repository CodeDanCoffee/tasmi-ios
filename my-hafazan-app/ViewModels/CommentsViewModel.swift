import Foundation
import Observation

@MainActor
@Observable
class CommentsViewModel {
    /// The API's own cap on a comment body.
    static let maximumBodyLength = 8000

    let postId: Int

    var comments: [Comment] = []
    var draft: String = ""
    var isLoading = false
    var isLoadingMore = false
    var isSubmitting = false
    var errorMessage: String?
    var submitError: String?

    private var currentPage = 1
    private var hasMorePages = false
    private var hasLoaded = false

    init(postId: Int) {
        self.postId = postId
    }

    // MARK: - Derived state

    var isEmpty: Bool { comments.isEmpty && !isLoading }

    var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSubmit: Bool {
        !trimmedDraft.isEmpty
            && trimmedDraft.count <= Self.maximumBodyLength
            && !isSubmitting
    }

    // MARK: - Loading

    func loadIfNeeded(auth: AuthManager) async {
        guard !hasLoaded else { return }
        await load(auth: auth)
    }

    func load(auth: AuthManager) async {
        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            let page = try await ReflectionsAPI.fetchComments(auth: auth, postId: postId, page: 1)
            comments = page.comments
            hasMorePages = page.hasMorePages
            hasLoaded = true
        } catch {
            comments = []
            hasMorePages = false
            errorMessage = "Couldn\u{2019}t load comments. Pull to try again."
        }

        isLoading = false
    }

    func loadMoreIfNeeded(auth: AuthManager, currentItem: Comment) async {
        guard hasMorePages, !isLoading, !isLoadingMore else { return }
        guard comments.suffix(3).contains(where: { $0.id == currentItem.id }) else { return }

        isLoadingMore = true
        let nextPage = currentPage + 1

        do {
            let page = try await ReflectionsAPI.fetchComments(auth: auth, postId: postId, page: nextPage)
            let known = Set(comments.map(\.id))
            comments.append(contentsOf: page.comments.filter { !known.contains($0.id) })
            currentPage = nextPage
            hasMorePages = page.hasMorePages
        } catch {
            hasMorePages = false
        }

        isLoadingMore = false
    }

    // MARK: - Posting

    /// Returns the new comment count so the card that opened this sheet can
    /// update without refetching the whole feed.
    @discardableResult
    func submit(auth: AuthManager) async -> Int? {
        guard canSubmit else { return nil }

        isSubmitting = true
        submitError = nil
        let body = trimmedDraft

        defer { isSubmitting = false }

        do {
            let created = try await ReflectionsAPI.createComment(
                auth: auth,
                postId: postId,
                body: body
            )
            if let created {
                comments.append(created)
            } else {
                // Created, but the response didn't echo it back — refetch so
                // the new comment isn't missing from the list.
                await load(auth: auth)
            }
            draft = ""
            return comments.count
        } catch {
            submitError = message(for: error)
            return nil
        }
    }

    private func message(for error: Error) -> String {
        switch error {
        case APIError.unauthorized:
            return "You aren\u{2019}t authorised to comment yet."
        case APIError.httpError(let status, _) where status == 401 || status == 403:
            return "You aren\u{2019}t authorised to comment yet."
        case APIError.httpError(let status, _) where status == 400 || status == 422:
            return "That comment couldn\u{2019}t be posted. Try rewording it."
        default:
            return "Couldn\u{2019}t post your comment. Check your connection and try again."
        }
    }
}
