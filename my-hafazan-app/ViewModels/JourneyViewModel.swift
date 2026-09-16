import Foundation
import SwiftData

struct SurahProgress: Identifiable {
    let id: Int // surahId
    let surahName: String
    let surahNameArabic: String
    let totalAyahs: Int
    let memorizedAyahs: Int
    let memorizedRanges: [(start: Int, end: Int)]
    let challengeCount: Int

    var isComplete: Bool {
        memorizedAyahs >= totalAyahs
    }
}

@Observable
class JourneyViewModel {
    var entries: [JourneyEntry] = []
    var surahProgresses: [SurahProgress] = []
    var currentStreak = 0
    var longestStreak = 0
    var totalChallenges = 0
    var totalVerses = 0
    var activeDays: Set<Date> = []

    func load(context: ModelContext) {
        let entryDescriptor = FetchDescriptor<JourneyEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        entries = (try? context.fetch(entryDescriptor)) ?? []

        let calendar = Calendar.current
        activeDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        calculateStreaks()

        // Load all challenges (active + completed)
        let allDescriptor = FetchDescriptor<Challenge>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let allChallenges = (try? context.fetch(allDescriptor)) ?? []

        let completed = allChallenges.filter { $0.status == "completed" }
        totalChallenges = completed.count
        totalVerses = completed.reduce(0) { $0 + ($1.verseEnd - $1.verseStart + 1) }

        buildSurahProgresses(from: allChallenges)
    }

    private func buildSurahProgresses(from challenges: [Challenge]) {
        let grouped = Dictionary(grouping: challenges) { $0.surahId }

        surahProgresses = grouped.map { surahId, challenges in
            let first = challenges[0]
            let completedChallenges = challenges.filter { $0.status == "completed" }

            // Build memorized ranges from completed challenges
            var ranges: [(start: Int, end: Int)] = []
            for c in completedChallenges {
                ranges.append((start: c.verseStart, end: c.verseEnd))
            }
            ranges.sort { $0.start < $1.start }

            // Count unique memorized ayahs
            var memorizedSet = Set<Int>()
            for r in ranges {
                for v in r.start...r.end {
                    memorizedSet.insert(v)
                }
            }

            let totalAyahs = Self.totalAyahCount(for: surahId, fallback: challenges)

            return SurahProgress(
                id: surahId,
                surahName: first.surahName,
                surahNameArabic: first.surahNameArabic,
                totalAyahs: totalAyahs,
                memorizedAyahs: memorizedSet.count,
                memorizedRanges: ranges,
                challengeCount: challenges.count
            )
        }
        .sorted { a, b in
            // In-progress first, then completed
            if a.isComplete != b.isComplete { return !a.isComplete }
            return a.id < b.id
        }
    }

    private static func totalAyahCount(for surahId: Int, fallback challenges: [Challenge]) -> Int {
        let known: [Int: Int] = [
            1: 7, 2: 286, 3: 200, 4: 176, 5: 120, 6: 165, 7: 206,
            18: 110, 36: 83, 55: 78, 56: 96, 67: 30, 78: 40,
            112: 4, 113: 5, 114: 6
        ]
        if let count = known[surahId] { return count }
        return challenges.map(\.verseEnd).max() ?? 1
    }

    private func calculateStreaks() {
        guard !activeDays.isEmpty else { return }

        let calendar = Calendar.current
        let sortedDays = activeDays.sorted(by: >)
        let today = calendar.startOfDay(for: Date())

        // Current streak
        var streak = 0
        var checkDate = today
        for day in sortedDays {
            if day == checkDate {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else if day < checkDate {
                break
            }
        }
        currentStreak = streak

        // Longest streak
        var longest = 0
        var current = 1
        let ascending = sortedDays.reversed()
        let daysArray = Array(ascending)

        for i in 1..<daysArray.count {
            let diff = calendar.dateComponents([.day], from: daysArray[i-1], to: daysArray[i]).day ?? 0
            if diff == 1 {
                current += 1
            } else {
                longest = max(longest, current)
                current = 1
            }
        }
        longestStreak = max(longest, current)
    }

    func recordStageCompletion(challenge: Challenge, stage: Int, context: ModelContext) {
        let entry = JourneyEntry(
            type: JourneyEntryType.stageCompleted,
            challengeId: challenge.id,
            surahName: challenge.surahName,
            detail: "Completed Stage \(stage) of \(challenge.verseRange)"
        )
        context.insert(entry)
        entries.insert(entry, at: 0)
        activeDays.insert(Calendar.current.startOfDay(for: Date()))
    }
}
