import Foundation
import Observation

@MainActor
@Observable
class ComposeReflectionViewModel {
    /// The API rejects anything shorter.
    static let minimumBodyLength = 6

    let chapterId: Int
    let verseStart: Int
    let verseEnd: Int
    let surahName: String

    var text: String
    /// Attached to everything the app publishes, so these reflections are
    /// findable in the app's own #Tasmi feed.
    var tags: [String] = [ReflectionsAPI.tasmiTag]
    var isDraft = false
    var isSubmitting = false
    var errorMessage: String?
    private(set) var didPublish = false

    init(chapterId: Int, verseStart: Int, verseEnd: Int, surahName: String, initialText: String = "") {
        self.chapterId = chapterId
        self.verseStart = verseStart
        self.verseEnd = verseEnd
        self.surahName = surahName
        self.text = initialText
    }

    convenience init(challenge: Challenge) {
        let name = ChapterNames.englishName(for: challenge.surahId) ?? challenge.surahName
        let range = challenge.verseStart == challenge.verseEnd
            ? "\(name) \(challenge.verseStart)"
            : "\(name) \(challenge.verseStart)\u{2013}\(challenge.verseEnd)"

        self.init(
            chapterId: challenge.surahId,
            verseStart: challenge.verseStart,
            verseEnd: challenge.verseEnd,
            surahName: name,
            initialText: "Alhamdulillah, I\u{2019}ve finished memorising \(range), and these ayahs are now part of my salah."
        )
    }

    // MARK: - Derived state

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var characterCount: Int { trimmedText.count }

    var canSubmit: Bool {
        characterCount >= Self.minimumBodyLength && !isSubmitting
    }

    var referenceLabel: String {
        verseStart == verseEnd
            ? "\(surahName) \(verseStart)"
            : "\(surahName) \(verseStart)\u{2013}\(verseEnd)"
    }

    var arabicSurahName: String? {
        ChapterNames.arabicName(for: chapterId)
    }

    // MARK: - Submit

    func submit(auth: AuthManager) async {
        guard canSubmit else { return }

        isSubmitting = true
        errorMessage = nil

        do {
            try await ReflectionsAPI.createPost(
                auth: auth,
                body: trimmedText,
                references: [
                    .init(chapterId: chapterId, from: verseStart, to: verseEnd)
                ],
                tags: tags,
                draft: isDraft
            )
            didPublish = true
        } catch {
            errorMessage = message(for: error)
        }

        isSubmitting = false
    }

    private func message(for error: Error) -> String {
        switch error {
        case APIError.unauthorized:
            return "Your account isn\u{2019}t authorised to post reflections yet. Sign out and back in to grant access."
        case APIError.httpError(let status, _) where status == 401 || status == 403:
            return "Your account isn\u{2019}t authorised to post reflections yet. Sign out and back in to grant access."
        case APIError.httpError(let status, _) where status == 422 || status == 400:
            return "That reflection couldn\u{2019}t be posted. Try rewording it."
        default:
            return "Couldn\u{2019}t share your reflection. Check your connection and try again."
        }
    }
}
