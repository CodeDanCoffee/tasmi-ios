import Foundation
import SwiftData
import AVFoundation

@Observable
class ChallengeWizardViewModel {
    // Step tracking
    var currentStep = 1
    let totalSteps = 6

    // Step 1: Surah selection
    var chapters: [Chapter] = []
    var selectedChapter: Chapter?
    var searchText = ""
    var isLoadingChapters = false

    // Step 2: Verse range
    var verses: [Verse] = []
    var verseStart = 1
    var verseEnd = 1
    var isLoadingVerses = false

    // Step 3: Template
    var selectedTemplate: MemorizationTemplate = MemorizationTemplate.all[0]

    // Step 4: Reciter
    var reciters: [Reciter] = []
    var selectedReciter: Reciter?
    var isLoadingReciters = false

    // Reciter preview playback
    var previewingReciterId: Int?
    var isLoadingPreview = false
    private var previewPlayer: AVPlayer?

    // Step 5: Translation
    var translations: [TranslationResource] = []
    var selectedTranslation: TranslationResource?
    var isLoadingTranslations = false
    var isRebuildingVerses = false

    // General
    var errorMessage: String?

    var filteredChapters: [Chapter] {
        if searchText.isEmpty { return chapters }
        return chapters.filter {
            $0.nameSimple.localizedCaseInsensitiveContains(searchText) ||
            $0.nameArabic.contains(searchText) ||
            $0.translatedName.name.localizedCaseInsensitiveContains(searchText) ||
            "\($0.id)".contains(searchText)
        }
    }

    var canProceedToStep2: Bool { selectedChapter != nil }
    var canProceedToStep3: Bool { verseStart >= 1 && verseEnd >= verseStart }
    var canProceedToStep4: Bool { true }
    var canProceedToStep5: Bool { selectedReciter != nil }
    var canProceedToStep6: Bool { selectedTranslation != nil }

    /// Languages in the loaded list, sorted with English first then alphabetical.
    /// Used by the wizard's language→translation drill-down.
    var availableLanguages: [String] {
        let names = Set(translations.map { $0.languageName.capitalized })
        return names.sorted { a, b in
            if a.lowercased() == "english" { return true }
            if b.lowercased() == "english" { return false }
            return a < b
        }
    }

    func translations(forLanguage language: String) -> [TranslationResource] {
        translations
            .filter { $0.languageName.caseInsensitiveCompare(language) == .orderedSame }
            .sorted { $0.name < $1.name }
    }

    func loadChapters() async {
        guard chapters.isEmpty else { return }
        isLoadingChapters = true
        errorMessage = nil

        do {
            chapters = try await QuranAPI.fetchChapters()
        } catch {
            errorMessage = "Failed to load surahs: \(error.localizedDescription)"
        }
        isLoadingChapters = false
    }

    func loadVerses() async {
        guard let chapter = selectedChapter else { return }
        isLoadingVerses = true
        errorMessage = nil

        do {
            verses = try await QuranAPI.fetchAllVerses(chapterId: chapter.id)
            verseStart = 1
            verseEnd = chapter.versesCount >= 10 ? 5 : chapter.versesCount
        } catch {
            errorMessage = "Failed to load verses: \(error.localizedDescription)"
        }
        isLoadingVerses = false
    }

    func loadTranslations() async {
        guard translations.isEmpty else { return }
        isLoadingTranslations = true
        errorMessage = nil

        do {
            translations = try await QuranAPI.fetchTranslationsList()
            if selectedTranslation == nil {
                // Default to Saheeh International (id 20) when present.
                selectedTranslation = translations.first(where: { $0.id == 20 })
            }
        } catch {
            errorMessage = "Failed to load translations: \(error.localizedDescription)"
        }
        isLoadingTranslations = false
    }

    func loadReciters() async {
        guard reciters.isEmpty else { return }
        isLoadingReciters = true
        errorMessage = nil

        do {
            reciters = try await QuranAPI.fetchReciters()
            // Default to Mishary Rashid Alafasy (id: 7) if available
            selectedReciter = reciters.first(where: { $0.id == 7 }) ?? reciters.first
        } catch {
            errorMessage = "Failed to load reciters: \(error.localizedDescription)"
        }
        isLoadingReciters = false
    }

    func nextStep() {
        if currentStep < totalSteps {
            currentStep += 1
        }
    }

    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }

    // MARK: - Reciter Preview

    func togglePreview(for reciter: Reciter) async {
        // If already previewing this reciter, stop
        if previewingReciterId == reciter.id {
            stopPreview()
            return
        }

        stopPreview()
        previewingReciterId = reciter.id
        isLoadingPreview = true

        do {
            let audio = try await QuranAPI.fetchChapterAudio(reciterId: reciter.id, chapterId: 1)
            // Check user didn't tap another reciter while loading
            guard previewingReciterId == reciter.id, let url = audio.audioUrl, let audioURL = URL(string: url) else {
                isLoadingPreview = false
                return
            }

            let item = AVPlayerItem(url: audioURL)
            previewPlayer = AVPlayer(playerItem: item)
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
            previewPlayer?.play()
            isLoadingPreview = false
        } catch {
            isLoadingPreview = false
            previewingReciterId = nil
        }
    }

    func stopPreview() {
        previewPlayer?.pause()
        previewPlayer = nil
        previewingReciterId = nil
        isLoadingPreview = false
    }

    func createChallenge(context: ModelContext) async -> Challenge? {
        guard let chapter = selectedChapter,
              let reciter = selectedReciter,
              let translation = selectedTranslation else { return nil }

        // The wizard's `verses` were initially fetched in English (step 2).
        // If the chosen translation is in a different language, re-fetch so
        // the cached word-by-word translation matches the picked language.
        let sourceVerses: [Verse]
        if translation.languageCode != "en" {
            isRebuildingVerses = true
            defer { isRebuildingVerses = false }
            do {
                sourceVerses = try await QuranAPI.fetchAllVerses(
                    chapterId: chapter.id,
                    languageCode: translation.languageCode
                )
            } catch {
                errorMessage = "Failed to load translations: \(error.localizedDescription)"
                return nil
            }
        } else {
            sourceVerses = verses
        }

        let challenge = Challenge(
            surahId: chapter.id,
            surahName: chapter.nameSimple,
            surahNameArabic: chapter.nameArabic,
            verseStart: verseStart,
            verseEnd: verseEnd,
            templateType: selectedTemplate.id,
            reciterId: reciter.id,
            reciterName: reciter.reciterName,
            translationId: translation.id,
            translationName: translation.name,
            translationLanguageCode: translation.languageCode,
            translationLanguageName: translation.languageName
        )

        let selectedVerses = sourceVerses.filter { v in
            v.verseNumber >= verseStart && v.verseNumber <= verseEnd
        }

        let cached = selectedVerses.map { verse in
            CachedVerse(
                id: verse.id,
                verseNumber: verse.verseNumber,
                verseKey: verse.verseKey,
                textUthmani: verse.textUthmani ?? "",
                words: (verse.words ?? []).map { word in
                    CachedWord(
                        position: word.position,
                        textUthmani: word.textUthmani ?? word.text ?? "",
                        charTypeName: word.charTypeName,
                        translation: word.translation?.text
                    )
                }
            )
        }
        challenge.cachedVerseList = cached

        context.insert(challenge)
        return challenge
    }
}
