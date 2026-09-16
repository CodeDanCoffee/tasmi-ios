import SwiftUI

struct ReadStageView: View {
    @Bindable var viewModel: ChallengeViewModel
    let showHints: Bool

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let mutedColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let cardBg = Color(red: 255/255, green: 253/255, blue: 248/255)
    private let thinBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.06)
    private let buttonBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.08)

    var body: some View {
        if showHints {
            reciteInOrderView
        } else {
            fromMemoryView
        }
    }

    // MARK: - Stage 3: Recite in order

    private var reciteInOrderView: some View {
        VStack(spacing: 0) {
            // Title & subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text("Recite in order")
                    .font(HFont.sourceSerif(22, weight: .semibold))
                    .foregroundStyle(Color.hDarkText)
                    .tracking(-0.3)

                Text("Ayahs \(viewModel.challenge.verseStart) through \(viewModel.challenge.verseEnd), aloud, from memory. Tap \u{2018}Show me\u{2019} only if you get stuck \u{2014} no penalty.")
                    .font(HFont.generalSans(14))
                    .foregroundStyle(subtextColor)
                    .lineSpacing(14 * 0.45 - 14 * 0.2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 14)

            // Card
            VStack(spacing: 0) {
                // "BEGIN FROM" + counter
                VStack(spacing: 4) {
                    Text("BEGIN FROM")
                        .font(HFont.generalSans(11))
                        .foregroundStyle(mutedColor)
                        .tracking(0.6)

                    Text("\(currentAyahNumber) / \(totalAyahCount)")
                        .font(.system(size: 40, design: .serif))
                        .foregroundStyle(Color.hDarkText)
                        .tracking(-1)
                }
                .padding(.bottom, 18)

                // Divider (full card width)
                Rectangle()
                    .fill(thinBorder)
                    .frame(height: 1)
                    .padding(.horizontal, -28)

                // Arabic text with verse end marker + translation per ayah
                if viewModel.currentReciteIndex >= 0 {
                    let endIdx = min(viewModel.currentReciteIndex, viewModel.verses.count - 1)
                    VStack(alignment: .trailing, spacing: 16) {
                        ForEach(0...endIdx, id: \.self) { i in
                            VStack(alignment: .trailing, spacing: 8) {
                                Text(verseAttributedText(viewModel.verses[i]))
                                    .font(HFont.amiriQuran(32))
                                    .multilineTextAlignment(.trailing)
                                    .lineSpacing(16)
                                    .frame(maxWidth: .infinity, alignment: .trailing)

                                let translation = verseTranslation(viewModel.verses[i])
                                if !translation.isEmpty {
                                    Text(translation)
                                        .font(HFont.generalSans(14))
                                        .foregroundStyle(subtextColor)
                                        .multilineTextAlignment(.leading)
                                        .lineSpacing(3)
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                    .id(viewModel.currentReciteIndex)
                    .transition(.opacity)
                }
            }
            .padding(28)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.hDarkText.opacity(0.04), lineWidth: 1)
            )
            .shadow(color: Color.hDarkText.opacity(0.03), radius: 0, y: 1)
            .padding(.horizontal, 20)

            // "Show me ayah X" button
            if viewModel.canShowNextAyah {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.showNextReciteAyah()
                    }
                } label: {
                    Text(viewModel.currentReciteIndex < 0
                         ? "Show me ayah 1"
                         : "Show me ayah \(currentAyahNumber + 1)")
                        .font(HFont.generalSans(15, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(Color.hDarkText)
                        .padding(.horizontal, 22)
                        .frame(height: 44)
                        .overlay(
                            Capsule()
                                .stroke(buttonBorder, lineWidth: 1)
                        )
                }
                .padding(.top, 24)
            }

        }
    }

    // MARK: - Stage 4: From memory

    private var fromMemoryView: some View {
        VStack(spacing: HSpacing.xl) {
            Text("Try to recall the verses from memory")
                .font(HFont.body)
                .foregroundStyle(Color.hSubtext)
                .multilineTextAlignment(.center)

            VStack(spacing: HSpacing.xl) {
                HCard {
                    VStack(spacing: HSpacing.md) {
                        Text(viewModel.challenge.surahName)
                            .font(HFont.subheading)
                        Text(viewModel.challenge.verseRange)
                            .font(HFont.body)
                            .foregroundStyle(Color.hSubtext)

                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.hOliveGreen.opacity(0.3))
                            .padding(.top, HSpacing.lg)
                    }
                    .frame(maxWidth: .infinity)
                }

                if viewModel.hasAssessedSelf {
                    VStack(spacing: HSpacing.md) {
                        ForEach(viewModel.verses, id: \.id) { verse in
                            AyahTextView(text: verse.textUthmani.cleanArabic, fontSize: 22, words: verse.words, showTranslation: true)
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Helpers

    private var currentAyahNumber: Int {
        viewModel.currentReciteIndex + 1
    }

    private var totalAyahCount: Int {
        viewModel.verses.count
    }

    private var currentVerseText: String {
        guard viewModel.currentReciteIndex < viewModel.verses.count else { return "" }
        return viewModel.verses[viewModel.currentReciteIndex].textUthmani.cleanArabic
    }

    private func verseTranslation(_ verse: CachedVerse) -> String {
        let verseLevel = viewModel.translationText(for: verse.verseNumber)
        if !verseLevel.isEmpty { return verseLevel }
        return verse.words
            .filter { $0.charTypeName == "word" }
            .compactMap { $0.translation }
            .joined(separator: " ")
    }

    private func verseAttributedText(_ verse: CachedVerse) -> AttributedString {
        var result = AttributedString()
        var wordIndex = 0

        for word in verse.words {
            if word.charTypeName == "end" {
                let arabicNum = arabicNumeral(verse.verseNumber)
                var marker = AttributedString(" \(arabicNum)")
                marker.foregroundColor = Color.hDarkText
                result += marker
            } else {
                if wordIndex > 0 {
                    result += AttributedString(" ")
                }
                var attr = AttributedString(word.textUthmani.cleanArabic)
                attr.foregroundColor = Color.hDarkText
                result += attr
                wordIndex += 1
            }
        }
        return result
    }

    private func arabicNumeral(_ number: Int) -> String {
        let digits = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        return String(number).compactMap { Int(String($0)).map { digits[$0] } }.joined()
    }
}
