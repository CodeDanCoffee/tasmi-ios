import SwiftUI

struct CompletionView: View {
    let challenge: Challenge
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var deckViewModel = DeckViewModel()
    @State private var appeared = false
    @State private var showShareSheet = false

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let cardBg = Color(red: 255/255, green: 253/255, blue: 248/255)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)
    private let iconBg = Color(red: 233/255, green: 236/255, blue: 227/255)

    private var nextVerseStart: Int { challenge.verseEnd + 1 }
    private var nextVerseEnd: Int { challenge.verseEnd + challenge.verseCount }
    private var nextRangeLabel: String {
        "\(challenge.surahName) \(nextVerseStart)\u{2013}\(nextVerseEnd)"
    }

    var body: some View {
        ZStack {
            Color.hCreamBg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Decorative icon
                        ZStack {
                            Circle()
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                .fill(Color.hOliveGreen.opacity(0.25))
                                .frame(width: 56, height: 56)
                            Image(systemName: "sun.min")
                                .font(.system(size: 24, weight: .light))
                                .foregroundStyle(Color.hOliveGreen.opacity(0.5))
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                        .scaleEffect(appeared ? 1.0 : 0.6)
                        .opacity(appeared ? 1.0 : 0)

                        // Title
                        Text("Alhamdulillah.")
                            .font(.custom("Georgia", size: 32).italic())
                            .foregroundStyle(Color.hOliveGreen)
                            .tracking(-0.3)
                            .padding(.bottom, 24)
                            .opacity(appeared ? 1.0 : 0)

                        // Surah reference
                        surahReferenceText
                            .padding(.bottom, 8)
                            .opacity(appeared ? 1.0 : 0)

                        Text("is now part of your salah.")
                            .font(.custom("Georgia", size: 20))
                            .foregroundStyle(Color.hDarkText)
                            .tracking(-0.3)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 16)
                            .opacity(appeared ? 1.0 : 0)

                        // Description
                        Text("These ayahs are yours \u{2014} not because you passed a test, but because you\u{2019}ve prayed with them.")
                            .font(HFont.generalSans(14))
                            .foregroundStyle(subtextColor)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 24)
                            .opacity(appeared ? 1.0 : 0)

                        // Divider
                        Rectangle()
                            .fill(Color.hDarkText.opacity(0.06))
                            .frame(height: 1)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 24)

                        // Info cards
                        VStack(spacing: 10) {
                            infoCard(
                                icon: "rectangle.stack.fill",
                                title: "Your review deck is ready",
                                subtitle: "\(challenge.verseCount) cards, browse anytime"
                            )

                            infoCard(
                                icon: "scope",
                                title: "Continue the surah",
                                subtitle: "Recommendation: \(nextRangeLabel)"
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        .opacity(appeared ? 1.0 : 0)
                    }
                }

                // Bottom buttons
                VStack(spacing: 10) {
                    Rectangle().fill(Color.hDarkText.opacity(0.06)).frame(height: 1)

                    Button {
                        dismiss()
                    } label: {
                        Text("Open Review Deck")
                            .font(HFont.generalSans(17, weight: .medium))
                            .tracking(-0.2)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.hOliveGreen)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Button {
                        showShareSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .medium))
                            Text("Share a reflection")
                                .font(HFont.generalSans(15, weight: .medium))
                                .tracking(-0.2)
                        }
                        .foregroundStyle(Color.hOliveGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            Capsule()
                                .stroke(Color.hOliveGreen.opacity(0.35), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)

                    HStack(spacing: 10) {
                        Button {
                            dismiss()
                        } label: {
                            Text("New\nChallenge")
                                .font(HFont.generalSans(15, weight: .medium))
                                .tracking(-0.2)
                                .foregroundStyle(Color.hDarkText)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.hDarkText.opacity(0.08), lineWidth: 1)
                                )
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Back to Home")
                                .font(HFont.generalSans(15, weight: .medium))
                                .tracking(-0.2)
                                .foregroundStyle(Color.hDarkText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.hDarkText.opacity(0.08), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(Color.hCreamBg)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ComposeReflectionSheet(
                viewModel: ComposeReflectionViewModel(challenge: challenge)
            )
        }
        .onAppear {
            deckViewModel.addCard(from: challenge, context: modelContext)

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()
            }
        }
    }

    // MARK: - Info Card

    private func infoCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconBg)
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.hOliveGreen)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(HFont.generalSans(15, weight: .medium))
                    .foregroundStyle(Color.hDarkText)
                Text(subtitle)
                    .font(HFont.generalSans(12))
                    .foregroundStyle(subtextColor)
            }

            Spacer()
        }
        .padding(16)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Arabic Verse Reference

    private var surahReferenceText: Text {
        let arabicName = arabicSurahName(for: challenge.surahId)

        return Text(arabicName)
            .font(HFont.amiriQuran(28))
            .foregroundColor(Color.hOliveGreen)
        + Text(" \(challenge.verseStart)-\(challenge.verseEnd)")
            .font(.custom("Georgia", size: 22))
            .foregroundColor(Color.hOliveGreen)
    }

    private func arabicSurahName(for id: Int) -> String {
        let names: [Int: String] = [
            1: "\u{0627}\u{0644}\u{0641}\u{0627}\u{062A}\u{062D}\u{0629}",
            2: "\u{0627}\u{0644}\u{0628}\u{0642}\u{0631}\u{0629}",
            36: "\u{064A}\u{0633}",
            55: "\u{0627}\u{0644}\u{0631}\u{062D}\u{0645}\u{0646}",
            56: "\u{0627}\u{0644}\u{0648}\u{0627}\u{0642}\u{0639}\u{0629}",
            67: "\u{0627}\u{0644}\u{0645}\u{064F}\u{0644}\u{0643}",
            78: "\u{0627}\u{0644}\u{0646}\u{0628}\u{0623}",
            112: "\u{0627}\u{0644}\u{0625}\u{062E}\u{0644}\u{0627}\u{0635}",
            113: "\u{0627}\u{0644}\u{0641}\u{0644}\u{0642}",
            114: "\u{0627}\u{0644}\u{0646}\u{0627}\u{0633}",
        ]
        return names[id] ?? challenge.surahName
    }
}
