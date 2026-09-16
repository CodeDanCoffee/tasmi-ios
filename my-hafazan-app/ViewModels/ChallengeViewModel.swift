import Foundation
import SwiftData
import SwiftUI

struct GapBlank {
    let localWordIndex: Int  // word index within a single verse
    let correctWord: String
    let translationText: String?
}

struct AyahGapData {
    let verseIndex: Int
    let verse: CachedVerse
    let blanks: [GapBlank]
    let bankWords: [String]  // shuffled correct answers for this ayah
    let bankTranslations: [String?]  // translations matching bankWords order
}

enum DropInPhase {
    case cue, recite, review
}

@Observable
class ChallengeViewModel {
    var challenge: Challenge
    var audioService = AudioService()
    var isTransitioning = false
    var stageCompleted = false
    var currentActivity = 1

    /// The stage number this view is displaying (1-based)
    let displayStage: Int

    /// Whether we're reviewing a past stage (not advancing progress)
    var isReviewMode: Bool {
        displayStage < challenge.currentStage || challenge.isCompleted
    }

    // Stage-specific state
    var continueFromMemoryPhase = false
    var continueFromVerificationPhase = false
    var continueFromStumblePhase = false
    var continueFromNotePhase = false
    var stumbledVerses: Set<Int> = []
    var continueFromNote = ""
    var isPeeking = false
    var revealedWords: Set<Int> = []
    var writeAttempt = ""
    var writeScore: Double = 0
    var hasAssessedSelf = false
    var reciteTimerSeconds = 0
    var isTimerRunning = false

    // Stage 6 - Chain challenge
    var chainCurrentRound: Int = 0  // 0 = not started

    var chainTotalRounds: Int { verses.count }

    var chainStarted: Bool { chainCurrentRound > 0 }

    var chainActiveRound: Int { max(chainCurrentRound, 1) }

    // Stage 3 - Recite in order
    var currentReciteIndex: Int = -1
    var showFirstWords = false

    // Stage 4 - Transition drill
    var currentTransitionIndex: Int = 0
    var isTransitionRevealed: Bool = false

    // Stage 4 - First-word cascade
    var cascadeRevealedAyahs: Set<Int> = []
    var cascadeVerifiedAyahs: Set<Int> = []
    var cascadeStumbledAyahs: Set<Int> = []

    // Translation match state (Activity 2)
    var chapterTranslations: [TranslationText] = []
    var isLoadingTranslations = false
    var translationError: String?
    var shuffledTranslationOrder: [Int] = []
    var selectedTranslationIndex: Int?
    var matchedPairs: Set<String> = []
    var wrongMatchVerseKey: String?

    // Gap fill state
    var ayahGaps: [AyahGapData] = []
    var currentGapAyahIndex: Int = 0
    var gapAnswers: [Int: Int] = [:] // blankIndex -> bankWordIndex
    var selectedGapIndex: Int?
    var gapFillChecked = false

    var currentAyahGap: AyahGapData? {
        guard currentGapAyahIndex < ayahGaps.count else { return nil }
        return ayahGaps[currentGapAyahIndex]
    }

    var gapBlanks: [GapBlank] {
        currentAyahGap?.blanks ?? []
    }

    var gapBankWords: [String] {
        currentAyahGap?.bankWords ?? []
    }

    var gapBankTranslations: [String?] {
        currentAyahGap?.bankTranslations ?? []
    }

    var isLastGapAyah: Bool {
        currentGapAyahIndex >= ayahGaps.count - 1
    }

    var gapAyahProgress: String {
        "Ayah \(currentGapAyahIndex + 1) of \(ayahGaps.count)"
    }

    private var timer: Timer?

    var currentStageType: StageType {
        let stages = StageDefinitions.stages(for: challenge.templateType)
        let index = min(displayStage - 1, stages.count - 1)
        return stages[max(0, index)]
    }

    var totalStages: Int {
        StageDefinitions.stageCount(for: challenge.templateType)
    }

    var totalActivities: Int {
        switch currentStageType {
        case .listenWithText: return 3
        case .listenOnly: return 2
        case .readFromMemory: return 2
        case .write: return 2
        default: return 1
        }
    }

    var verses: [CachedVerse] {
        challenge.cachedVerseList
    }

    var fullText: String {
        verses.map { $0.textUthmani.cleanArabic }.joined(separator: " ")
    }

    var allWords: [CachedWord] {
        verses.flatMap { $0.words.filter { $0.charTypeName == "word" } }
    }

    init(challenge: Challenge, stageNumber: Int? = nil) {
        self.challenge = challenge
        self.displayStage = stageNumber ?? challenge.currentStage
    }

    func loadAudio() async {
        guard currentStageType.hasAudio else { return }

        do {
            let audioFile = try await QuranAPI.fetchChapterAudio(
                reciterId: challenge.reciterId,
                chapterId: challenge.surahId
            )

            if let url = audioFile.audioUrl {
                audioService.loadAudio(
                    url: url,
                    timings: audioFile.timestamps ?? [],
                    verseStart: challenge.verseStart,
                    verseEnd: challenge.verseEnd,
                    chapterId: challenge.surahId
                )
            }
        } catch {
            // Audio loading failed. User can still proceed
        }
    }

    func advanceStage() {
        isTransitioning = true
        resetStageState()

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        if !isReviewMode {
            if challenge.currentStage >= totalStages {
                challenge.status = "completed"
                challenge.completedAt = Date()
            } else {
                challenge.currentStage += 1
                var progress = challenge.stageProgress
                progress[challenge.currentStage - 1] = true
                challenge.stageProgress = progress
            }
        }

        stageCompleted = true
        isTransitioning = false
    }

    func resetStageState() {
        audioService.stop()
        continueFromMemoryPhase = false
        continueFromVerificationPhase = false
        continueFromStumblePhase = false
        continueFromNotePhase = false
        stumbledVerses = []
        continueFromNote = ""
        isPeeking = false
        revealedWords = []
        writeAttempt = ""
        writeScore = 0
        hasAssessedSelf = false
        currentReciteIndex = 0
        showFirstWords = false
        stopTimer()
        // Translation match
        selectedTranslationIndex = nil
        matchedPairs = []
        wrongMatchVerseKey = nil
        // Transition drill & cascade
        currentTransitionIndex = 0
        isTransitionRevealed = false
        cascadeRevealedAyahs = []
        cascadeVerifiedAyahs = []
        cascadeStumbledAyahs = []
        // Gap fill
        ayahGaps = []
        currentGapAyahIndex = 0
        gapAnswers = [:]
        selectedGapIndex = nil
        gapFillChecked = false
        // Chain challenge
        chainCurrentRound = 0
        // Random drop-in
        dropInAttempts = 0
        dropInPhase = .cue
        dropInAyahIndices = []
        dropInSelfAssessment = nil
    }

    // Peek functionality (Stage 2)
    func togglePeek() {
        isPeeking.toggle()
        if isPeeking {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.isPeeking = false
            }
        }
    }

    // Word reveal (Stage 3)
    func revealWord(at index: Int) {
        revealedWords.insert(index)
    }

    var allWordsRevealed: Bool {
        revealedWords.count >= allWords.count
    }

    // Recite in order (Stage 3)
    func showNextReciteAyah() {
        guard currentReciteIndex < verses.count - 1 else { return }
        currentReciteIndex += 1
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    var canShowNextAyah: Bool {
        currentReciteIndex < verses.count - 1
    }

    func redoReciteStage() {
        currentReciteIndex = -1
        showFirstWords = false
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    func loadAndPlayAudio() async {
        do {
            let audioFile = try await QuranAPI.fetchChapterAudio(
                reciterId: challenge.reciterId,
                chapterId: challenge.surahId
            )
            if let url = audioFile.audioUrl {
                audioService.loadAudio(
                    url: url,
                    timings: audioFile.timestamps ?? [],
                    verseStart: challenge.verseStart,
                    verseEnd: challenge.verseEnd,
                    chapterId: challenge.surahId
                )
                audioService.startSequential(passes: 1)
            }
        } catch {
            // Audio loading failed silently
        }
    }

    func loadAndPlayAudioSoftly() async {
        do {
            let audioFile = try await QuranAPI.fetchChapterAudio(
                reciterId: challenge.reciterId,
                chapterId: challenge.surahId
            )
            if let url = audioFile.audioUrl {
                audioService.loadAudio(
                    url: url,
                    timings: audioFile.timestamps ?? [],
                    verseStart: challenge.verseStart,
                    verseEnd: challenge.verseEnd,
                    chapterId: challenge.surahId
                )
                audioService.setVolume(0.35)
                audioService.startSequential(passes: 1)
            }
        } catch {
            // Audio loading failed silently
        }
    }

    // Continue from here (Stage 5, Activity 1)
    var continueFromAyahCount: Int {
        max(1, verses.count - 2)
    }

    var continueFromPrompt: String {
        let firstRemaining = challenge.verseStart + continueFromAyahCount
        let last = challenge.verseEnd
        if firstRemaining == last {
            return "The audio has paused. Continue aloud \u{2014} ayah \(firstRemaining)."
        } else {
            return "The audio has paused. Continue aloud \u{2014} ayahs \(firstRemaining) and \(last)."
        }
    }

    func isVerseInAudioRange(_ verse: CachedVerse) -> Bool {
        verse.verseNumber < challenge.verseStart + continueFromAyahCount
    }

    func retryContinueFrom() {
        continueFromMemoryPhase = false
        continueFromVerificationPhase = false
        continueFromStumblePhase = false
        continueFromNotePhase = false
        stumbledVerses = []
        continueFromNote = ""
        audioService.resetForNextActivity()
    }

    func toggleStumbledVerse(_ verseNumber: Int) {
        if stumbledVerses.contains(verseNumber) {
            stumbledVerses.remove(verseNumber)
        } else {
            stumbledVerses.insert(verseNumber)
        }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    func startContinueFromAudio() async {
        do {
            let audioFile = try await QuranAPI.fetchChapterAudio(
                reciterId: challenge.reciterId,
                chapterId: challenge.surahId
            )
            if let url = audioFile.audioUrl {
                audioService.loadAudio(
                    url: url,
                    timings: audioFile.timestamps ?? [],
                    verseStart: challenge.verseStart,
                    verseEnd: challenge.verseEnd,
                    chapterId: challenge.surahId
                )
                audioService.sequentialVerseLimit = continueFromAyahCount
                audioService.startSequential(passes: 1)
            }
        } catch {
            // Audio loading failed silently
        }
    }

    // Random drop-in (Stage 5, Activity 2)
    var dropInAttempts: Int = 0
    var dropInPhase: DropInPhase = .cue
    var dropInAyahIndices: [Int] = []
    let dropInMaxAttempts: Int = 2
    var dropInSelfAssessment: String? = nil

    var currentDropInAyahIndex: Int {
        guard dropInAttempts < dropInAyahIndices.count else { return min(1, verses.count - 1) }
        return dropInAyahIndices[dropInAttempts]
    }

    var currentDropInAyah: CachedVerse? {
        guard currentDropInAyahIndex < verses.count else { return nil }
        return verses[currentDropInAyahIndex]
    }

    var dropInCueAyahIndex: Int {
        max(0, currentDropInAyahIndex - 1)
    }

    var currentDropInVerseNumber: Int {
        challenge.verseStart + currentDropInAyahIndex
    }

    var dropInCueVerseNumber: Int {
        challenge.verseStart + dropInCueAyahIndex
    }

    var dropInCueText: String {
        guard let ayah = currentDropInAyah else { return "" }
        let words = ayah.words.filter { $0.charTypeName == "word" }
        let firstWords = words.prefix(3).map { $0.textUthmani.cleanArabic }.joined(separator: " ")
        return firstWords + " ..."
    }

    var isDropInComplete: Bool {
        dropInAttempts >= dropInMaxAttempts
    }

    func setupRandomDropIn() {
        var possibleIndices = Array(1..<verses.count)
        if possibleIndices.isEmpty {
            possibleIndices = [0]
        }

        var indices: [Int] = []
        var shuffled = possibleIndices.shuffled()
        while indices.count < dropInMaxAttempts {
            if shuffled.isEmpty {
                shuffled = possibleIndices.shuffled()
            }
            indices.append(shuffled.removeFirst())
        }

        dropInAyahIndices = indices
        dropInAttempts = 0
        dropInPhase = .cue
        dropInSelfAssessment = nil
    }

    func startDropInCueAudio() async {
        audioService.resetForNextActivity()

        let cueVerseNumber = dropInCueVerseNumber

        do {
            let audioFile = try await QuranAPI.fetchChapterAudio(
                reciterId: challenge.reciterId,
                chapterId: challenge.surahId
            )
            if let url = audioFile.audioUrl {
                audioService.loadAudio(
                    url: url,
                    timings: audioFile.timestamps ?? [],
                    verseStart: cueVerseNumber,
                    verseEnd: cueVerseNumber,
                    chapterId: challenge.surahId
                )
                audioService.startSequential(passes: 1)
            }
        } catch {
            // Audio loading failed silently
        }
    }

    func advanceDropInAttempt() {
        dropInAttempts += 1
        dropInPhase = .cue
        dropInSelfAssessment = nil
        audioService.resetForNextActivity()
    }

    // Write scoring (Stage 5)
    func scoreWriteAttempt() {
        writeScore = ArabicTextUtils.compare(writeAttempt, fullText)
    }

    // Chain challenge (Stage 6)
    func beginChain() {
        chainCurrentRound = 2
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    func advanceChainRound() {
        chainCurrentRound += 1
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    var isChainComplete: Bool {
        chainCurrentRound > chainTotalRounds
    }

    var lastCompletedRound: Int {
        chainCurrentRound - 1
    }

    // Timer (Stage 6)
    func startTimer() {
        reciteTimerSeconds = 0
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.reciteTimerSeconds += 1
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }

    // Translation match (Activity 2)
    var allTranslationsMatched: Bool {
        matchedPairs.count >= verses.count
    }

    func loadTranslations() async {
        guard chapterTranslations.isEmpty, !isLoadingTranslations else { return }
        isLoadingTranslations = true
        translationError = nil

        do {
            let allTranslations = try await QuranAPI.fetchTranslations(
                chapterId: challenge.surahId,
                translationId: challenge.translationId
            )
            // Extract only the verses in our range (index = verseNumber - 1)
            let startIndex = challenge.verseStart - 1
            let endIndex = challenge.verseEnd - 1
            guard startIndex >= 0, endIndex < allTranslations.count else {
                translationError = "Translations not available for these verses"
                isLoadingTranslations = false
                return
            }
            chapterTranslations = Array(allTranslations[startIndex...endIndex])
            // Create shuffled order (indices into chapterTranslations)
            shuffledTranslationOrder = Array(0..<chapterTranslations.count).shuffled()
        } catch {
            translationError = "Failed to load translations"
        }

        isLoadingTranslations = false
    }

    func translationText(for verseNumber: Int) -> String {
        let index = verseNumber - challenge.verseStart
        guard index >= 0, index < chapterTranslations.count else { return "" }
        return chapterTranslations[index].text.strippingHTML()
    }

    func checkTranslationMatch(translationDisplayIndex: Int, verseKey: String) {
        guard let translationIndex = shuffledTranslationOrder[safe: translationDisplayIndex] else { return }
        // The translation at translationIndex corresponds to verse at that offset
        let expectedVerseNumber = challenge.verseStart + translationIndex
        let expectedKey = "\(challenge.surahId):\(expectedVerseNumber)"

        if verseKey == expectedKey {
            matchedPairs.insert(verseKey)
            selectedTranslationIndex = nil
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } else {
            wrongMatchVerseKey = verseKey
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                if self?.wrongMatchVerseKey == verseKey {
                    self?.wrongMatchVerseKey = nil
                }
            }
        }
    }

    // Gap fill
    func setupGapFill() {
        var gaps: [AyahGapData] = []

        for (verseIndex, verse) in verses.enumerated() {
            let contentWords = verse.words.filter { $0.charTypeName == "word" }
            let wordCount = contentWords.count

            // Skip verses too short for 2 blanks
            guard wordCount >= 4 else { continue }

            // At least 2 blanks; scale up by ~1 per 5 words
            let blankCount = max(2, wordCount / 5)
            let interval = wordCount / blankCount

            var blanks: [GapBlank] = []
            for b in 0..<blankCount {
                let idx = (b + 1) * interval - 1
                guard idx < wordCount else { break }
                blanks.append(GapBlank(
                    localWordIndex: idx,
                    correctWord: contentWords[idx].textUthmani.cleanArabic,
                    translationText: contentWords[idx].translation
                ))
            }

            let bank = blanks.map { ($0.correctWord, $0.translationText) }.shuffled()
            gaps.append(AyahGapData(
                verseIndex: verseIndex,
                verse: verse,
                blanks: blanks,
                bankWords: bank.map(\.0),
                bankTranslations: bank.map(\.1)
            ))
        }

        ayahGaps = gaps
        currentGapAyahIndex = 0
        resetGapAyahState()
    }

    func setupGapFillHarder() {
        var gaps: [AyahGapData] = []

        for (verseIndex, verse) in verses.enumerated() {
            let contentWords = verse.words.filter { $0.charTypeName == "word" }
            let wordCount = contentWords.count

            guard wordCount >= 3 else { continue }

            // Every 3rd word is blank
            var blanks: [GapBlank] = []
            for idx in stride(from: 2, to: wordCount, by: 3) {
                blanks.append(GapBlank(
                    localWordIndex: idx,
                    correctWord: contentWords[idx].textUthmani.cleanArabic,
                    translationText: contentWords[idx].translation
                ))
            }

            let bank = blanks.map { ($0.correctWord, $0.translationText) }.shuffled()
            gaps.append(AyahGapData(
                verseIndex: verseIndex,
                verse: verse,
                blanks: blanks,
                bankWords: bank.map(\.0),
                bankTranslations: bank.map(\.1)
            ))
        }

        ayahGaps = gaps
        currentGapAyahIndex = 0
        resetGapAyahState()
    }

    func resetGapAyahState() {
        gapAnswers = [:]
        selectedGapIndex = nil
        gapFillChecked = false
    }

    func advanceGapAyah() {
        currentGapAyahIndex += 1
        resetGapAyahState()
    }

    func tapGapBlank(at blankIndex: Int) {
        guard !gapFillChecked else { return }
        if gapAnswers[blankIndex] != nil {
            gapAnswers.removeValue(forKey: blankIndex)
            selectedGapIndex = nil
        } else {
            selectedGapIndex = blankIndex
        }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    /// Callback set by the view to handle auto-finishing the last ayah
    var onLastAyahCompleted: (() -> Void)?

    func tapBankWord(at bankIndex: Int) {
        guard !gapFillChecked else { return }
        guard !gapAnswers.values.contains(bankIndex) else { return }

        if let selected = selectedGapIndex {
            gapAnswers[selected] = bankIndex
            selectedGapIndex = nil
        } else {
            // Fill first empty blank
            for i in 0..<gapBlanks.count {
                if gapAnswers[i] == nil {
                    gapAnswers[i] = bankIndex
                    break
                }
            }
        }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Auto-check when all blanks are filled
        if allGapsFilled {
            gapFillChecked = true
            if allGapsCorrect {
                // All correct — auto-advance after a brief delay
                let successImpact = UIImpactFeedbackGenerator(style: .medium)
                successImpact.impactOccurred()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                    guard let self else { return }
                    if self.isLastGapAyah {
                        self.onLastAyahCompleted?()
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            self.advanceGapAyah()
                        }
                    }
                }
            } else {
                // Some wrong — show mistakes
                let errorImpact = UINotificationFeedbackGenerator()
                errorImpact.notificationOccurred(.error)
            }
        }
    }

    var allGapsFilled: Bool {
        gapAnswers.count >= gapBlanks.count
    }

    func checkGapFill() {
        gapFillChecked = true
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    var allGapsCorrect: Bool {
        guard gapFillChecked else { return false }
        return (0..<gapBlanks.count).allSatisfy { isGapCorrect(at: $0) == true }
    }

    func retryGapAyah() {
        resetGapAyahState()
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    func isGapCorrect(at blankIndex: Int) -> Bool? {
        guard gapFillChecked else { return nil }
        guard let bankIndex = gapAnswers[blankIndex] else { return false }
        return gapBankWords[bankIndex] == gapBlanks[blankIndex].correctWord
    }

    // Transition drill (Stage 4, Activity 1)
    var totalTransitions: Int {
        max(verses.count - 1, 0)
    }

    var transitionLastWords: String {
        guard currentTransitionIndex < verses.count else { return "" }
        let words = verses[currentTransitionIndex].words.filter { $0.charTypeName == "word" }
        let count = min(3, words.count)
        return words.suffix(count).map { $0.textUthmani.cleanArabic }.joined(separator: " ")
    }

    var transitionFirstWord: String {
        let nextIndex = currentTransitionIndex + 1
        guard nextIndex < verses.count else { return "" }
        let words = verses[nextIndex].words.filter { $0.charTypeName == "word" }
        return (words.first?.textUthmani ?? "").cleanArabic
    }

    var isLastTransition: Bool {
        currentTransitionIndex >= totalTransitions - 1
    }

    func revealTransition() {
        isTransitionRevealed = true
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    func advanceTransition() {
        guard !isLastTransition else { return }
        currentTransitionIndex += 1
        isTransitionRevealed = false
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    // First-word cascade (Stage 4, Activity 2)
    var cascadeVerifiedCount: Int {
        cascadeVerifiedAyahs.count
    }

    var allCascadeVerified: Bool {
        (cascadeVerifiedAyahs.count + cascadeStumbledAyahs.count) >= verses.count
    }

    func revealCascadeAyah(at index: Int) {
        cascadeRevealedAyahs.insert(index)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    func hideCascadeAyah(at index: Int) {
        cascadeRevealedAyahs.remove(index)
    }

    func verifyCascadeAyah(at index: Int) {
        cascadeVerifiedAyahs.insert(index)
        cascadeStumbledAyahs.remove(index)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    func stumbleCascadeAyah(at index: Int) {
        cascadeStumbledAyahs.insert(index)
        cascadeVerifiedAyahs.remove(index)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    // Prayer count (Stage 7)
    static let prayerNames = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]

    func syncPrayerCount() {
        let count = challenge.prayerEntries.count
        if challenge.prayerCount != count {
            challenge.prayerCount = count
        }
    }

    func addPrayerEntry(name: String, date: Date) {
        var entries = challenge.prayerEntries
        guard entries.count < 3 else { return }
        entries.append(PrayerEntry(name: name, date: date))
        challenge.prayerEntries = entries
        challenge.prayerCount = entries.count
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    func updatePrayerEntry(at index: Int, name: String, date: Date) {
        var entries = challenge.prayerEntries
        guard index >= 0 && index < entries.count else { return }
        entries[index] = PrayerEntry(name: name, date: date)
        challenge.prayerEntries = entries
    }

    var canCompletePrayerStage: Bool {
        challenge.prayerCount >= 3
    }

    func formattedPrayerTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct PrayerEntry: Identifiable, Equatable, Codable {
    var id = UUID()
    var name: String
    var date: Date
}
