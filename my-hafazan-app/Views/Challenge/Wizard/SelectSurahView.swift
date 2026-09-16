import SwiftUI

struct SelectSurahView: View {
    @Bindable var viewModel: ChallengeWizardViewModel

    var body: some View {
        VStack(spacing: HSpacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: HSpacing.xs) {
                Text("Pick a surah")
                    .font(HFont.sourceSerif(24, weight: .semibold))
                    .foregroundStyle(Color.hDarkText)
                Text("The surah you'll memorise from.")
                    .font(HFont.body)
                    .foregroundStyle(Color.hSubtext)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SearchBar(text: $viewModel.searchText, placeholder: "Search surahs")

            if viewModel.isLoadingChapters {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.filteredChapters) { chapter in
                            SurahRowView(
                                chapter: chapter,
                                isSelected: viewModel.selectedChapter?.id == chapter.id
                            ) {
                                viewModel.selectedChapter = chapter
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, HSpacing.screenPadding)
        .task {
            await viewModel.loadChapters()
        }
    }
}

struct SurahRowView: View {
    let chapter: Chapter
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: HSpacing.md) {
                // Number badge
                Text("\(chapter.id)")
                    .font(HFont.captionMedium)
                    .foregroundStyle(Color.hOliveGreen)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .stroke(Color.hOliveGreen.opacity(0.3), lineWidth: 1)
                    )

                // Arabic name + transliteration
                VStack(alignment: .leading, spacing: 2) {
                    Text(chapter.nameArabic)
                        .font(HFont.amiriQuran(32))
                        .foregroundStyle(Color.hDarkText)

                    Text(chapter.nameSimple)
                        .font(HFont.caption)
                        .foregroundStyle(Color.hSubtext)
                }

                Spacer()

                // Ayat count + memorised
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(chapter.versesCount) ayat")
                        .font(HFont.captionMedium)
                        .foregroundStyle(Color.hDarkText)

                    Text("0% memorised")
                        .font(HFont.caption)
                        .foregroundStyle(Color.hSubtext)
                }
            }
            .padding(.vertical, HSpacing.md)
            .padding(.horizontal, HSpacing.md)
            .background(
                isSelected
                    ? Color.hOliveGreen.opacity(0.08)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
