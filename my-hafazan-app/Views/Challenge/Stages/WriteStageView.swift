import SwiftUI

struct WriteStageView: View {
    @Bindable var viewModel: ChallengeViewModel

    var body: some View {
        VStack(spacing: HSpacing.xl) {
            Text("Write the verses from memory")
                .font(HFont.body)
                .foregroundStyle(Color.hSubtext)
                .multilineTextAlignment(.center)

            // Reference
            HCard {
                VStack(spacing: HSpacing.sm) {
                    Text(viewModel.challenge.surahName)
                        .font(HFont.subheading)
                    Text(viewModel.challenge.verseRange)
                        .font(HFont.body)
                        .foregroundStyle(Color.hSubtext)
                }
                .frame(maxWidth: .infinity)
            }

            // Text input
            VStack(alignment: .trailing, spacing: HSpacing.sm) {
                TextEditor(text: $viewModel.writeAttempt)
                    .font(HFont.amiriQuran(22))
                    .environment(\.layoutDirection, .rightToLeft)
                    .frame(minHeight: 150)
                    .padding(HSpacing.md)
                    .background(Color.hCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: HSpacing.cornerRadius))
                    .overlay {
                        RoundedRectangle(cornerRadius: HSpacing.cornerRadius)
                            .stroke(Color.hBorder, lineWidth: 1)
                    }

                Text("\(viewModel.writeAttempt.count) characters")
                    .font(HFont.caption)
                    .foregroundStyle(Color.hSubtext)
            }

            // Score display (after checking)
            if viewModel.writeScore > 0 {
                HCard {
                    VStack(spacing: HSpacing.sm) {
                        Text("Score")
                            .font(HFont.captionMedium)
                            .foregroundStyle(Color.hSubtext)

                        Text("\(Int(viewModel.writeScore * 100))%")
                            .font(HFont.title)
                            .foregroundStyle(scoreColor)

                        ProgressBarView(progress: viewModel.writeScore, color: scoreColor)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var scoreColor: Color {
        if viewModel.writeScore >= 0.8 { return .hStrongGreen }
        if viewModel.writeScore >= 0.5 { return .hModerateYellow }
        return .hWeakRed
    }
}
