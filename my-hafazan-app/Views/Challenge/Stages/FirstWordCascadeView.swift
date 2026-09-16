import SwiftUI

struct FirstWordCascadeView: View {
    @Bindable var viewModel: ChallengeViewModel

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let mutedColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let cardBg = Color.white
    private let lineColor = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.08)

    var body: some View {
        VStack(spacing: 0) {
            // Title & subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text("First-word cascade")
                    .font(HFont.sourceSerif(22, weight: .semibold))
                    .foregroundStyle(Color.hDarkText)
                    .tracking(-0.3)

                Text("Each ayah shows only its opening word. Recite the full ayah aloud, then tap to verify.")
                    .font(HFont.generalSans(14))
                    .foregroundStyle(subtextColor)
                    .lineSpacing(14 * 0.25)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 18)

            // Ayah cards with timeline
            VStack(spacing: 0) {
                ForEach(Array(viewModel.verses.enumerated()), id: \.element.id) { index, verse in
                    ayahRow(index: index, verse: verse)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Ayah Row

    @ViewBuilder
    private func ayahRow(index: Int, verse: CachedVerse) -> some View {
        let isRevealed = viewModel.cascadeRevealedAyahs.contains(index)
        let isVerified = viewModel.cascadeVerifiedAyahs.contains(index)
        let isLast = index == viewModel.verses.count - 1
        let firstWord = (verse.words.first(where: { $0.charTypeName == "word" })?.textUthmani ?? "").cleanArabic

        HStack(alignment: .top, spacing: 0) {
            // Timeline: number/checkmark + connector line
            VStack(spacing: 0) {
                if isVerified {
                    // Filled green circle with checkmark
                    ZStack {
                        Circle()
                            .fill(Color.hOliveGreen)
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                } else {
                    // Regular numbered circle
                    ZStack {
                        Circle()
                            .stroke(lineColor, lineWidth: 1.5)
                            .frame(width: 28, height: 28)
                        Text("\(index + 1)")
                            .font(HFont.generalSans(12, weight: .medium))
                            .foregroundStyle(mutedColor)
                    }
                }

                // Connector line
                if !isLast {
                    Rectangle()
                        .fill(lineColor)
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 28)
            .padding(.trailing, 10)

            // Card
            VStack(spacing: 0) {
                if isRevealed {
                    revealedCard(index: index, verse: verse, firstWord: firstWord)
                } else {
                    hiddenCard(firstWord: firstWord, index: index)
                }
            }
            .frame(maxWidth: .infinity)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.bottom, isLast ? 0 : 12)
        }
    }

    // MARK: - Hidden Card

    @ViewBuilder
    private func hiddenCard(firstWord: String, index: Int) -> some View {
        HStack(spacing: 0) {
            Spacer()

            // First word + blank line
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Rectangle()
                    .fill(Color.hDarkText.opacity(0.15))
                    .frame(width: 60, height: 1.5)
                    .offset(y: -6)

                Text(firstWord)
                    .font(HFont.amiriQuran(28))
                    .foregroundStyle(Color.hDarkText)
            }

            Spacer()

            // Reveal button
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.revealCascadeAyah(at: index)
                }
            } label: {
                Text("reveal")
                    .font(HFont.generalSans(13))
                    .foregroundStyle(mutedColor)
            }
            .padding(.trailing, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }

    // MARK: - Revealed Card

    @ViewBuilder
    private func revealedCard(index: Int, verse: CachedVerse, firstWord: String) -> some View {
        let isVerified = viewModel.cascadeVerifiedAyahs.contains(index)
        let isStumbled = viewModel.cascadeStumbledAyahs.contains(index)

        VStack(spacing: 0) {
            // Top section: first word + hide (cream bg)
            HStack(alignment: .firstTextBaseline) {
                Spacer()

                Text(firstWord)
                    .font(HFont.amiriQuran(28))
                    .foregroundStyle(Color.hDarkText)

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.hideCascadeAyah(at: index)
                    }
                } label: {
                    Text("hide")
                        .font(HFont.generalSans(13))
                        .foregroundStyle(mutedColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)

            // Separator line
            Rectangle()
                .fill(Color.hDarkText.opacity(0.06))
                .frame(height: 1)

            // Bottom section: full text + translation + buttons
            VStack(spacing: 0) {
                // Full ayah text
                Text(verse.textUthmani.cleanArabic)
                    .font(HFont.amiriQuran(22))
                    .foregroundStyle(Color.hDarkText)
                    .multilineTextAlignment(.trailing)
                    .lineSpacing(10)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 14)

                // Translation
                let translation = viewModel.translationText(for: verse.verseNumber)
                if !translation.isEmpty {
                    Text(translation)
                        .font(HFont.generalSans(14))
                        .foregroundStyle(subtextColor)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(14 * 0.25)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                }

                // Stumbled / I had it buttons (always interactive, right-aligned)
                HStack(spacing: 10) {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.stumbleCascadeAyah(at: index)
                        }
                    } label: {
                        Text("Missed")
                            .font(HFont.generalSans(14, weight: .medium))
                            .foregroundStyle(Color.hDarkText.opacity(isVerified ? 0.3 : 1))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                isStumbled
                                    ? Capsule().fill(Color(red: 235/255, green: 231/255, blue: 225/255))
                                    : Capsule().fill(Color.clear)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        Color.hDarkText.opacity(isStumbled ? 0 : (isVerified ? 0.06 : 0.12)),
                                        lineWidth: 1
                                    )
                            )
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.verifyCascadeAyah(at: index)
                        }
                    } label: {
                        Text("Passed")
                            .font(HFont.generalSans(14, weight: .medium))
                            .foregroundStyle(Color.hDarkText.opacity(isStumbled ? 0.3 : 1))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                isVerified
                                    ? Capsule().fill(Color.hOliveGreen.opacity(0.15))
                                    : Capsule().fill(Color.clear)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        Color.hDarkText.opacity(isVerified ? 0 : (isStumbled ? 0.06 : 0.12)),
                                        lineWidth: 1
                                    )
                            )
                    }
                }
                .padding(.top, 14)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}
