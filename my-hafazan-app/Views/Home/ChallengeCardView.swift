import SwiftUI

struct ChallengeCardView: View {
    let challenge: Challenge
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HCard {
                VStack(alignment: .leading, spacing: HSpacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(challenge.surahName)
                                .font(HFont.bodyMedium)
                                .foregroundStyle(Color.hDarkText)
                            Text(challenge.verseRange)
                                .font(HFont.caption)
                                .foregroundStyle(Color.hSubtext)
                        }

                        Spacer()

                        Text(challenge.surahNameArabic)
                            .font(HFont.amiriQuran(22))
                            .foregroundStyle(Color.hOliveGreen)
                    }

                    HStack(spacing: HSpacing.md) {
                        // Stage info
                        HStack(spacing: HSpacing.xs) {
                            Image(systemName: StageType(rawValue: challenge.currentStage)?.icon ?? "circle")
                                .font(.system(size: 12))
                            Text("Stage \(challenge.currentStage)/\(StageDefinitions.stageCount(for: challenge.templateType))")
                                .font(HFont.caption)
                        }
                        .foregroundStyle(Color.hOliveGreen)

                        Spacer()

                        // Progress
                        ProgressBarView(progress: challenge.progressFraction)
                            .frame(width: 80)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}
