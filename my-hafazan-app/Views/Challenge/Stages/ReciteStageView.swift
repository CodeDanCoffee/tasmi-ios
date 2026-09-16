import SwiftUI

struct ReciteStageView: View {
    @Bindable var viewModel: ChallengeViewModel
    @State private var expandedRounds: Set<Int> = []

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let cardBg = Color(red: 255/255, green: 253/255, blue: 248/255)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)
    private let labelColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let gateBadgeColor = Color(red: 180/255, green: 120/255, blue: 80/255)

    var body: some View {
        VStack(spacing: 0) {
            // Gate stage badge
            if viewModel.currentStageType.isGate {
                Text("GATE STAGE")
                    .font(HFont.generalSans(11, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(gateBadgeColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(gateBadgeColor.opacity(0.1))
                    )
                    .padding(.top, 10)
                    .padding(.bottom, 8)
            }

            // Title
            Text("The Chain Challenge")
                .font(.custom("Georgia", size: 24))
                .foregroundStyle(Color.hDarkText)
                .tracking(-0.3)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            // Description
            Text("Recite each round aloud, continuously, without help. Each round builds on the last.")
                .font(HFont.generalSans(14))
                .foregroundStyle(subtextColor)
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

            // Chain rounds card
            chainCard
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            // Motivational text
            Text("No text. No audio. Just you and the ayahs.")
                .font(.custom("Georgia", size: 14).italic())
                .foregroundStyle(subtextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.chainCurrentRound)
    }

    // MARK: - Chain Card

    private var chainCard: some View {
        VStack(spacing: 0) {
            ForEach(1...viewModel.chainTotalRounds, id: \.self) { round in
                chainRow(round: round)

                if round < viewModel.chainTotalRounds {
                    Rectangle()
                        .fill(Color.hDarkText.opacity(0.04))
                        .frame(height: 1)
                        .padding(.leading, 56)
                }
            }
        }
        .padding(.vertical, 8)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorder, lineWidth: 1)
        )
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

    private func chainRow(round: Int) -> some View {
        let isCurrent = round == viewModel.chainActiveRound && !viewModel.isChainComplete
        let isCompleted = viewModel.chainStarted && round < viewModel.chainCurrentRound
        let verseStart = viewModel.challenge.verseStart
        let verseEnd = verseStart + round - 1
        let isExpanded = expandedRounds.contains(round)

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if expandedRounds.contains(round) {
                        expandedRounds.remove(round)
                    } else {
                        expandedRounds.insert(round)
                    }
                }
            } label: {
                HStack(spacing: 14) {
                    // Number circle
                    ZStack {
                        if isCompleted {
                            Circle()
                                .fill(Color.hOliveGreen)
                                .frame(width: 28, height: 28)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Circle()
                                .stroke(
                                    isCurrent ? Color.hDarkText.opacity(0.3) :
                                    Color.hDarkText.opacity(0.12),
                                    lineWidth: 1
                                )
                                .frame(width: isCurrent ? 32 : 28, height: isCurrent ? 32 : 28)
                            Text("\(round)")
                                .font(HFont.generalSans(isCurrent ? 14 : 12, weight: isCurrent ? .medium : .regular))
                                .foregroundStyle(isCurrent ? Color.hDarkText : labelColor)
                        }
                    }

                    // Round label
                    if round == 1 {
                        Text("Ayah \(verseStart)")
                            .font(isCurrent
                                ? HFont.generalSans(16, weight: .semibold)
                                : HFont.generalSans(14))
                            .foregroundStyle(isCurrent ? Color.hDarkText : subtextColor)
                    } else {
                        Text("Ayahs \(verseStart) \u{2192} \(verseEnd)")
                            .font(isCurrent
                                ? HFont.generalSans(16, weight: .semibold)
                                : HFont.generalSans(14))
                            .foregroundStyle(isCurrent ? Color.hDarkText : subtextColor)
                    }

                    Spacer()

                    // NOW badge for current round
                    if isCurrent {
                        Text("NOW")
                            .font(HFont.generalSans(11, weight: .medium))
                            .tracking(0.3)
                            .foregroundStyle(subtextColor)
                    }

                    // Dropdown chevron
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(labelColor)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded ayah text
            if isExpanded {
                VStack(alignment: .trailing, spacing: 12) {
                    ForEach(0..<round, id: \.self) { index in
                        if index < viewModel.verses.count {
                            VStack(alignment: .trailing, spacing: 6) {
                                Text(verseAttributedText(viewModel.verses[index]))
                                    .font(HFont.amiriQuran(32))
                                    .lineSpacing(14)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: .infinity, alignment: .trailing)

                                let translation = verseTranslation(viewModel.verses[index])
                                if !translation.isEmpty {
                                    Text(translation)
                                        .font(HFont.generalSans(13))
                                        .foregroundStyle(labelColor)
                                        .multilineTextAlignment(.leading)
                                        .lineSpacing(2)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
                .padding(.top, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
