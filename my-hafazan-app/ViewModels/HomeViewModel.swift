import Foundation
import SwiftData

@Observable
class HomeViewModel {
    var activeChallenges: [Challenge] = []
    var completedChallenges: [Challenge] = []
    var deckCards: [DeckCard] = []
    var completedCount = 0
    var totalVersesMemorized = 0
    var currentStreak = 0
    var isLoading = false

    var totalDeckCardCount: Int {
        deckCards.reduce(0) { $0 + ($1.verseEnd - $1.verseStart + 1) * 3 }
    }

    /// Suggests the next verse range based on the most recent active challenge
    var suggestedNextRange: String? {
        guard let challenge = activeChallenges.first ?? completedChallenges.last else { return nil }
        let nextStart = challenge.verseEnd + 1
        let nextEnd = nextStart + challenge.verseCount - 1
        return "\(challenge.surahName) \(nextStart)\u{2013}\(nextEnd)"
    }

    func load(context: ModelContext) {
        let activeDescriptor = FetchDescriptor<Challenge>(
            predicate: #Predicate { $0.status == "active" },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        activeChallenges = (try? context.fetch(activeDescriptor)) ?? []

        let completedDescriptor = FetchDescriptor<Challenge>(
            predicate: #Predicate { $0.status == "completed" },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        completedChallenges = (try? context.fetch(completedDescriptor)) ?? []
        completedCount = completedChallenges.count
        totalVersesMemorized = completedChallenges.reduce(0) { $0 + ($1.verseEnd - $1.verseStart + 1) }

        let deckDescriptor = FetchDescriptor<DeckCard>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        deckCards = (try? context.fetch(deckDescriptor)) ?? []

        // Calculate streak from journey entries
        let entryDescriptor = FetchDescriptor<JourneyEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let entries = (try? context.fetch(entryDescriptor)) ?? []
        currentStreak = calculateStreak(from: entries)
    }

    func relativeDateString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let days = Int(interval / 86400)
        if days == 0 { return "today" }
        if days == 1 { return "yesterday" }
        if days < 7 { return "\(days) days ago" }
        let weeks = days / 7
        if weeks == 1 { return "1 week ago" }
        if weeks < 5 { return "\(weeks) weeks ago" }
        let months = days / 30
        if months == 1 { return "1 month ago" }
        return "\(months) months ago"
    }

    private func calculateStreak(from entries: [JourneyEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streakDays = Set<Date>()

        for entry in entries {
            streakDays.insert(calendar.startOfDay(for: entry.date))
        }

        var streak = 0
        var checkDate = today

        while streakDays.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return streak
    }
}
