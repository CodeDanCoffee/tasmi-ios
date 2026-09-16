import Foundation
import SwiftData

@Observable
class DeckViewModel {
    var cards: [DeckCard] = []
    var dueCards: [DeckCard] = []

    var cardsBySurah: [(surahName: String, cards: [DeckCard])] {
        let grouped = Dictionary(grouping: cards) { $0.surahName }
        return grouped.map { (surahName: $0.key, cards: $0.value) }
            .sorted { $0.surahName < $1.surahName }
    }

    var dueCount: Int {
        dueCards.count
    }

    func load(context: ModelContext) {
        let descriptor = FetchDescriptor<DeckCard>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        cards = (try? context.fetch(descriptor)) ?? []
        dueCards = cards.filter(\.isDueForReview)
    }

    func addCard(from challenge: Challenge, context: ModelContext) {
        let card = DeckCard(
            challengeId: challenge.id,
            surahId: challenge.surahId,
            surahName: challenge.surahName,
            surahNameArabic: challenge.surahNameArabic,
            verseStart: challenge.verseStart,
            verseEnd: challenge.verseEnd,
            versesData: challenge.cachedVerses
        )
        context.insert(card)
        cards.insert(card, at: 0)
        dueCards = cards.filter(\.isDueForReview)
    }

    func reviewCard(_ card: DeckCard, confidence: String, context: ModelContext) {
        card.updateAfterReview(newConfidence: confidence)
        dueCards = cards.filter(\.isDueForReview)

        // Record journey entry
        let entry = JourneyEntry(
            type: JourneyEntryType.deckReview,
            surahName: card.surahName,
            detail: "Reviewed \(card.verseRange). \(confidence)"
        )
        context.insert(entry)
    }
}
