import Foundation
import Observation

/// The Reflections tab shows one feed only: everything tagged #Tasmi, newest
/// first. `newest` rather than `trending`, because trending is a curated set
/// that silently drops posts without traction — which would hide most of the
/// app's own reflections.
@MainActor
@Observable
class ReflectionsViewModel {
    var reflections: [Reflection] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?

    private var currentPage = 1
    private var hasMorePages = false
    private var hasLoaded = false

    var isEmpty: Bool { reflections.isEmpty && !isLoading }

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
            let feed = try await fetch(auth: auth, page: 1)
            reflections = feed.data
            hasMorePages = feed.hasMorePages
            hasLoaded = true
        } catch {
            reflections = []
            hasMorePages = false
            errorMessage = message(for: error)
        }

        isLoading = false
    }

    func refresh(auth: AuthManager) async {
        hasLoaded = false
        await load(auth: auth)
    }

    func loadMoreIfNeeded(auth: AuthManager, currentItem: Reflection) async {
        guard hasMorePages, !isLoading, !isLoadingMore else { return }
        guard reflections.suffix(3).contains(where: { $0.id == currentItem.id }) else { return }

        isLoadingMore = true
        let nextPage = currentPage + 1

        do {
            let feed = try await fetch(auth: auth, page: nextPage)
            let known = Set(reflections.map(\.id))
            reflections.append(contentsOf: feed.data.filter { !known.contains($0.id) })
            currentPage = nextPage
            hasMorePages = feed.hasMorePages
        } catch {
            hasMorePages = false
        }

        isLoadingMore = false
    }

    private func fetch(auth: AuthManager, page: Int) async throws -> ReflectionFeed {
        try await ReflectionsAPI.fetchFeed(
            auth: auth,
            tab: .newest,
            tags: ReflectionsAPI.tasmiTags,
            page: page
        )
    }

    // MARK: - Helpers

    private func message(for error: Error) -> String {
        if case APIError.httpError(let status, _) = error, status == 401 || status == 403 {
            return "Your account isn\u{2019}t authorised for reflections yet. Sign out and back in to grant access."
        }
        if case APIError.unauthorized = error {
            return "Your account isn\u{2019}t authorised for reflections yet. Sign out and back in to grant access."
        }
        return "Couldn\u{2019}t load reflections. Pull to try again."
    }
}
