import SwiftUI
import SwiftData

struct DeckListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DeckViewModel()
    @State private var selectedCardForReview: DeckCard? = nil

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let cardBg = Color(red: 255/255, green: 253/255, blue: 248/255)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)

    private let includedCardTypes = [0, 1, 2]

    var body: some View {
        ZStack {
            Color.hCreamBg.ignoresSafeArea()

            if viewModel.cards.isEmpty {
                emptyState
            } else {
                deckList
            }
        }
        .navigationTitle("Revise")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedCardForReview) { card in
            CardReviewView(cards: [card], includedTypes: includedCardTypes)
        }
        .onAppear {
            viewModel.load(context: modelContext)
        }
    }

    private var deckList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.cards) { card in
                    Button {
                        selectedCardForReview = card
                    } label: {
                        deckRow(for: card)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
    }

    private func deckRow(for card: DeckCard) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.surahNameArabic.isEmpty ? card.surahName : card.surahNameArabic)
                    .font(HFont.amiriQuran(18))
                    .foregroundStyle(Color.hDarkText)

                Text("\(card.surahName) \(card.verseStart)\u{2013}\(card.verseEnd)")
                    .font(HFont.generalSans(15, weight: .medium))
                    .foregroundStyle(Color.hDarkText)

                let ayahCount = card.verseEnd - card.verseStart + 1
                Text("\(ayahCount) ayahs \u{00B7} \(ayahCount * 3) cards")
                    .font(HFont.generalSans(12))
                    .foregroundStyle(subtextColor)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(subtextColor)
        }
        .padding(16)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .fill(Color.hDarkText.opacity(0.08))
                    .frame(width: 56, height: 56)
                Image(systemName: "rectangle.stack")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(Color.hDarkText.opacity(0.25))
            }

            Text("No cards yet")
                .font(.custom("Georgia", size: 22))
                .foregroundStyle(Color.hDarkText)

            Text("Complete a challenge to build\nyour review deck.")
                .font(HFont.generalSans(14))
                .foregroundStyle(subtextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
}
