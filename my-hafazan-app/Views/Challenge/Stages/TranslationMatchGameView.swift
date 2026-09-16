import SwiftUI

struct TranslationMatchGameView: View {
    @Bindable var viewModel: ChallengeViewModel

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let labelColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let translationTextColor = Color(red: 61/255, green: 56/255, blue: 52/255)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.08)
    private let matchedBg = Color(red: 233/255, green: 236/255, blue: 227/255) // light olive

    var body: some View {
        VStack(spacing: 0) {
            // Title section
            VStack(alignment: .leading, spacing: 4) {
                Text("Translation match")
                    .font(.custom("Georgia", size: 22))
                    .foregroundStyle(Color.hDarkText)
                    .tracking(-0.3)

                Text("Tap a translation, then tap the ayah it belongs to.")
                    .font(HFont.generalSans(14))
                    .foregroundStyle(subtextColor)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 14)

            if viewModel.isLoadingTranslations {
                ProgressView()
                    .padding(.top, 40)
                Spacer()
            } else {
                // Two-column layout
                HStack(alignment: .top, spacing: 10) {
                    // Left column – Ayahs
                    VStack(alignment: .leading, spacing: 0) {
                        Text("AYAHS")
                            .font(HFont.generalSans(11))
                            .foregroundStyle(labelColor)
                            .tracking(0.6)
                            .padding(.bottom, 8)

                        VStack(spacing: 8) {
                            ForEach(viewModel.verses) { verse in
                                ayahCard(verse: verse)
                            }
                        }
                    }

                    // Right column – Translations (shuffled)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("TRANSLATIONS")
                            .font(HFont.generalSans(11))
                            .foregroundStyle(labelColor)
                            .tracking(0.6)
                            .padding(.bottom, 8)

                        VStack(spacing: 8) {
                            ForEach(Array(viewModel.shuffledTranslationOrder.enumerated()), id: \.offset) { displayIndex, translationIndex in
                                let verseNumber = viewModel.challenge.verseStart + translationIndex
                                let verseKey = "\(viewModel.challenge.surahId):\(verseNumber)"
                                let isMatched = viewModel.matchedPairs.contains(verseKey)
                                let isSelected = viewModel.selectedTranslationIndex == displayIndex

                                translationCard(
                                    displayIndex: displayIndex,
                                    text: viewModel.translationText(for: verseNumber),
                                    isSelected: isSelected,
                                    isMatched: isMatched
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // Match counter
                Text("\(viewModel.matchedPairs.count) of \(viewModel.verses.count) matched")
                    .font(HFont.generalSans(12))
                    .foregroundStyle(subtextColor)
                    .padding(.top, 4)
                    .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Ayah Card

    private func ayahCard(verse: CachedVerse) -> some View {
        let isMatched = viewModel.matchedPairs.contains(verse.verseKey)
        let isWrong = viewModel.wrongMatchVerseKey == verse.verseKey

        return Button {
            guard !isMatched else { return }
            if viewModel.selectedTranslationIndex != nil {
                viewModel.checkTranslationMatch(
                    translationDisplayIndex: viewModel.selectedTranslationIndex!,
                    verseKey: verse.verseKey
                )
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(verse.verseNumber)")
                        .font(HFont.generalSans(10))
                        .foregroundStyle(isMatched ? Color.hOliveGreen : subtextColor)
                        .monospacedDigit()

                    Spacer()

                    if isMatched {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.hOliveGreen)
                    }
                }

                Text(fullArabic(verse))
                    .font(HFont.amiriQuran(15))
                    .foregroundStyle(Color.hDarkText)
                    .environment(\.layoutDirection, .rightToLeft)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 60)
            .background(isMatched ? matchedBg : .white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isMatched ? Color.hOliveGreen :
                        isWrong ? Color.hWeakRed.opacity(0.5) :
                        cardBorder,
                        lineWidth: isMatched || isWrong ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
    }

    // MARK: - Translation Card

    private func translationCard(displayIndex: Int, text: String, isSelected: Bool, isMatched: Bool) -> some View {
        Button {
            guard !isMatched else { return }
            if viewModel.selectedTranslationIndex == displayIndex {
                viewModel.selectedTranslationIndex = nil
            } else {
                viewModel.selectedTranslationIndex = displayIndex
            }
        } label: {
            HStack(alignment: .top, spacing: 6) {
                Text(text)
                    .font(HFont.generalSans(12))
                    .foregroundStyle(translationTextColor)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isMatched {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.hOliveGreen)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 60)
            .background(isMatched ? matchedBg : isSelected ? Color.hOliveGreen.opacity(0.08) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isMatched ? Color.hOliveGreen :
                        isSelected ? Color.hOliveGreen :
                        cardBorder,
                        lineWidth: isMatched || isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
    }

    // MARK: - Helpers

    private func fullArabic(_ verse: CachedVerse) -> String {
        let contentWords = verse.words.filter { $0.charTypeName == "word" }
        return contentWords.map { $0.textUthmani.cleanArabic }.joined(separator: " ")
    }
}
