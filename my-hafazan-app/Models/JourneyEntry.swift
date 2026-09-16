import Foundation
import SwiftData

@Model
class JourneyEntry {
    var id: UUID
    var type: String
    var challengeId: UUID?
    var surahName: String
    var detail: String
    var date: Date

    init(
        type: String,
        challengeId: UUID? = nil,
        surahName: String,
        detail: String
    ) {
        self.id = UUID()
        self.type = type
        self.challengeId = challengeId
        self.surahName = surahName
        self.detail = detail
        self.date = Date()
    }
}

enum JourneyEntryType {
    static let stageCompleted = "stage_completed"
    static let challengeCompleted = "challenge_completed"
    static let deckReview = "deck_review"
    static let challengeStarted = "challenge_started"
}
