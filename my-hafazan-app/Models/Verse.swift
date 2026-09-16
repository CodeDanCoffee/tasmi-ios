import Foundation

struct VersesResponse: Codable {
    let verses: [Verse]
    let pagination: Pagination?
}

struct Pagination: Codable {
    let perPage: Int
    let currentPage: Int
    let nextPage: Int?
    let totalPages: Int
    let totalRecords: Int
}

struct Verse: Codable, Identifiable, Hashable {
    let id: Int
    let verseNumber: Int
    let verseKey: String
    let hizbNumber: Int
    let rubElHizbNumber: Int
    let rukuNumber: Int
    let manzilNumber: Int
    let sajdahNumber: Int?
    let textUthmani: String?
    let pageNumber: Int
    let juzNumber: Int
    let words: [Word]?
}

struct Word: Codable, Identifiable, Hashable {
    let id: Int
    let position: Int
    let audioUrl: String?
    let charTypeName: String
    let textUthmani: String?
    let pageNumber: Int
    let lineNumber: Int
    let text: String?
    let translation: WordTranslation?
    let transliteration: WordTranslation?
}

struct WordTranslation: Codable, Hashable {
    let text: String?
    let languageName: String?
}

// MARK: - Translation API

struct TranslationResponse: Codable {
    let translations: [TranslationText]
}

struct TranslationText: Codable {
    let resourceId: Int
    let text: String
}
