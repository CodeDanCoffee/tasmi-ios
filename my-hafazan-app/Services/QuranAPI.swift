import Foundation

enum QuranAPI {
    private static let baseURL = "https://api.quran.com/api/v4"

    static func fetchChapters() async throws -> [Chapter] {
        let response = try await APIClient.shared.get(
            url: "\(baseURL)/chapters",
            queryItems: [URLQueryItem(name: "language", value: "en")],
            type: ChaptersResponse.self
        )
        return response.chapters
    }

    static func fetchVerses(
        chapterId: Int,
        page: Int = 1,
        perPage: Int = 50,
        languageCode: String = "en"
    ) async throws -> VersesResponse {
        try await APIClient.shared.get(
            url: "\(baseURL)/verses/by_chapter/\(chapterId)",
            queryItems: [
                URLQueryItem(name: "language", value: languageCode),
                URLQueryItem(name: "words", value: "true"),
                URLQueryItem(name: "fields", value: "text_uthmani"),
                URLQueryItem(name: "word_fields", value: "text_uthmani,translation"),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "per_page", value: "\(perPage)")
            ],
            type: VersesResponse.self
        )
    }

    static func fetchAllVerses(chapterId: Int, languageCode: String = "en") async throws -> [Verse] {
        var allVerses: [Verse] = []
        var page = 1

        while true {
            let response = try await fetchVerses(
                chapterId: chapterId,
                page: page,
                languageCode: languageCode
            )
            allVerses.append(contentsOf: response.verses)

            if response.pagination?.nextPage == nil {
                break
            }
            page += 1
        }

        return allVerses
    }

    static func fetchReciters() async throws -> [Reciter] {
        let response = try await APIClient.shared.get(
            url: "\(baseURL)/resources/recitations",
            queryItems: [URLQueryItem(name: "language", value: "en")],
            type: RecitersResponse.self
        )
        return response.recitations
    }

    static func fetchAudioFiles(reciterId: Int, chapterId: Int) async throws -> [AudioFile] {
        let response = try await APIClient.shared.get(
            url: "\(baseURL)/recitations/\(reciterId)/by_chapter/\(chapterId)",
            queryItems: [URLQueryItem(name: "fields", value: "segments")],
            type: AudioFilesResponse.self
        )
        return response.audioFiles
    }

    static func fetchChapterAudio(reciterId: Int, chapterId: Int) async throws -> ChapterAudioFile {
        let response = try await APIClient.shared.get(
            url: "\(baseURL)/chapter_recitations/\(reciterId)/\(chapterId)",
            queryItems: [URLQueryItem(name: "segments", value: "true")],
            type: ChapterRecitationResponse.self
        )
        return response.audioFile
    }

    static func fetchTranslations(chapterId: Int, translationId: Int = 20) async throws -> [TranslationText] {
        let response = try await APIClient.shared.get(
            url: "\(baseURL)/quran/translations/\(translationId)",
            queryItems: [
                URLQueryItem(name: "chapter_number", value: "\(chapterId)")
            ],
            type: TranslationResponse.self
        )
        return response.translations
    }

    static func fetchTranslationsList() async throws -> [TranslationResource] {
        let response = try await APIClient.shared.get(
            url: "\(baseURL)/resources/translations",
            queryItems: [URLQueryItem(name: "language", value: "en")],
            type: TranslationsResourceResponse.self
        )
        return response.translations
    }
}
