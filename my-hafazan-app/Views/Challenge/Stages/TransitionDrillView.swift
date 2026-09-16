import SwiftUI

struct TransitionDrillView: View {
    @Bindable var viewModel: ChallengeViewModel

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let mutedColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let cardBg = Color(red: 255/255, green: 253/255, blue: 248/255)
    private let warmBeige = Color(red: 242/255, green: 238/255, blue: 231/255)

    var body: some View {
        VStack(spacing: 0) {
            // Title & subtitle
            VStack(alignment: .leading, spacing: 4) {
                (Text("Last word ") + Text(Image(systemName: "arrow.right")).font(.system(size: 16, weight: .medium)) + Text(" first word"))
                    .font(HFont.sourceSerif(22, weight: .semibold))
                    .foregroundStyle(Color.hDarkText)
                    .tracking(-0.3)

                Text("Say the first word of the next ayah before revealing it. This trains the hardest part: ayah-to-ayah transitions.")
                    .font(HFont.generalSans(14))
                    .foregroundStyle(subtextColor)
                    .lineSpacing(14 * 0.25)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 14)

            Spacer(minLength: 20)

            // Counter
            Text("Transition \(viewModel.currentTransitionIndex + 1) of \(viewModel.totalTransitions)")
                .font(HFont.generalSans(13))
                .foregroundStyle(mutedColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 16)

            // Card
            VStack(spacing: 0) {
                // End of ayah label
                Text("END OF AYAH \(currentAyahNumber)")
                    .font(HFont.generalSans(11))
                    .foregroundStyle(mutedColor)
                    .tracking(0.6)
                    .padding(.bottom, 12)

                // Last word with ellipsis
                Text("\u{2026}\(viewModel.transitionLastWords)")
                    .font(HFont.amiriQuran(38))
                    .foregroundStyle(Color.hDarkText)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 16)

                // Down arrow
                Text("\u{2193}")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Color.hOliveGreen)
                    .padding(.bottom, 16)

                // First word of next ayah label
                Text("FIRST WORD OF AYAH \(nextAyahNumber)")
                    .font(HFont.generalSans(11))
                    .foregroundStyle(mutedColor)
                    .tracking(0.6)
                    .padding(.bottom, 12)

                // Revealed / hidden state
                if viewModel.isTransitionRevealed {
                    Text(viewModel.transitionFirstWord)
                        .font(HFont.amiriQuran(38))
                        .foregroundStyle(Color.hOliveGreen)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    hiddenPlaceholder
                        .transition(.opacity)
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.hDarkText.opacity(0.04), lineWidth: 1)
            )
            .shadow(color: Color.hDarkText.opacity(0.03), radius: 0, y: 1)
            .padding(.horizontal, 20)
            .id(viewModel.currentTransitionIndex)
            .animation(.easeInOut(duration: 0.25), value: viewModel.isTransitionRevealed)

            // Instruction
            Text("Say the first word aloud now.\nWhen you\u{2019}re ready, reveal to check.")
                .font(HFont.generalSans(13))
                .foregroundStyle(mutedColor)
                .multilineTextAlignment(.center)
                .lineSpacing(13 * 0.3)
                .padding(.top, 20)
                .padding(.horizontal, 24)

            Spacer(minLength: 20)
        }
    }

    // MARK: - Hidden placeholder

    private var hiddenPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(warmBeige)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(Color.hDarkText.opacity(0.1))
            )
            .overlay(
                Text("\u{2014}  \u{2014}  \u{2014}")
                    .font(HFont.generalSans(20, weight: .medium))
                    .foregroundStyle(Color.hDarkText.opacity(0.15))
            )
            .frame(height: 72)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private var currentAyahNumber: Int {
        guard viewModel.currentTransitionIndex < viewModel.verses.count else { return 0 }
        return viewModel.verses[viewModel.currentTransitionIndex].verseNumber
    }

    private var nextAyahNumber: Int {
        let nextIndex = viewModel.currentTransitionIndex + 1
        guard nextIndex < viewModel.verses.count else { return 0 }
        return viewModel.verses[nextIndex].verseNumber
    }
}
