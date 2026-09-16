import SwiftUI
import SwiftData

struct JourneyView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = JourneyViewModel()

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let labelColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let cardBg = Color(red: 255/255, green: 253/255, blue: 248/255)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)

    var body: some View {
        ZStack {
            Color.hCreamBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your journey, ayah by ayah.")
                            .font(.custom("Georgia", size: 36))
                            .foregroundStyle(Color.hDarkText)
                            .tracking(-0.3)
                            .lineSpacing(2)

                        Text("What you\u{2019}ve brought into salah.")
                            .font(HFont.generalSans(14))
                            .foregroundStyle(subtextColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)

                    // Stats row
                    HStack(spacing: 10) {
                        statCard(value: "\(viewModel.totalVerses)", label: "Ayahs")
                        statCard(value: "\(viewModel.totalChallenges)", label: "Challenges")
                        statCard(value: "\(viewModel.currentStreak)", label: "Day streak")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)

                    // Surahs in progress
                    if !viewModel.surahProgresses.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("SURAHS IN PROGRESS")
                                .font(HFont.generalSans(11, weight: .medium))
                                .tracking(0.5)
                                .foregroundStyle(labelColor)
                                .padding(.horizontal, 20)

                            ForEach(viewModel.surahProgresses) { surah in
                                surahCard(surah)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle("My Journey")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.load(context: modelContext)
        }
    }

    // MARK: - Stat Card

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("Georgia", size: 28))
                .foregroundStyle(Color.hDarkText)
                .tracking(-0.3)
            Text(label)
                .font(HFont.generalSans(12))
                .foregroundStyle(subtextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Surah Card

    private func surahCard(_ surah: SurahProgress) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row: Arabic name + verse count
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(surah.surahNameArabic.isEmpty ? surah.surahName : surah.surahNameArabic)
                        .font(HFont.amiriQuran(24))
                        .foregroundStyle(Color.hDarkText)
                    Text(surah.surahName)
                        .font(HFont.generalSans(14))
                        .foregroundStyle(subtextColor)
                }

                Spacer()

                // Verse count / COMPLETE
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(surah.memorizedAyahs)")
                            .font(HFont.generalSans(18, weight: .semibold))
                            .foregroundStyle(Color.hDarkText)
                        Text("/\(surah.totalAyahs)")
                            .font(HFont.generalSans(14))
                            .foregroundStyle(labelColor)
                    }

                    if surah.isComplete {
                        Text("COMPLETE")
                            .font(HFont.generalSans(11, weight: .medium))
                            .tracking(0.3)
                            .foregroundStyle(Color.hOliveGreen)
                    }
                }
            }
            .padding(.bottom, 14)

            // Segmented progress bar
            segmentedProgressBar(surah: surah)
                .padding(.bottom, 10)

            // Bottom label
            if surah.isComplete {
                Text("\(surah.memorizedAyahs) of \(surah.totalAyahs) \u{00B7} completed")
                    .font(HFont.generalSans(12))
                    .foregroundStyle(subtextColor)
            } else {
                Text("\(surah.memorizedAyahs) of \(surah.totalAyahs) ayahs \u{00B7} \(surah.challengeCount) challenges")
                    .font(HFont.generalSans(12))
                    .foregroundStyle(subtextColor)
            }
        }
        .padding(20)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Segmented Progress Bar

    private func segmentedProgressBar(surah: SurahProgress) -> some View {
        GeometryReader { geo in
            let totalAyahs = surah.totalAyahs
            let spacing: CGFloat = totalAyahs > 20 ? 1.5 : 2
            let totalSpacing = spacing * CGFloat(totalAyahs - 1)
            let segmentWidth = max(2, (geo.size.width - totalSpacing) / CGFloat(totalAyahs))

            HStack(spacing: spacing) {
                ForEach(1...totalAyahs, id: \.self) { ayah in
                    let isMemorized = surah.memorizedRanges.contains { ayah >= $0.start && ayah <= $0.end }
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isMemorized
                            ? Color.hOliveGreen
                            : Color.hOliveGreen.opacity(0.15))
                        .frame(width: segmentWidth, height: 8)
                }
            }
        }
        .frame(height: 8)
    }
}
