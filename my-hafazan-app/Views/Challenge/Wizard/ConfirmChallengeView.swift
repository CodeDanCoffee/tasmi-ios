import SwiftUI

struct ConfirmChallengeView: View {
    @Bindable var viewModel: ChallengeWizardViewModel

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)
    private let cardShadow = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.03)
    private let dividerColor = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.06)

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Ready to begin")
                    .font(HFont.sourceSerif(26, weight: .regular))
                    .foregroundStyle(Color.hDarkText)
                    .tracking(-0.4)
                Text("Review your challenge before starting.")
                    .font(HFont.generalSans(14))
                    .foregroundStyle(subtextColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 20)

            // Summary card
            VStack(spacing: 0) {
                // Top section: icon + surah info
                VStack(spacing: 0) {
                    // Sun/compass icon
                    Image(systemName: "sun.min")
                        .font(.system(size: 22, weight: .ultraLight))
                        .foregroundStyle(Color.hOliveGreen)
                        .frame(width: 28, height: 28)
                        .padding(.top, 24)
                        .padding(.bottom, 10)

                    // Arabic name
                    if let chapter = viewModel.selectedChapter {
                        Text(ChapterNames.arabicName(for: chapter.id) ?? chapter.nameArabic)
                            .font(HFont.amiriQuran(30))
                            .foregroundStyle(Color.hDarkText)
                            .padding(.bottom, 4)

                        // English name + verse range
                        Text("\(chapter.nameSimple) \(viewModel.verseStart)–\(viewModel.verseEnd)")
                            .font(.custom("Georgia", size: 22))
                            .foregroundStyle(Color.hDarkText)
                            .tracking(-0.3)
                            .padding(.bottom, 4)

                        // Ayah count + translated name
                        let ayahCount = viewModel.verseEnd - viewModel.verseStart + 1
                        Text("\(ayahCount) ayahs · \(chapter.translatedName.name)")
                            .font(HFont.generalSans(13))
                            .foregroundStyle(subtextColor)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 18)

                // Divider
                Rectangle().fill(dividerColor).frame(height: 1)

                // Template row
                HStack {
                    Text("Template")
                        .font(HFont.generalSans(13))
                        .foregroundStyle(subtextColor)
                        .tracking(0.3)
                    Spacer()
                    Text("\(viewModel.selectedTemplate.name) · \(viewModel.selectedTemplate.stages.count) stages")
                        .font(HFont.generalSans(15))
                        .foregroundStyle(Color.hDarkText)
                }
                .padding(.vertical, 16)

                // Divider
                Rectangle().fill(dividerColor).frame(height: 1)

                // Reciter row
                if let reciter = viewModel.selectedReciter {
                    HStack {
                        Text("Reciter")
                            .font(HFont.generalSans(13))
                            .foregroundStyle(subtextColor)
                            .tracking(0.3)
                        Spacer()
                        Text(reciter.reciterName)
                            .font(HFont.generalSans(15))
                            .foregroundStyle(Color.hDarkText)
                    }
                    .padding(.vertical, 16)

                    // Divider
                    Rectangle().fill(dividerColor).frame(height: 1)
                }

                // Translation row
                if let translation = viewModel.selectedTranslation {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Translation")
                            .font(HFont.generalSans(13))
                            .foregroundStyle(subtextColor)
                            .tracking(0.3)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(translation.name)
                                .font(HFont.generalSans(15))
                                .foregroundStyle(Color.hDarkText)
                                .multilineTextAlignment(.trailing)
                            Text(translation.languageName.capitalized)
                                .font(HFont.generalSans(12))
                                .foregroundStyle(subtextColor)
                        }
                    }
                    .padding(.vertical, 16)

                    // Divider
                    Rectangle().fill(dividerColor).frame(height: 1)
                }

                // Stage ready indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.hOliveGreen)
                        .frame(width: 6, height: 6)
                    Text("Stage 1 is ready now.")
                        .font(HFont.generalSans(13))
                        .foregroundStyle(Color.hOliveGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(cardBorder, lineWidth: 1)
            )
            .shadow(color: cardShadow, radius: 0, x: 0, y: 1)
            .padding(.horizontal, 20)

            // Encouragement text
            Text("Take your time. You'll move through seven gentle stages, each unlocking the next.")
                .font(HFont.generalSans(13))
                .foregroundStyle(subtextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 26)
                .padding(.top, 18)

            Spacer()
        }
    }
}
