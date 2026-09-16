import SwiftUI

struct ListenStageView: View {
    @Bindable var viewModel: ChallengeViewModel
    let showText: Bool

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let ayahTextColor = Color(red: 61/255, green: 56/255, blue: 52/255)
    private let cardBg = Color(red: 255/255, green: 253/255, blue: 248/255)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)
    private let highlightBg = Color(red: 233/255, green: 236/255, blue: 227/255)
    private let progressTrackColor = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.06)

    var body: some View {
        VStack(spacing: 0) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Listen & follow along")
                    .font(.custom("Georgia", size: 22))
                    .foregroundStyle(Color.hDarkText)
                    .tracking(-0.3)

                Text(showText
                     ? "Let the words wash over you. Your eyes follow your ear. No pressure to remember."
                     : "Close your eyes and let the recitation sink in. Focus on the rhythm and melody.")
                    .font(HFont.generalSans(14))
                    .foregroundStyle(subtextColor)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 20)

            if showText {
                // Quran text card
                quranTextCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            } else {
                // Listen-only: ear icon card
                listenOnlyCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }

            // Audio player pill
            audioPlayerPill
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Quran Text Card

    private var quranTextCard: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .trailing, spacing: 16) {
                        ForEach(viewModel.verses) { verse in
                            VStack(alignment: .trailing, spacing: 8) {
                                Text(verseAttributedText(verse))
                                    .font(HFont.amiriQuran(32))
                                    .multilineTextAlignment(.trailing)
                                    .lineSpacing(8)
                                    .frame(maxWidth: .infinity, alignment: .trailing)

                                let translation = verseTranslation(verse)
                                if !translation.isEmpty {
                                    Text(translation)
                                        .font(HFont.generalSans(14))
                                        .foregroundStyle(subtextColor)
                                        .multilineTextAlignment(.leading)
                                        .lineSpacing(3)
                                }
                            }
                            .id(verse.verseKey)
                        }
                    }
                    .padding(22)
                }
                .frame(height: geo.size.height)
                .onChange(of: viewModel.audioService.activeVerseKey) { _, newKey in
                    guard !newKey.isEmpty else { return }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newKey, anchor: .center)
                    }
                }
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.4)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    private func verseAttributedText(_ verse: CachedVerse) -> AttributedString {
        let isActiveVerse = viewModel.audioService.activeVerseKey == verse.verseKey
        var result = AttributedString()
        var wordIndex = 0

        for word in verse.words {
            if word.charTypeName == "end" {
                let arabicNum = arabicNumeral(verse.verseNumber)
                var marker = AttributedString(" \(arabicNum)")
                marker.foregroundColor = Color(red: 91/255, green: 110/255, blue: 79/255)
                marker.font = HFont.amiriQuran(20)
                result += marker
            } else if word.charTypeName == "word" {
                if wordIndex > 0 {
                    result += AttributedString(" ")
                }
                var attr = AttributedString(word.textUthmani.cleanArabic)
                if isActiveVerse && wordIndex == viewModel.audioService.currentWordIndex {
                    attr.foregroundColor = Color(red: 91/255, green: 110/255, blue: 79/255)
                    attr.backgroundColor = highlightBg
                } else {
                    attr.foregroundColor = ayahTextColor
                }
                wordIndex += 1
                result += attr
            }
        }

        return result
    }

    // MARK: - Listen Only Card

    private var listenOnlyCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "ear.fill")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(Color.hOliveGreen.opacity(0.3))

            Text("Focus on the recitation")
                .font(HFont.generalSans(14))
                .foregroundStyle(subtextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Audio Player Pill

    private var audioPlayerPill: some View {
        HStack(spacing: 12) {
            // Play/pause button
            Button {
                viewModel.audioService.toggleSequential()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.hDarkText)
                        .frame(width: 40, height: 40)
                    Image(systemName: viewModel.audioService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .offset(x: viewModel.audioService.isPlaying ? 0 : 1)
                }
            }

            // Info + progress
            VStack(alignment: .leading, spacing: 6) {
                Text("Ayah \(currentAyahNumber) · \(viewModel.challenge.reciterName)")
                    .font(HFont.generalSans(13))
                    .foregroundStyle(Color.hDarkText)
                    .lineLimit(1)

                // Progress bar
                GeometryReader { geo in
                    let fraction = viewModel.audioService.duration > 0
                        ? geo.size.width * CGFloat(viewModel.audioService.currentTime / viewModel.audioService.duration)
                        : 0
                    Capsule()
                        .fill(progressTrackColor)
                        .frame(height: 3)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(Color.hOliveGreen)
                                .frame(width: min(fraction, geo.size.width), height: 3)
                        }
                        .clipShape(Capsule())
                }
                .frame(height: 3)
            }

            // Time
            Text("\(formatTime(viewModel.audioService.currentTime)) / \(formatTime(viewModel.audioService.duration))")
                .font(HFont.generalSans(12))
                .foregroundStyle(subtextColor)
                .monospacedDigit()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var currentAyahNumber: Int {
        guard !viewModel.audioService.activeVerseKey.isEmpty else {
            return viewModel.challenge.verseStart
        }
        let parts = viewModel.audioService.activeVerseKey.split(separator: ":")
        return Int(parts.last ?? "") ?? viewModel.challenge.verseStart
    }

    private var statusLabel: String {
        if viewModel.audioService.isSequentialComplete {
            return "Complete"
        } else if viewModel.audioService.isPlaying {
            return "Playing"
        } else {
            return "Paused"
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = max(0, Int(seconds))
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func verseTranslation(_ verse: CachedVerse) -> String {
        let verseLevel = viewModel.translationText(for: verse.verseNumber)
        if !verseLevel.isEmpty { return verseLevel }
        return verse.words
            .filter { $0.charTypeName == "word" }
            .compactMap { $0.translation }
            .joined(separator: " ")
    }

    private func arabicNumeral(_ number: Int) -> String {
        let digits = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        return String(number).compactMap { Int(String($0)).map { digits[$0] } }.joined()
    }

}
