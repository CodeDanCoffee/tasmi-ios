import SwiftUI

struct TimelineView: View {
    let entries: [JourneyEntry]

    var body: some View {
        if entries.isEmpty {
            HCard {
                VStack(spacing: HSpacing.sm) {
                    Image(systemName: "clock")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.hSubtext.opacity(0.5))
                    Text("No activity yet")
                        .font(HFont.body)
                        .foregroundStyle(Color.hSubtext)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, HSpacing.xl)
            }
        } else {
            VStack(spacing: 0) {
                ForEach(entries.prefix(20)) { entry in
                    HStack(alignment: .top, spacing: HSpacing.md) {
                        // Timeline dot + line
                        VStack(spacing: 0) {
                            Circle()
                                .fill(iconColor(for: entry.type))
                                .frame(width: 10, height: 10)
                            Rectangle()
                                .fill(Color.hBorder)
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                        .frame(width: 10)

                        // Content
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: icon(for: entry.type))
                                    .font(.system(size: 12))
                                    .foregroundStyle(iconColor(for: entry.type))

                                Text(entry.surahName)
                                    .font(HFont.bodyMedium)
                                    .foregroundStyle(Color.hDarkText)
                            }

                            Text(entry.detail)
                                .font(HFont.caption)
                                .foregroundStyle(Color.hSubtext)

                            Text(DateFormatters.relativeString(from: entry.date))
                                .font(HFont.caption)
                                .foregroundStyle(Color.hSubtext.opacity(0.7))
                        }
                        .padding(.bottom, HSpacing.lg)
                    }
                }
            }
        }
    }

    private func icon(for type: String) -> String {
        switch type {
        case JourneyEntryType.stageCompleted: return "checkmark.circle"
        case JourneyEntryType.challengeCompleted: return "checkmark.seal.fill"
        case JourneyEntryType.deckReview: return "rectangle.stack"
        case JourneyEntryType.challengeStarted: return "play.circle"
        default: return "circle"
        }
    }

    private func iconColor(for type: String) -> Color {
        switch type {
        case JourneyEntryType.challengeCompleted: return .hOliveGreen
        case JourneyEntryType.deckReview: return .hModerateYellow
        default: return .hOliveGreen
        }
    }
}
