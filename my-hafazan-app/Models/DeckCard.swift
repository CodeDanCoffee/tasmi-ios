import Foundation
import SwiftData

@Model
class DeckCard {
    var id: UUID
    var challengeId: UUID
    var surahId: Int
    var surahName: String
    var surahNameArabic: String
    var verseStart: Int
    var verseEnd: Int
    var versesData: Data
    var confidence: String
    var nextReviewDate: Date
    var reviewCount: Int
    var lastReviewedAt: Date?
    var createdAt: Date

    init(
        challengeId: UUID,
        surahId: Int,
        surahName: String,
        surahNameArabic: String = "",
        verseStart: Int,
        verseEnd: Int,
        versesData: Data = Data()
    ) {
        self.id = UUID()
        self.challengeId = challengeId
        self.surahId = surahId
        self.surahName = surahName
        self.surahNameArabic = surahNameArabic
        self.verseStart = verseStart
        self.verseEnd = verseEnd
        self.versesData = versesData
        self.confidence = "weak"
        self.nextReviewDate = Date()
        self.reviewCount = 0
        self.createdAt = Date()
    }

    var verseRange: String {
        if verseStart == verseEnd {
            return "Ayah \(verseStart)"
        }
        return "Ayah \(verseStart)-\(verseEnd)"
    }

    var isDueForReview: Bool {
        nextReviewDate <= Date()
    }

    var cachedVerses: [CachedVerse] {
        (try? JSONDecoder().decode([CachedVerse].self, from: versesData)) ?? []
    }

    func updateAfterReview(newConfidence: String) {
        self.confidence = newConfidence
        self.reviewCount += 1
        self.lastReviewedAt = Date()

        let interval: TimeInterval
        switch newConfidence {
        case "easy":
            interval = 9 * 24 * 3600
        case "good":
            interval = 4 * 24 * 3600
        case "hard":
            interval = 1 * 24 * 3600
        case "forgot":
            interval = 10 * 60
        case "strong":
            interval = 7 * 24 * 3600
        case "moderate":
            interval = 3 * 24 * 3600
        default:
            interval = 1 * 24 * 3600
        }
        self.nextReviewDate = Date().addingTimeInterval(interval)
    }
}
