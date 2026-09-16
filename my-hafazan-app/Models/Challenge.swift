import Foundation
import SwiftData

@Model
class Challenge {
    var id: UUID
    var surahId: Int
    var surahName: String
    var surahNameArabic: String
    var verseStart: Int
    var verseEnd: Int
    var templateType: String
    var reciterId: Int
    var reciterName: String
    var translationId: Int = 20
    var translationName: String = "Saheeh International"
    var translationLanguageCode: String = "en"
    var translationLanguageName: String = "english"
    var status: String
    var currentStage: Int
    var stageProgressData: Data
    var prayerCount: Int
    var prayerEntriesData: Data = Data()
    var cachedVerses: Data
    var createdAt: Date
    var completedAt: Date?

    init(
        surahId: Int,
        surahName: String,
        surahNameArabic: String = "",
        verseStart: Int,
        verseEnd: Int,
        templateType: String = "standard",
        reciterId: Int,
        reciterName: String,
        translationId: Int = 20,
        translationName: String = "Saheeh International",
        translationLanguageCode: String = "en",
        translationLanguageName: String = "english"
    ) {
        self.id = UUID()
        self.surahId = surahId
        self.surahName = surahName
        self.surahNameArabic = surahNameArabic
        self.verseStart = verseStart
        self.verseEnd = verseEnd
        self.templateType = templateType
        self.reciterId = reciterId
        self.reciterName = reciterName
        self.translationId = translationId
        self.translationName = translationName
        self.translationLanguageCode = translationLanguageCode
        self.translationLanguageName = translationLanguageName
        self.status = "active"
        self.currentStage = 1
        self.stageProgressData = Data()
        self.prayerCount = 0
        self.prayerEntriesData = Data()
        self.cachedVerses = Data()
        self.createdAt = Date()
    }

    var verseCount: Int {
        verseEnd - verseStart + 1
    }

    var verseRange: String {
        if verseStart == verseEnd {
            return "Ayah \(verseStart)"
        }
        return "Ayah \(verseStart)-\(verseEnd)"
    }

    var stageProgress: [Int: Bool] {
        get {
            (try? JSONDecoder().decode([Int: Bool].self, from: stageProgressData)) ?? [:]
        }
        set {
            stageProgressData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var prayerEntries: [PrayerEntry] {
        get {
            (try? JSONDecoder().decode([PrayerEntry].self, from: prayerEntriesData)) ?? []
        }
        set {
            prayerEntriesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var cachedVerseList: [CachedVerse] {
        get {
            (try? JSONDecoder().decode([CachedVerse].self, from: cachedVerses)) ?? []
        }
        set {
            cachedVerses = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var isCompleted: Bool {
        status == "completed"
    }

    var progressFraction: Double {
        Double(currentStage - 1) / 7.0
    }
}

struct CachedVerse: Codable, Identifiable, Hashable {
    let id: Int
    let verseNumber: Int
    let verseKey: String
    let textUthmani: String
    let words: [CachedWord]
}

struct CachedWord: Codable, Hashable {
    let position: Int
    let textUthmani: String
    let charTypeName: String
    let translation: String?
}
