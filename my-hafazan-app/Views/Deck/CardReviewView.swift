import SwiftUI
import SwiftData
import UIKit

struct CardReviewView: View {
    let cards: [DeckCard]
    var verse: CachedVerse? = nil
    /// Which card type indices to include: 0 = First word, 1 = Translation, 2 = Gap fill
    var includedTypes: [Int] = [0, 1, 2]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var isRevealed = false
    @State private var deckViewModel = DeckViewModel()
    @State private var audioService = AudioService()
    @State private var audioLoaded = false
    @State private var hiddenWordIndex: Int? = nil

    // MARK: - Review Steps

    private struct ReviewStep {
        let cardIndex: Int
        let verseIndex: Int
        let cardType: Int
    }

    /// Flat list of steps across all cards, verses, and included types.
    private var reviewSteps: [ReviewStep] {
        var steps: [ReviewStep] = []

        if let verse {
            // Single-verse mode: one card, one verse, cycle through included types
            let card = cards.first!
            let verseIdx = card.cachedVerses.firstIndex(where: { $0.id == verse.id }) ?? 0
            for type in includedTypes {
                steps.append(ReviewStep(cardIndex: 0, verseIndex: verseIdx, cardType: type))
            }
        } else {
            // Multi-card/multi-verse mode
            for (ci, card) in cards.enumerated() {
                let versesCount = max(card.cachedVerses.count, 1)
                for vi in 0..<versesCount {
                    for type in includedTypes {
                        steps.append(ReviewStep(cardIndex: ci, verseIndex: vi, cardType: type))
                    }
                }
            }
        }

        return steps
    }

    private var totalSteps: Int { reviewSteps.count }

    private var isComplete: Bool { currentStep >= totalSteps }

    private var currentCard: DeckCard? {
        guard currentStep < reviewSteps.count else { return nil }
        let ci = reviewSteps[currentStep].cardIndex
        guard ci < cards.count else { return nil }
        return cards[ci]
    }

    private func currentVerse(for card: DeckCard) -> CachedVerse? {
        guard currentStep < reviewSteps.count else { return nil }
        if let verse { return verse }
        let vi = reviewSteps[currentStep].verseIndex
        guard vi < card.cachedVerses.count else { return card.cachedVerses.first }
        return card.cachedVerses[vi]
    }

    private var activeType: Int {
        guard currentStep < reviewSteps.count else { return 0 }
        return reviewSteps[currentStep].cardType
    }

    var body: some View {
        ZStack {
            Color.hCreamBg.ignoresSafeArea()

            if !isComplete, let card = currentCard {
                VStack(spacing: 0) {
                    // Header
                    headerView(for: card)
                        .padding(.top, HSpacing.sm)
                        .padding(.horizontal, HSpacing.screenPadding)

                    // Progress bar
                    progressBar
                        .padding(.top, 10)
                        .padding(.horizontal, HSpacing.screenPadding)

                    // Card
                    reviewCard(for: card)
                        .padding(.top, 14)
                        .padding(.bottom, 14)
                        .padding(.horizontal, HSpacing.screenPadding)

                    // Bottom section
                    if isRevealed {
                        nextCardButton(for: card)
                            .padding(.horizontal, HSpacing.screenPadding)
                            .padding(.bottom, HSpacing.md)
                    }
                }
            } else {
                completionView
            }
        }
        .navigationBarHidden(true)
        .task(id: currentCard?.id) {
            await loadAudioForCurrentCard()
        }
        .onDisappear {
            audioService.stop()
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.hDarkText.opacity(0.08))
                    .frame(height: 5)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.hOliveGreen)
                    .frame(width: max(0, geo.size.width * CGFloat(currentStep + 1) / CGFloat(max(totalSteps, 1))), height: 5)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(height: 5)
    }

    // MARK: - Audio Loading

    private func loadAudioForCurrentCard() async {
        guard let card = currentCard else { return }
        audioService.stop()
        audioLoaded = false

        let challengeId = card.challengeId
        let descriptor = FetchDescriptor<Challenge>(predicate: #Predicate { $0.id == challengeId })
        let reciterId = (try? modelContext.fetch(descriptor).first?.reciterId) ?? 7

        do {
            let audioFile = try await QuranAPI.fetchChapterAudio(
                reciterId: reciterId,
                chapterId: card.surahId
            )
            if let url = audioFile.audioUrl {
                audioService.loadAudio(
                    url: url,
                    timings: audioFile.timestamps ?? [],
                    verseStart: card.verseStart,
                    verseEnd: card.verseEnd,
                    chapterId: card.surahId
                )
                audioLoaded = true
            }
        } catch {
            // Audio unavailable
        }
    }

    // MARK: - Header

    private func headerView(for card: DeckCard) -> some View {
        ZStack {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.hDarkText)
                }
                Spacer()
            }

            Text("Card \(currentStep + 1) of \(totalSteps)")
                .font(HFont.captionMedium)
                .foregroundStyle(Color.hSubtext)
        }
    }

    // MARK: - Card

    private let cardRadius: CGFloat = 24

    private func reviewCard(for card: DeckCard) -> some View {
        Group {
            if isRevealed {
                revealedSide(for: card)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 255/255, green: 253/255, blue: 248/255))
                    .clipShape(RoundedRectangle(cornerRadius: cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: cardRadius)
                            .stroke(Color.hOliveGreen.opacity(0.35), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                    .transition(.opacity)
            } else {
                questionSide(for: card)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 255/255, green: 253/255, blue: 248/255))
                    .clipShape(RoundedRectangle(cornerRadius: cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: cardRadius)
                            .stroke(Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.08), lineWidth: 1)
                    )
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Question Side (Front)

    private func questionSide(for card: DeckCard) -> some View {
        VStack(spacing: 0) {
            Spacer()

            let v = currentVerse(for: card)
            let ayahNum = v?.verseNumber ?? card.verseStart

            if activeType == 0 {
                // First word card
                Text("FIRST WORD \u{00B7} AYAH \(ayahNum)")
                    .font(HFont.generalSans(11, weight: .medium))
                    .foregroundStyle(Color(red: 168/255, green: 160/255, blue: 152/255))
                    .tracking(0.6)
                    .padding(.bottom, 18)

                if let firstWord = v?.words.first(where: { $0.charTypeName == "word" }) {
                    Text(firstWord.textUthmani.cleanArabic)
                        .font(HFont.amiriQuran(56))
                        .foregroundStyle(Color.hDarkText)
                        .tracking(2)
                }

                Text("Recite the full ayah aloud")
                    .font(.custom("PlayfairDisplayItalic-Regular", size: 13))
                    .foregroundStyle(Color(red: 122/255, green: 114/255, blue: 106/255))
                    .padding(.top, 28)

            } else if activeType == 1 {
                // Translation card — show Arabic, ask for meaning
                Text("TRANSLATION \u{00B7} AYAH \(ayahNum)")
                    .font(HFont.generalSans(11, weight: .medium))
                    .foregroundStyle(Color(red: 168/255, green: 160/255, blue: 152/255))
                    .tracking(0.6)
                    .padding(.bottom, 18)

                if let v {
                    verseTextView(for: v)
                        .frame(maxWidth: .infinity)
                }

                Text("What does this ayah mean?")
                    .font(.custom("PlayfairDisplayItalic-Regular", size: 13))
                    .foregroundStyle(Color(red: 122/255, green: 114/255, blue: 106/255))
                    .padding(.top, 28)

            } else {
                // Gap fill card — show Arabic with one word blanked out
                Text("GAP FILL \u{00B7} AYAH \(ayahNum)")
                    .font(HFont.generalSans(11, weight: .medium))
                    .foregroundStyle(Color(red: 168/255, green: 160/255, blue: 152/255))
                    .tracking(0.6)
                    .padding(.bottom, 18)

                if let v {
                    gapFillText(for: v)
                        .frame(maxWidth: .infinity)
                }

                Text("Say the missing word aloud")
                    .font(.custom("PlayfairDisplayItalic-Regular", size: 13))
                    .foregroundStyle(Color(red: 122/255, green: 114/255, blue: 106/255))
                    .padding(.top, 28)
            }

            Text("Tap to reveal")
                .font(HFont.generalSans(11))
                .foregroundStyle(Color(red: 168/255, green: 160/255, blue: 152/255))
                .tracking(0.4)
                .padding(.top, 40)

            Spacer()
        }
        .padding(28)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                isRevealed = true
            }
        }
    }

    // MARK: - Revealed Side (Back)

    private func revealedSide(for card: DeckCard) -> some View {
        VStack(spacing: HSpacing.lg) {
            Spacer()

            if let v = currentVerse(for: card) {
                Text("\(card.surahName.uppercased()) \u{00B7} \(v.verseNumber)")
                    .font(HFont.captionMedium)
                    .foregroundStyle(Color.hSubtext)
                    .tracking(1)

                VStack(spacing: HSpacing.md) {
                    // Gap fill revealed: show the missing word highlighted
                    if activeType == 2, let hideIdx = hiddenWordIndex {
                        revealedGapFillTextView(for: v, hiddenIndex: hideIdx)
                            .frame(maxWidth: .infinity)
                    } else {
                        verseTextView(for: v)
                            .frame(maxWidth: .infinity)
                    }

                    let translation = v.words
                        .filter { $0.charTypeName == "word" }
                        .compactMap(\.translation)
                        .joined(separator: " ")

                    if !translation.isEmpty {
                        Text(translation)
                            .font(HFont.body)
                            .foregroundStyle(Color.hSubtext)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }
            }

            // Play button
            Button {
                if let v = currentVerse(for: card) {
                    let verseKey = "\(card.surahId):\(v.verseNumber)"
                    audioService.toggleVerse(verseKey)
                }
            } label: {
                Circle()
                    .fill(Color.hDarkText)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .offset(x: audioService.isPlaying ? 0 : 2)
                    }
            }
            .padding(.top, HSpacing.sm)

            Spacer()
        }
        .padding(HSpacing.xl)
    }

    // MARK: - End of Ayah Marker

    private func endOfAyahMarker(verseNumber: Int, color: Color = .hOliveGreen) -> some View {
        let num = arabicNumeral(verseNumber)
        return Text(" \(num)")
            .font(HFont.amiriQuran(20))
            .foregroundStyle(color)
    }

    private func arabicNumeral(_ number: Int) -> String {
        let digits = ["\u{0660}", "\u{0661}", "\u{0662}", "\u{0663}", "\u{0664}",
                      "\u{0665}", "\u{0666}", "\u{0667}", "\u{0668}", "\u{0669}"]
        return String(number).compactMap { Int(String($0)).map { digits[$0] } }.joined()
    }

    // MARK: - Verse Text View

    private func verseTextView(for verse: CachedVerse) -> some View {
        var segments: [(id: Int, view: AnyView)] = []

        for (index, word) in verse.words.enumerated() {
            if index > 0 {
                segments.append((id: index * 1000, view: AnyView(
                    Text(" ").font(HFont.amiriQuran(26))
                )))
            }

            if word.charTypeName == "end" {
                segments.append((id: index, view: AnyView(
                    endOfAyahMarker(verseNumber: verse.verseNumber)
                )))
            } else {
                segments.append((id: index, view: AnyView(
                    Text(word.textUthmani.cleanArabic)
                        .font(HFont.amiriQuran(26))
                        .foregroundStyle(Color.hOliveGreen)
                )))
            }
        }

        return GapFillFlowLayout(segments: segments)
            .environment(\.layoutDirection, .rightToLeft)
    }

    /// Revealed gap fill: show the hidden word in dark text, rest in olive.
    private func revealedGapFillTextView(for verse: CachedVerse, hiddenIndex: Int) -> some View {
        var segments: [(id: Int, view: AnyView)] = []

        for (index, word) in verse.words.enumerated() {
            if index > 0 {
                segments.append((id: index * 1000, view: AnyView(
                    Text(" ").font(HFont.amiriQuran(26))
                )))
            }

            if word.charTypeName == "end" {
                segments.append((id: index, view: AnyView(
                    endOfAyahMarker(verseNumber: verse.verseNumber)
                )))
            } else if index == hiddenIndex {
                segments.append((id: index, view: AnyView(
                    Text(word.textUthmani.cleanArabic)
                        .font(HFont.amiriQuran(26))
                        .foregroundStyle(Color.hDarkText)
                )))
            } else {
                segments.append((id: index, view: AnyView(
                    Text(word.textUthmani.cleanArabic)
                        .font(HFont.amiriQuran(26))
                        .foregroundStyle(Color.hOliveGreen)
                )))
            }
        }

        return GapFillFlowLayout(segments: segments)
            .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Gap Fill Text

    private func pickHiddenWordIndex(for verse: CachedVerse) -> Int {
        let words = verse.words.enumerated().filter { $0.element.charTypeName == "word" }
        guard !words.isEmpty else { return 0 }
        var rng = SeededRandomNumberGenerator(seed: UInt64(verse.id &+ 7))
        return words.randomElement(using: &rng)?.offset ?? 0
    }

    private func gapFillText(for verse: CachedVerse) -> some View {
        let hideIndex = hiddenWordIndex ?? pickHiddenWordIndex(for: verse)

        var segments: [(id: Int, view: AnyView)] = []

        for (index, word) in verse.words.enumerated() {
            if index > 0 {
                segments.append((id: index * 1000, view: AnyView(
                    Text(" ")
                        .font(HFont.amiriQuran(26))
                )))
            }

            if index == hideIndex {
                segments.append((id: index, view: AnyView(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.hDarkText.opacity(0.06))
                        .frame(width: 60, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.hDarkText.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 2)
                )))
            } else if word.charTypeName == "end" {
                segments.append((id: index, view: AnyView(
                    endOfAyahMarker(verseNumber: verse.verseNumber)
                )))
            } else {
                segments.append((id: index, view: AnyView(
                    Text(word.textUthmani.cleanArabic)
                        .font(HFont.amiriQuran(26))
                        .foregroundStyle(Color.hDarkText)
                )))
            }
        }

        return GapFillFlowLayout(segments: segments)
            .environment(\.layoutDirection, .rightToLeft)
            .onAppear {
                if hiddenWordIndex == nil {
                    hiddenWordIndex = hideIndex
                }
            }
    }

    // MARK: - Next Card Button

    private func nextCardButton(for card: DeckCard) -> some View {
        let isLastCard = currentStep + 1 >= totalSteps
        return Button {
            advanceToNext(card: card)
        } label: {
            Text(isLastCard ? "Finish Review" : "Next card")
                .font(HFont.generalSans(17, weight: .medium))
                .tracking(-0.2)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.hOliveGreen)
                .clipShape(Capsule())
        }
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: HSpacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.hOliveGreen)
            Text("Review Complete!")
                .font(HFont.heading)
            Text("You reviewed \(totalSteps) cards")
                .font(HFont.body)
                .foregroundStyle(Color.hSubtext)

            HButton(title: "Done") {
                dismiss()
            }
        }
        .padding(HSpacing.screenPadding)
    }

    // MARK: - Actions

    private func advanceToNext(card: DeckCard) {
        audioService.pause()
        hiddenWordIndex = nil

        let isLastStep = currentStep + 1 >= totalSteps
        if isLastStep {
            deckViewModel.reviewCard(card, confidence: "good", context: modelContext)
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            isRevealed = false
            currentStep += 1
        }
    }
}

// MARK: - Gap Fill Flow Layout

private struct GapFillFlowLayout: View {
    let segments: [(id: Int, view: AnyView)]

    var body: some View {
        GapFillWrappingLayout(alignment: .center, spacing: 0) {
            ForEach(segments, id: \.id) { segment in
                segment.view
            }
        }
    }
}

private struct GapFillWrappingLayout: Layout {
    var alignment: HorizontalAlignment
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        var maxWidth: CGFloat = 0

        for (index, row) in rows.enumerated() {
            let rowHeight = row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight
            if index > 0 { height += 8 }
            let rowWidth = row.map { subviews[$0].sizeThatFits(.unspecified).width }.reduce(0, +)
            maxWidth = max(maxWidth, rowWidth)
        }

        return CGSize(width: proposal.width ?? maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            let sizes = row.map { subviews[$0].sizeThatFits(.unspecified) }
            let rowHeight = sizes.map(\.height).max() ?? 0
            let rowWidth = sizes.map(\.width).reduce(0, +)

            var x: CGFloat
            switch alignment {
            case .center:
                x = bounds.midX - rowWidth / 2
            case .trailing:
                x = bounds.maxX - rowWidth
            default:
                x = bounds.minX
            }

            for (i, idx) in row.enumerated() {
                let size = sizes[i]
                subviews[idx].place(
                    at: CGPoint(x: x, y: y + (rowHeight - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width
            }

            y += rowHeight + 8
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[Int]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[Int]] = [[]]
        var currentWidth: CGFloat = 0

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if currentWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentWidth = 0
            }
            rows[rows.count - 1].append(index)
            currentWidth += size.width
        }

        return rows
    }
}

// MARK: - Seeded RNG

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
