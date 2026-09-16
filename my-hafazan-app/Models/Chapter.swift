import Foundation

struct ChaptersResponse: Codable {
    let chapters: [Chapter]
}

struct Chapter: Codable, Identifiable, Hashable {
    let id: Int
    let revelationPlace: String
    let revelationOrder: Int
    let bismillahPre: Bool
    let nameSimple: String
    let nameComplex: String
    let nameArabic: String
    let versesCount: Int
    let pages: [Int]
    let translatedName: TranslatedName

    struct TranslatedName: Codable, Hashable {
        let name: String
        let languageName: String
    }
}
