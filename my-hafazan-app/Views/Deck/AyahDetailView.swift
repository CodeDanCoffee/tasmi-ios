import SwiftUI

struct AyahDetailView: View {
    let card: DeckCard
    let verse: CachedVerse
    var includedTypes: [Int] = [0, 1, 2]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var deckViewModel = DeckViewModel()
    @State private var navigateToReview = false
    @State private var navigateToFirstWord = false

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let labelColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let cardBg = Color(red: 255/255, green: 253/255, blue: 248/255)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)

    private var translation: String {
        verse.words
            .filter { $0.charTypeName == "word" }
            .compactMap(\.translation)
            .joined(separator: " ")
    }

    private var ayahAttributedText: AttributedString {
        // Main Arabic text
        var text = AttributedString(verse.textUthmani.cleanArabic)
        text.font = HFont.amiriQuran(26)
        text.foregroundColor = Color.hDarkText

        // Inline verse end marker in olive green
        let marker = " \(arabicNumeral(verse.verseNumber))"
        var markerAttr = AttributedString(marker)
        markerAttr.font = HFont.amiriQuran(18)
        markerAttr.foregroundColor = Color.hOliveGreen

        text.append(markerAttr)
        return text
    }

    var body: some View {
        ZStack {
            Color.hCreamBg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Surah label
                        Text("\(card.surahName.uppercased()) \u{00B7} AYAH \(verse.verseNumber)")
                            .font(HFont.generalSans(11, weight: .medium))
                            .tracking(0.5)
                            .foregroundStyle(labelColor)
                            .padding(.top, 32)
                            .padding(.bottom, 16)

                        // Full Arabic text with inline verse marker
                        Text(ayahAttributedText)
                            .environment(\.layoutDirection, .rightToLeft)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 10)

                        // Translation
                        if !translation.isEmpty {
                            Text(translation)
                                .font(HFont.generalSans(15))
                                .foregroundStyle(subtextColor)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 32)
                                .padding(.bottom, 32)
                        }

                        // Divider
                        Rectangle()
                            .fill(Color.hDarkText.opacity(0.06))
                            .frame(height: 1)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)

                        // Cards section header
                        HStack {
                            Text("3 CARDS \u{00B7} THIS AYAH")
                                .font(HFont.generalSans(11, weight: .medium))
                                .tracking(0.5)
                                .foregroundStyle(labelColor)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                        // Card type rows
                        VStack(spacing: 8) {
                            Button {
                                navigateToFirstWord = true
                            } label: {
                                cardTypeRow(
                                    iconText: "\u{0627}",
                                    iconFont: HFont.amiriQuran(18),
                                    title: "First word",
                                    stage: "Stage 1c",
                                    dueText: dueText(for: .firstWord)
                                )
                            }
                            .buttonStyle(.plain)

                            cardTypeRow(
                                iconText: "\u{23AF}",
                                iconFont: HFont.generalSans(16),
                                title: "Gap fill",
                                stage: "Stage 2",
                                dueText: dueText(for: .gapFill)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                        // Skip link
                        VStack(spacing: 4) {
                            Text("Skip \u{00B7} I have it memorized")
                                .font(HFont.generalSans(13))
                                .foregroundStyle(subtextColor)
                                .underline()

                            Text("Pushes all 3 cards to their next interval")
                                .font(HFont.generalSans(11))
                                .foregroundStyle(labelColor)
                        }
                        .padding(.vertical, 14)
                        .padding(.bottom, 100)
                        .onTapGesture {
                            markAllReviewed()
                        }
                    }
                }

                // Bottom button
                VStack(spacing: 0) {
                    Rectangle().fill(Color.hDarkText.opacity(0.06)).frame(height: 1)

                    Button {
                        navigateToReview = true
                    } label: {
                        Text("Review just this ayah \u{00B7} 3 cards")
                            .font(HFont.generalSans(17, weight: .medium))
                            .tracking(-0.2)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.hOliveGreen)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
                .background(Color.hCreamBg)
            }
        }
        .navigationTitle("Ayah \u{00B7} review")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.hDarkText)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToReview) {
            CardReviewView(cards: [card], verse: verse, includedTypes: includedTypes)
        }
        .navigationDestination(isPresented: $navigateToFirstWord) {
            CardReviewView(cards: [card], verse: verse, includedTypes: includedTypes)
        }
        .onAppear {
            deckViewModel.load(context: modelContext)
        }
    }

    // MARK: - Card Type Row

    private let iconBg = Color(red: 233/255, green: 236/255, blue: 227/255)

    private func cardTypeRow(iconText: String, iconFont: Font, title: String, stage: String, dueText: String) -> some View {
        HStack(spacing: 14) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(iconBg)
                    .frame(width: 36, height: 36)
                Text(iconText)
                    .font(iconFont)
                    .foregroundStyle(Color.hOliveGreen)
            }

            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(HFont.generalSans(14))
                    .foregroundStyle(Color.hDarkText)
                Text("from \(stage) \u{00B7} \(dueText)")
                    .font(HFont.generalSans(11))
                    .foregroundStyle(subtextColor)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(labelColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.hDarkText.opacity(0.03), radius: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.hDarkText.opacity(0.04), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private enum CardType {
        case firstWord, gapFill
    }

    private func dueText(for type: CardType) -> String {
        let baseDate = card.nextReviewDate
        let offset: TimeInterval
        switch type {
        case .firstWord:
            offset = 0
        case .gapFill:
            offset = 4 * 24 * 3600
        }

        let dueDate = baseDate.addingTimeInterval(offset)
        let now = Date()
        let days = Calendar.current.dateComponents([.day], from: now, to: dueDate).day ?? 0

        if days < 0 {
            return "Overdue"
        } else if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "Due tomorrow"
        } else {
            return "Due in \(days) days"
        }
    }

    private func markAllReviewed() {
        deckViewModel.reviewCard(card, confidence: "strong", context: modelContext)
        dismiss()
    }

    private func arabicNumeral(_ number: Int) -> String {
        let digits = ["\u{0660}", "\u{0661}", "\u{0662}", "\u{0663}", "\u{0664}",
                      "\u{0665}", "\u{0666}", "\u{0667}", "\u{0668}", "\u{0669}"]
        return String(number).compactMap { Int(String($0)).map { digits[$0] } }.joined()
    }
}
