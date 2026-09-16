import SwiftUI

struct RandomDropInView: View {
    @Bindable var viewModel: ChallengeViewModel

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let cardBg = Color(red: 255/255, green: 253/255, blue: 248/255)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)
    private let progressTrackColor = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.06)
    private let labelColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let ayahTextColor = Color(red: 61/255, green: 56/255, blue: 52/255)

    /// Verses from the drop-in point to the end of the range
    private var carryOnVerses: [(number: Int, firstWord: String)] {
        guard viewModel.currentDropInAyahIndex < viewModel.verses.count else { return [] }
        return viewModel.verses[viewModel.currentDropInAyahIndex...].map { verse in
            let firstWord = verse.words.first(where: { $0.charTypeName == "word" })?.textUthmani.cleanArabic ?? ""
            return (verse.verseNumber, firstWord)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Random drop-in")
                    .font(.custom("Georgia", size: 22))
                    .foregroundStyle(Color.hDarkText)
                    .tracking(-0.3)

                Text("The app picks a random spot. Listen to the cue, then carry on aloud to the end of the range.")
                    .font(HFont.generalSans(14))
                    .foregroundStyle(subtextColor)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 16)

            // Attempts tracker (hidden in review phase)
            if viewModel.dropInPhase != .review {
                attemptsTracker
                    .padding(.bottom, 20)
                    .transition(.opacity)
            }

            // Drop-in card
            dropInCard
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            // Phase-specific content below card
            switch viewModel.dropInPhase {
            case .cue:
                audioPlayerPill
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .transition(.opacity)

            case .recite:
                Text("Carry on aloud through ayah \(viewModel.challenge.verseEnd).")
                    .font(.custom("Georgia", size: 14).italic())
                    .foregroundStyle(Color.hOliveGreen)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.opacity)

            case .review:
                // Self-assessment
                VStack(spacing: 12) {
                    Text("How was that one?")
                        .font(HFont.generalSans(14))
                        .foregroundStyle(subtextColor)

                    HStack(spacing: 10) {
                        assessmentPill(label: "Shaky", value: "shaky")
                        assessmentPill(label: "Solid", value: "solid")
                    }
                }
                .padding(.bottom, 16)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.dropInPhase)
        .animation(.easeInOut(duration: 0.3), value: viewModel.dropInAttempts)
        .task {
            viewModel.setupRandomDropIn()
            await viewModel.startDropInCueAudio()
        }
        .onChange(of: viewModel.dropInAttempts) { _, _ in
            if !viewModel.isDropInComplete {
                Task {
                    await viewModel.startDropInCueAudio()
                }
            }
        }
    }

    // MARK: - Attempts Tracker

    private var attemptsTracker: some View {
        HStack(spacing: 8) {
            Text("ATTEMPTS")
                .font(HFont.generalSans(11, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(labelColor)

            HStack(spacing: 6) {
                ForEach(0..<viewModel.dropInMaxAttempts, id: \.self) { index in
                    Circle()
                        .fill(index < viewModel.dropInAttempts
                            ? Color.hOliveGreen
                            : Color.hDarkText.opacity(0.1))
                        .frame(width: 8, height: 8)
                }
            }

            Text("\(viewModel.dropInAttempts) of \(viewModel.dropInMaxAttempts)")
                .font(HFont.generalSans(12))
                .foregroundStyle(subtextColor)
        }
    }

    // MARK: - Assessment Pill

    private func assessmentPill(label: String, value: String) -> some View {
        let isSelected = viewModel.dropInSelfAssessment == value
        let shakyColor = Color(red: 180/255, green: 120/255, blue: 80/255)
        let activeColor = value == "shaky" ? shakyColor : Color.hOliveGreen
        let unselectedText = Color(red: 168/255, green: 160/255, blue: 152/255)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.dropInSelfAssessment = value
            }
        } label: {
            Text(label)
                .font(HFont.generalSans(14, weight: .medium))
                .foregroundStyle(isSelected ? activeColor : unselectedText)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? activeColor : Color.hDarkText.opacity(0.08), lineWidth: 1)
                )
        }
    }

    // MARK: - Drop-in Card

    private var dropInCard: some View {
        VStack(spacing: 0) {
            // Section 1: DROP-IN header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DROP-IN")
                        .font(HFont.generalSans(11, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(labelColor)

                    Text("From ayah \(viewModel.currentDropInVerseNumber)")
                        .font(.custom("Georgia", size: 20))
                        .foregroundStyle(Color.hDarkText)
                }

                Spacer()

                // Decorative icon
                ZStack {
                    Circle()
                        .fill(Color(red: 233/255, green: 236/255, blue: 227/255))
                        .frame(width: 48, height: 48)
                    Text("\u{06DE}")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.hOliveGreen.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Divider
            sectionDivider

            // Section 2: CUE · LISTEN / YOU CONTINUE FROM
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.dropInPhase == .cue ? "CUE \u{00B7} LISTEN" : "YOU CONTINUE FROM")
                    .font(HFont.generalSans(11, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(labelColor)

                Text(viewModel.dropInCueText)
                    .font(HFont.amiriQuran(22))
                    .foregroundStyle(Color.hDarkText)
                    .environment(\.layoutDirection, .rightToLeft)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)

            // Section 3: CARRY ON THROUGH (recite phase) or FULL PASSAGE (review phase)
            if viewModel.dropInPhase == .recite {
                sectionDivider

                VStack(alignment: .leading, spacing: 16) {
                    Text("CARRY ON THROUGH")
                        .font(HFont.generalSans(11, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(labelColor)

                    ForEach(carryOnVerses, id: \.number) { item in
                        carryOnRow(number: item.number, firstWord: item.firstWord)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .transition(.opacity)
            } else if viewModel.dropInPhase == .review {
                sectionDivider

                VStack(alignment: .leading, spacing: 12) {
                    Text("FULL PASSAGE")
                        .font(HFont.generalSans(11, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(labelColor)

                    Text(fullPassageText())
                        .font(HFont.amiriQuran(32))
                        .environment(\.layoutDirection, .rightToLeft)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(8)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .transition(.opacity)
            }
        }
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.hDarkText.opacity(0.06))
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    // MARK: - Carry On Row

    private func carryOnRow(number: Int, firstWord: String) -> some View {
        HStack(spacing: 0) {
            // Ayah number circle
            ZStack {
                Circle()
                    .stroke(Color.hOliveGreen.opacity(0.3), lineWidth: 1)
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(HFont.generalSans(12))
                    .foregroundStyle(Color.hOliveGreen)
            }

            Spacer()

            // First word + line
            HStack(spacing: 10) {
                Rectangle()
                    .fill(Color.hDarkText.opacity(0.15))
                    .frame(width: 48, height: 1)

                Text(firstWord)
                    .font(HFont.amiriQuran(20))
                    .foregroundStyle(Color.hDarkText)
            }
        }
    }

    // MARK: - Full Passage Text

    private func fullPassageText() -> AttributedString {
        var result = AttributedString()
        let startIndex = viewModel.currentDropInAyahIndex
        guard startIndex < viewModel.verses.count else { return result }

        let passageVerses = Array(viewModel.verses[startIndex...])

        for (vIdx, verse) in passageVerses.enumerated() {
            var wordIndex = 0
            for word in verse.words {
                if word.charTypeName == "end" {
                    let arabicNum = arabicNumeral(verse.verseNumber)
                    var marker = AttributedString(" \(arabicNum)")
                    marker.foregroundColor = Color(red: 91/255, green: 110/255, blue: 79/255)
                    result += marker
                } else {
                    if wordIndex > 0 || vIdx > 0 {
                        result += AttributedString(" ")
                    }
                    var attr = AttributedString(word.textUthmani.cleanArabic)
                    attr.foregroundColor = ayahTextColor
                    result += attr
                    wordIndex += 1
                }
            }
        }

        return result
    }

    private func arabicNumeral(_ number: Int) -> String {
        let digits = ["\u{0660}", "\u{0661}", "\u{0662}", "\u{0663}", "\u{0664}", "\u{0665}", "\u{0666}", "\u{0667}", "\u{0668}", "\u{0669}"]
        return String(number).compactMap { Int(String($0)).map { digits[$0] } }.joined()
    }

    // MARK: - Audio Player Pill

    private var audioPlayerPill: some View {
        HStack(spacing: 12) {
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

            VStack(alignment: .leading, spacing: 6) {
                Text("Ayah \(viewModel.dropInCueVerseNumber) \u{00B7} \(viewModel.challenge.reciterName)")
                    .font(HFont.generalSans(13))
                    .foregroundStyle(Color.hDarkText)
                    .lineLimit(1)

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

    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = max(0, Int(seconds))
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
