import SwiftUI

struct ContinueFromHereView: View {
    @Bindable var viewModel: ChallengeViewModel

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let ayahTextColor = Color(red: 61/255, green: 56/255, blue: 52/255)
    private let cardBg = Color(red: 255/255, green: 253/255, blue: 248/255)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)
    private let progressTrackColor = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.06)

    private var playCount: Int { viewModel.continueFromAyahCount }
    private var continueFrom: Int { viewModel.challenge.verseStart + playCount }
    private var isMemoryPhase: Bool { viewModel.continueFromMemoryPhase }
    private var isVerificationPhase: Bool { viewModel.continueFromVerificationPhase }
    private var isStumblePhase: Bool { viewModel.continueFromStumblePhase }
    private var isNotePhase: Bool { viewModel.continueFromNotePhase }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text(titleText)
                    .font(.custom("Georgia", size: 22))
                    .foregroundStyle(Color.hDarkText)
                    .tracking(-0.3)

                Text(subtitleText)
                    .font(HFont.generalSans(14))
                    .foregroundStyle(subtextColor)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, isStumblePhase ? 6 : 20)

            if isStumblePhase {
                // Instruction for stumble phase
                Text("Tap the ayahs you stumbled on \u{2014} they\u{2019}ll surface sooner in your review deck.")
                    .font(HFont.generalSans(13))
                    .foregroundStyle(Color.hOliveGreen)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.opacity)
            }

            if isNotePhase {
                // Note text field
                noteCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .transition(.opacity)
            } else if isStumblePhase {
                stumbleCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            } else {
                quranTextCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }

            if isStumblePhase {
                // Flagged count
                Text("\(viewModel.stumbledVerses.count) flagged for review")
                    .font(HFont.generalSans(13))
                    .foregroundStyle(subtextColor)
                    .padding(.bottom, 16)
                    .transition(.opacity)
            } else if isMemoryPhase {
                // Italic prompt below card
                Text(viewModel.continueFromPrompt)
                    .font(.custom("Georgia", size: 14).italic())
                    .foregroundStyle(Color.hOliveGreen)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.opacity)
            } else if !isVerificationPhase && !isNotePhase {
                // Audio player pill (Phase 1 only)
                audioPlayerPill
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isMemoryPhase)
        .animation(.easeInOut(duration: 0.3), value: isVerificationPhase)
        .animation(.easeInOut(duration: 0.3), value: isStumblePhase)
        .animation(.easeInOut(duration: 0.3), value: isNotePhase)
        .task {
            await viewModel.startContinueFromAudio()
        }
    }

    private var titleText: String {
        if isNotePhase { return "Add a note" }
        if isStumblePhase { return "Continue from here" }
        if isVerificationPhase { return "How did you do?" }
        return "Continue from here"
    }

    private var subtitleText: String {
        if isNotePhase {
            return "Jot down what tripped you up. This note is just for you."
        }
        if isVerificationPhase {
            return "Check the ayahs you recited below."
        }
        let playText = playCount == 1
            ? "We\u{2019}ll play only ayah \(viewModel.challenge.verseStart)."
            : "We\u{2019}ll play ayahs \(viewModel.challenge.verseStart)\u{2013}\(viewModel.challenge.verseStart + playCount - 1)."
        if isStumblePhase {
            return "\(playText) When the audio stops, continue aloud from ayah \(continueFrom)."
        }
        return "\(playText) When the audio stops, continue aloud from ayah \(continueFrom)."
    }

    // MARK: - Note Card

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextEditor(text: $viewModel.continueFromNote)
                .font(HFont.generalSans(15))
                .foregroundStyle(Color.hDarkText)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 160)
                .overlay(alignment: .topLeading) {
                    if viewModel.continueFromNote.isEmpty {
                        Text("e.g. \u{201C}I keep mixing up ayah 3 and 4\u{2026}\u{201D}")
                            .font(HFont.generalSans(15))
                            .foregroundStyle(Color.hDarkText.opacity(0.3))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding(16)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Quran Text Card

    private var quranTextCard: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .trailing, spacing: 0) {
                        // Status label
                        HStack {
                            Spacer()
                            Text(statusLabel)
                                .font(HFont.generalSans(11, weight: .medium))
                                .tracking(0.5)
                                .foregroundStyle(statusLabelColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(statusLabelBg)
                                )
                            Spacer()
                        }
                        .padding(.bottom, 14)

                        ForEach(isVerificationPhase ? viewModel.verses : Array(viewModel.verses.prefix(playCount))) { verse in
                            Text(verseAttributedText(verse))
                                .font(HFont.amiriQuran(32))
                                .environment(\.layoutDirection, .rightToLeft)
                                .multilineTextAlignment(.leading)
                                .lineSpacing(8)
                                .frame(maxWidth: .infinity, alignment: .trailing)
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

    private var statusLabel: String {
        if isStumblePhase {
            return "MARK STUMBLES"
        } else if isVerificationPhase {
            return "VERIFICATION"
        } else if isMemoryPhase {
            return "CONTINUE FROM MEMORY"
        } else if viewModel.audioService.isSequentialComplete {
            return "YOUR TURN"
        } else if viewModel.audioService.isPlaying {
            return "AUDIO PLAYING"
        } else {
            return "PAUSED"
        }
    }

    private var statusLabelColor: Color {
        if isStumblePhase { return subtextColor }
        if isVerificationPhase { return subtextColor }
        if isMemoryPhase { return subtextColor }
        if viewModel.audioService.isSequentialComplete { return Color.hOliveGreen }
        return subtextColor
    }

    private var statusLabelBg: Color {
        if isStumblePhase { return Color.hDarkText.opacity(0.04) }
        if isVerificationPhase { return Color.hDarkText.opacity(0.04) }
        if isMemoryPhase { return Color.hDarkText.opacity(0.04) }
        if viewModel.audioService.isSequentialComplete { return Color.hOliveGreen.opacity(0.1) }
        return Color.hDarkText.opacity(0.04)
    }

    private func verseAttributedText(_ verse: CachedVerse) -> AttributedString {
        let isActiveVerse = !isMemoryPhase && viewModel.audioService.activeVerseKey == verse.verseKey
        let highlightBg = Color(red: 233/255, green: 236/255, blue: 227/255)
        var result = AttributedString()
        var wordIndex = 0

        for word in verse.words {
            if word.charTypeName == "end" {
                let arabicNum = arabicNumeral(verse.verseNumber)
                var marker = AttributedString(" \(arabicNum)")
                marker.foregroundColor = Color(red: 91/255, green: 110/255, blue: 79/255)
                result += marker
            } else {
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

    // MARK: - Stumble Card

    private var stumbleCard: some View {
        ScrollView {
            VStack(alignment: .trailing, spacing: 0) {
                // Status label
                HStack {
                    Spacer()
                    Text(statusLabel)
                        .font(HFont.generalSans(11, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(statusLabelColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(statusLabelBg)
                        )
                    Spacer()
                }
                .padding(.bottom, 14)

                ForEach(viewModel.verses) { verse in
                    let isStumbled = viewModel.stumbledVerses.contains(verse.verseNumber)

                    Button {
                        viewModel.toggleStumbledVerse(verse.verseNumber)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            // Checkbox
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(isStumbled ? Color.hOliveGreen : Color.hDarkText.opacity(0.15), lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(isStumbled ? Color.hOliveGreen : Color.clear)
                                    )

                                if isStumbled {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(.top, 6)

                            // Ayah text
                            Text(verseAttributedText(verse))
                                .font(HFont.amiriQuran(22))
                                .environment(\.layoutDirection, .rightToLeft)
                                .multilineTextAlignment(.leading)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .buttonStyle(.plain)

                    if verse.verseNumber != viewModel.verses.last?.verseNumber {
                        Rectangle()
                            .fill(Color.hDarkText.opacity(0.04))
                            .frame(height: 1)
                            .padding(.vertical, 10)
                    }
                }
            }
            .padding(22)
        }
        .frame(height: UIScreen.main.bounds.height * 0.55)
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
                Text("Ayah \(currentAyahNumber) \u{00B7} \(viewModel.challenge.reciterName)")
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

    // MARK: - Helpers

    private var currentAyahNumber: Int {
        guard !viewModel.audioService.activeVerseKey.isEmpty else {
            return viewModel.challenge.verseStart
        }
        let parts = viewModel.audioService.activeVerseKey.split(separator: ":")
        return Int(parts.last ?? "") ?? viewModel.challenge.verseStart
    }

    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = max(0, Int(seconds))
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func arabicNumeral(_ number: Int) -> String {
        let digits = ["\u{0660}", "\u{0661}", "\u{0662}", "\u{0663}", "\u{0664}", "\u{0665}", "\u{0666}", "\u{0667}", "\u{0668}", "\u{0669}"]
        return String(number).compactMap { Int(String($0)).map { digits[$0] } }.joined()
    }
}
