import SwiftUI

struct TranslationMatchView: View {
    @Bindable var viewModel: ChallengeViewModel
    @State private var expandedVerseKey: String?

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let chevronColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let translationTextColor = Color(red: 61/255, green: 56/255, blue: 52/255)
    private let cardBorderColor = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)
    private let dividerColor = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.06)
    private let listenBtnBg = Color(red: 242/255, green: 238/255, blue: 231/255)
    private let listenBtnBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.08)

    var body: some View {
        VStack(spacing: 0) {
            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text("Meet the translations")
                    .font(.custom("Georgia", size: 22))
                    .foregroundStyle(Color.hDarkText)
                    .tracking(-0.3)

                Text("Read what each ayah means. Tap to expand. Take your time. The next activity tests recall.")
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
            } else if let error = viewModel.translationError {
                Text(error)
                    .font(HFont.generalSans(14))
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(.top, 40)
                Spacer()
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.verses) { verse in
                        accordionCard(verse: verse)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Accordion Card

    private func accordionCard(verse: CachedVerse) -> some View {
        let isExpanded = expandedVerseKey == verse.verseKey

        return VStack(spacing: 0) {
            // Header row (always visible)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedVerseKey = isExpanded ? nil : verse.verseKey
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    // Full Arabic text with verse marker
                    Text(fullArabicWithMarker(verse))
                        .font(HFont.amiriQuran(32))
                        .environment(\.layoutDirection, .rightToLeft)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(8)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(chevronColor)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                expandedSection(verse: verse)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.03), radius: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorderColor, lineWidth: 1)
        )
    }

    // MARK: - Expanded Section

    @ViewBuilder
    private func expandedSection(verse: CachedVerse) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Divider
            Rectangle()
                .fill(dividerColor)
                .frame(height: 1)

            // English translation
            Text(viewModel.translationText(for: verse.verseNumber))
                .font(HFont.generalSans(14))
                .foregroundStyle(translationTextColor)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            // Listen to ayah button
            HStack(spacing: 8) {
                Button {
                    viewModel.audioService.toggleVerse(verse.verseKey)
                } label: {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(listenBtnBg)
                                .frame(width: 32, height: 32)
                            Circle()
                                .stroke(listenBtnBorder, lineWidth: 1)
                                .frame(width: 32, height: 32)

                            let isPlayingThis = viewModel.audioService.activeVerseKey == verse.verseKey
                                && viewModel.audioService.isPlaying
                            Image(systemName: isPlayingThis ? "pause.fill" : "play.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.hDarkText)
                                .offset(x: isPlayingThis ? 0 : 1)
                        }

                        Text("Listen to ayah \(verse.verseNumber)")
                            .font(HFont.generalSans(12))
                            .foregroundStyle(subtextColor)
                    }
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 18)
        }
    }

    // MARK: - Helpers

    private func fullArabicWithMarker(_ verse: CachedVerse) -> AttributedString {
        // Build text from words array, excluding "end" markers to avoid duplicates
        let contentWords = verse.words.filter { $0.charTypeName == "word" }
        let cleaned = contentWords.map { $0.textUthmani.cleanArabic }.joined(separator: " ")
        var result = AttributedString(cleaned)
        result.foregroundColor = Color.hDarkText

        let arabicNum = arabicNumeral(verse.verseNumber)
        var marker = AttributedString(" \(arabicNum)")
        marker.foregroundColor = Color.hOliveGreen
        marker.font = HFont.amiriQuran(24)
        result += marker

        return result
    }

    private func arabicNumeral(_ number: Int) -> String {
        let digits = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        return String(number).compactMap { Int(String($0)).map { digits[$0] } }.joined()
    }

}
