import SwiftUI

// MARK: - Gap Fill Token

private enum GapToken: Identifiable {
    case word(id: Int, text: String, translation: String?)
    case blank(id: Int, blankIndex: Int, translation: String?)
    case verseMarker(id: Int, text: String, number: Int)

    var id: Int {
        switch self {
        case .word(let id, _, _): return id
        case .blank(let id, _, _): return id
        case .verseMarker(let id, _, _): return id
        }
    }
}

// MARK: - RTL Flow Layout

private struct RTLFlowLayout: Layout {
    var hSpacing: CGFloat = 6
    var vSpacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let lines = computeLines(subviews: subviews, in: proposal.width ?? .infinity)
        let height = lines.reduce(CGFloat(0)) { $0 + $1.height }
            + CGFloat(max(lines.count - 1, 0)) * vSpacing
        return CGSize(width: proposal.width ?? .infinity, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let lines = computeLines(subviews: subviews, in: bounds.width)
        var y: CGFloat = 0

        for line in lines {
            for item in line.items {
                let size = subviews[item.index].sizeThatFits(.unspecified)
                let yOffset = (line.height - size.height) / 2
                subviews[item.index].place(
                    at: CGPoint(x: bounds.maxX - item.trailingX, y: bounds.minY + y + yOffset),
                    anchor: .topTrailing,
                    proposal: .unspecified
                )
            }
            y += line.height + vSpacing
        }
    }

    private struct LineItem {
        let index: Int
        let trailingX: CGFloat
    }

    private struct Line {
        var items: [LineItem] = []
        var height: CGFloat = 0
    }

    private func computeLines(subviews: Subviews, in width: CGFloat) -> [Line] {
        var lines: [Line] = []
        var current = Line()
        var x: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > width && x > 0 {
                lines.append(current)
                current = Line()
                x = 0
            }

            current.items.append(LineItem(index: index, trailingX: x))
            x += size.width + hSpacing
            current.height = max(current.height, size.height)
        }

        if !current.items.isEmpty {
            lines.append(current)
        }

        return lines
    }
}

// MARK: - Word Bank Flow Layout

private struct WordBankFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(subviews: subviews, in: proposal.width ?? .infinity)
        return CGSize(width: proposal.width ?? result.maxWidth, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(subviews: subviews, in: bounds.width)
        for (index, pos) in result.positions.enumerated() where index < subviews.count {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y),
                anchor: .topLeading,
                proposal: .unspecified
            )
        }
    }

    private func arrange(subviews: Subviews, in width: CGFloat) -> (positions: [CGPoint], maxWidth: CGFloat, height: CGFloat) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                y += lineHeight + spacing
                x = 0
                lineHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            maxWidth = max(maxWidth, x)
            lineHeight = max(lineHeight, size.height)
        }

        return (positions, maxWidth, y + lineHeight)
    }
}

// MARK: - Gap Fill Mode

enum GapFillMode {
    case warmUp
    case harder
}

// MARK: - Gap Fill View

struct GapFillView: View {
    @Bindable var viewModel: ChallengeViewModel
    var mode: GapFillMode = .warmUp

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let labelColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let cardBg = Color(red: 255/255, green: 253/255, blue: 248/255)
    private let blankBg = Color(red: 242/255, green: 238/255, blue: 231/255)
    private let blankDashColor = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.08)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)
    private let cardShadow = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.03)
    private let chipBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.08)

    /// Whether the current ayah has word-level translations cached
    private var hasWordTranslations: Bool {
        guard let ayahGap = viewModel.currentAyahGap else { return false }
        return ayahGap.verse.words.contains { $0.translation != nil }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text(mode == .harder ? "Gap fill \u{2014} harder" : "Gap fill \u{00B7} warm up")
                    .font(.custom("Georgia", size: 22))
                    .foregroundStyle(Color.hDarkText)
                    .tracking(-0.3)

                Text(mode == .harder ? "Every 3rd word is blank. More to recall." : "Fill in the missing words from the bank.")
                    .font(HFont.generalSans(14))
                    .foregroundStyle(subtextColor)
                    .lineSpacing(3)

                if viewModel.ayahGaps.count > 1 {
                    Text(viewModel.gapAyahProgress)
                        .font(HFont.generalSans(13, weight: .medium))
                        .foregroundStyle(Color.hOliveGreen)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 14)

            // Arabic text card with word-by-word translations
            RTLFlowLayout(hSpacing: 18, vSpacing: 6) {
                ForEach(buildTokens()) { token in
                    tokenView(token)
                }
            }
            .padding(22)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(cardBorder, lineWidth: 1)
            )
            .shadow(color: cardShadow, radius: 0, y: 1)
            .padding(.horizontal, 20)
            .id(viewModel.currentGapAyahIndex)
            .transition(.opacity)

            // Sentence-level translation fallback for old challenges without word translations
            if !hasWordTranslations, let ayahGap = viewModel.currentAyahGap {
                Text(viewModel.translationText(for: ayahGap.verse.verseNumber))
                    .font(HFont.generalSans(14))
                    .foregroundStyle(Color(red: 61/255, green: 56/255, blue: 52/255))
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .id(viewModel.currentGapAyahIndex)
            }

            // Word bank
            VStack(alignment: .leading, spacing: 8) {
                Text("WORD BANK")
                    .font(HFont.generalSans(11))
                    .foregroundStyle(labelColor)
                    .tracking(0.6)

                WordBankFlowLayout(spacing: 8) {
                    ForEach(Array(viewModel.gapBankWords.enumerated()), id: \.offset) { index, word in
                        bankChip(word: word, translation: viewModel.gapBankTranslations[safe: index] ?? nil, bankIndex: index)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
            .id(viewModel.currentGapAyahIndex)
        }
        .onAppear {
            if viewModel.ayahGaps.isEmpty {
                if mode == .harder {
                    viewModel.setupGapFillHarder()
                } else {
                    viewModel.setupGapFill()
                }
            }
        }
        .task {
            // Load sentence translations as fallback for old challenges
            if !hasWordTranslations, viewModel.chapterTranslations.isEmpty {
                await viewModel.loadTranslations()
            }
        }
    }

    // MARK: - Token Builder

    private func buildTokens() -> [GapToken] {
        guard let ayahGap = viewModel.currentAyahGap else { return [] }

        var tokens: [GapToken] = []
        var contentWordIndex = 0
        var blankPointer = 0
        var tokenId = 0
        var addedVerseMarker = false
        let blanks = ayahGap.blanks
        let contentWords = ayahGap.verse.words.filter { $0.charTypeName == "word" }

        for word in ayahGap.verse.words {
            if word.charTypeName == "end" && !addedVerseMarker {
                tokens.append(.verseMarker(id: tokenId, text: word.textUthmani, number: ayahGap.verse.verseNumber))
                tokenId += 1
                addedVerseMarker = true
            } else if word.charTypeName == "word" {
                let translation = contentWords[safe: contentWordIndex]?.translation
                if blankPointer < blanks.count
                    && contentWordIndex == blanks[blankPointer].localWordIndex {
                    tokens.append(.blank(id: tokenId, blankIndex: blankPointer, translation: blanks[blankPointer].translationText))
                    blankPointer += 1
                } else {
                    tokens.append(.word(id: tokenId, text: word.textUthmani.cleanArabic, translation: translation))
                }
                contentWordIndex += 1
                tokenId += 1
            }
        }

        return tokens
    }

    // MARK: - Token Views

    @ViewBuilder
    private func tokenView(_ token: GapToken) -> some View {
        switch token {
        case .word(_, let text, let translation):
            VStack(spacing: 2) {
                Text(text)
                    .font(HFont.amiriQuran(32))
                    .foregroundStyle(Color.hDarkText)
                if let translation {
                    Text(translation)
                        .font(HFont.generalSans(10))
                        .foregroundStyle(subtextColor)
                        .lineLimit(1)
                        .fixedSize()
                }
            }

        case .blank(_, let blankIndex, let translation):
            blankView(at: blankIndex, translation: translation)

        case .verseMarker(_, let text, let number):
            VStack(spacing: 2) {
                Text(text)
                    .font(HFont.amiriQuran(24))
                    .foregroundStyle(Color.hOliveGreen)
                Text("(\(number))")
                    .font(HFont.generalSans(10))
                    .foregroundStyle(subtextColor)
            }
        }
    }

    private func blankView(at blankIndex: Int, translation: String?) -> some View {
        let isSelected = viewModel.selectedGapIndex == blankIndex
        let answerBankIndex = viewModel.gapAnswers[blankIndex]
        let answerText = answerBankIndex.map { viewModel.gapBankWords[$0] }
        let correctness = viewModel.isGapCorrect(at: blankIndex)

        let showTranslation = answerText != nil && translation != nil

        return VStack(spacing: 2) {
            Button {
                viewModel.tapGapBlank(at: blankIndex)
            } label: {
                HStack(spacing: 4) {
                    if correctness == true {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.hOliveGreen)
                    }
                    if let text = answerText {
                        Text(text)
                            .font(HFont.amiriQuran(28))
                            .foregroundStyle(
                                correctness == true ? Color.hOliveGreen :
                                correctness == false ? Color.hWeakRed :
                                Color.hDarkText
                            )
                    } else {
                        Text("\u{23AF}\u{23AF}")
                            .font(.system(size: 28))
                            .foregroundStyle(labelColor)
                    }
                    if correctness == false {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.hWeakRed)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 2)
                .background(
                    correctness == true ? Color.hOliveGreen.opacity(0.15) :
                    correctness == false ? Color.hWeakRed.opacity(0.1) :
                    isSelected ? Color.hOliveGreen.opacity(0.12) :
                    blankBg
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            correctness == true ? Color.hOliveGreen :
                            correctness == false ? Color.hWeakRed :
                            isSelected ? Color.hOliveGreen :
                            blankDashColor,
                            style: answerText != nil || isSelected
                                ? StrokeStyle(lineWidth: 1.5)
                                : StrokeStyle(lineWidth: 1, dash: [4, 3])
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.gapFillChecked)

            if showTranslation, let translation {
                Text(translation)
                    .font(HFont.generalSans(10))
                    .foregroundStyle(subtextColor)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }

    // MARK: - Bank Chip

    private func bankChip(word: String, translation: String?, bankIndex: Int) -> some View {
        let isUsed = viewModel.gapAnswers.values.contains(bankIndex)

        return Button {
            viewModel.tapBankWord(at: bankIndex)
        } label: {
            VStack(spacing: 2) {
                Text(word)
                    .font(HFont.amiriQuran(30))
                    .foregroundStyle(Color.hDarkText)
                if let translation {
                    Text(translation)
                        .font(HFont.generalSans(10))
                        .foregroundStyle(subtextColor)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(chipBorder, lineWidth: 1)
            )
            .opacity(isUsed ? 0.3 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isUsed || viewModel.gapFillChecked)
    }

    // MARK: - Helpers

    private func arabicNumeral(_ number: Int) -> String {
        let digits = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        return String(number).compactMap { Int(String($0)).map { digits[$0] } }.joined()
    }
}
