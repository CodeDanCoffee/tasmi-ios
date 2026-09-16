import SwiftUI

struct SelectTranslationView: View {
    @Bindable var viewModel: ChallengeWizardViewModel

    @State private var selectedLanguage: String?

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)

    var body: some View {
        VStack(spacing: 0) {
            header

            if viewModel.isLoadingTranslations && viewModel.translations.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if selectedLanguage == nil {
                languageList
            } else if let language = selectedLanguage {
                translationsList(language: language)
            }
        }
        .task {
            await viewModel.loadTranslations()
            // If the user already has a selection (e.g. coming back), open
            // straight to that language so they see what's currently chosen.
            if selectedLanguage == nil, let current = viewModel.selectedTranslation {
                selectedLanguage = current.languageName.capitalized
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedLanguage == nil ? "Pick a language" : "Pick a translation")
                .font(HFont.sourceSerif(26, weight: .regular))
                .foregroundStyle(Color.hDarkText)
                .tracking(-0.4)
            Text(selectedLanguage == nil
                 ? "Choose the language you read alongside the verses. Word-by-word meanings will be in this language too."
                 : "Pick the translation you want to read.")
                .font(HFont.generalSans(14))
                .foregroundStyle(subtextColor)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }

    // MARK: - Language list

    private var languageList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.availableLanguages, id: \.self) { language in
                    LanguageRow(
                        language: language,
                        count: viewModel.translations(forLanguage: language).count,
                        isCurrent: viewModel.selectedTranslation?.languageName.capitalized == language,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedLanguage = language
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Translations list

    private func translationsList(language: String) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedLanguage = nil
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("All languages")
                        .font(HFont.generalSans(13, weight: .medium))
                }
                .foregroundStyle(Color.hOliveGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
            .buttonStyle(.plain)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.translations(forLanguage: language)) { translation in
                        TranslationRow(
                            translation: translation,
                            isSelected: viewModel.selectedTranslation?.id == translation.id,
                            onTap: { viewModel.selectedTranslation = translation }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

private struct LanguageRow: View {
    let language: String
    let count: Int
    let isCurrent: Bool
    let onTap: () -> Void

    private let selectedBg = Color(red: 233/255, green: 236/255, blue: 227/255)
    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(language)
                        .font(HFont.generalSans(15))
                        .foregroundStyle(Color.hDarkText)
                    Text("\(count) translation\(count == 1 ? "" : "s")")
                        .font(HFont.generalSans(12))
                        .foregroundStyle(subtextColor)
                }
                Spacer()
                if isCurrent {
                    Text("Current")
                        .font(HFont.generalSans(12, weight: .medium))
                        .foregroundStyle(Color.hOliveGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.hOliveGreen.opacity(0.12)))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(subtextColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isCurrent ? selectedBg : .white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isCurrent ? Color.hOliveGreen : Color.hDarkText.opacity(0.08),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct TranslationRow: View {
    let translation: TranslationResource
    let isSelected: Bool
    let onTap: () -> Void

    private let selectedBg = Color(red: 233/255, green: 236/255, blue: 227/255)
    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(translation.name)
                        .font(HFont.generalSans(15))
                        .foregroundStyle(Color.hDarkText)
                        .multilineTextAlignment(.leading)
                    if let author = translation.authorName, !author.isEmpty, author != translation.name {
                        Text(author)
                            .font(HFont.generalSans(12))
                            .foregroundStyle(subtextColor)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer()

                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.hOliveGreen)
                            .frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Circle()
                            .stroke(Color.hDarkText.opacity(0.08), lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? selectedBg : .white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.hOliveGreen : Color.hDarkText.opacity(0.08),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
