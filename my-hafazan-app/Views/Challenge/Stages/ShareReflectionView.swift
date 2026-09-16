import SwiftUI

/// Final stage of every template: the user writes a reflection on the ayahs
/// they just memorised. Publishing attaches the `#tasmi` tag and the ayah range
/// as a QuranReflect reference, so the post lands both in the app's own feed
/// and alongside those verses on QuranReflect.
struct ShareReflectionView: View {
    @Bindable var viewModel: ComposeReflectionViewModel

    @FocusState private var isEditorFocused: Bool

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let labelColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let cardBg = Color(red: 255/255, green: 253/255, blue: 248/255)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.didPublish {
                publishedState
            } else {
                composer
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Composer

    private var composer: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            referenceChip
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

            editor
                .padding(.horizontal, 20)

            tagRow
                .padding(.horizontal, 20)
                .padding(.top, 14)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(HFont.generalSans(13))
                    .foregroundStyle(Color.hWeakRed)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .fill(Color.hDarkText.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "text.bubble")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Color.hDarkText.opacity(0.25))
            }
            .padding(.top, 8)
            .padding(.bottom, 20)

            Text("Share what stayed\nwith you.")
                .font(.custom("Georgia", size: 26))
                .foregroundStyle(Color.hDarkText)
                .tracking(-0.3)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, 14)

            Text("You've carried these ayahs through your salah. Write a line about what they left with you, and someone reading the same verses will find it.")
                .font(HFont.generalSans(14))
                .foregroundStyle(subtextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
    }

    private var referenceChip: some View {
        HStack(spacing: 10) {
            Image(systemName: "book.closed")
                .font(.system(size: 13))
                .foregroundStyle(Color.hOliveGreen)

            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.referenceLabel)
                    .font(HFont.generalSans(14, weight: .medium))
                    .foregroundStyle(Color.hDarkText)

                Text("Your reflection will appear on these ayahs")
                    .font(HFont.generalSans(11))
                    .foregroundStyle(subtextColor)
            }

            Spacer()

            if let arabic = viewModel.arabicSurahName {
                Text(arabic)
                    .font(HFont.amiriQuran(20))
                    .foregroundStyle(Color.hOliveGreen)
            }
        }
        .padding(14)
        .background(Color.hOliveGreen.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                if viewModel.text.isEmpty {
                    Text("What did these ayahs leave with you?")
                        .font(HFont.generalSans(15))
                        .foregroundStyle(labelColor)
                        .padding(.top, 12)
                        .padding(.horizontal, 14)
                }

                TextEditor(text: $viewModel.text)
                    .font(HFont.generalSans(15))
                    .foregroundStyle(Color.hDarkText)
                    .lineSpacing(5)
                    .scrollContentBackground(.hidden)
                    .focused($isEditorFocused)
                    .frame(minHeight: 180)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
            }
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(cardBorder, lineWidth: 1)
            )

            HStack {
                Spacer()
                Text(counterLabel)
                    .font(HFont.generalSans(11))
                    .foregroundStyle(labelColor)
            }
        }
    }

    private var counterLabel: String {
        let remaining = ComposeReflectionViewModel.minimumBodyLength - viewModel.characterCount
        return remaining > 0
            ? "\(remaining) more character\(remaining == 1 ? "" : "s")"
            : "\(viewModel.characterCount) characters"
    }

    /// Shows the tag that gets attached on publish, so it isn't a surprise.
    private var tagRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(HFont.generalSans(12, weight: .medium))
                    .foregroundStyle(Color.hOliveGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.hOliveGreen.opacity(0.09))
                    .clipShape(Capsule())
            }

            Text("added automatically")
                .font(HFont.generalSans(11))
                .foregroundStyle(labelColor)

            Spacer()
        }
    }

    // MARK: - Published

    private var publishedState: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .fill(Color.hOliveGreen.opacity(0.25))
                    .frame(width: 56, height: 56)
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Color.hOliveGreen)
            }
            .padding(.top, 60)
            .padding(.bottom, 20)

            Text("Shared.")
                .font(.custom("Georgia", size: 28).italic())
                .foregroundStyle(Color.hOliveGreen)
                .tracking(-0.3)
                .padding(.bottom, 10)

            Text("Your reflection now sits alongside \(viewModel.referenceLabel) for others reading these ayahs.")
                .font(HFont.generalSans(14))
                .foregroundStyle(subtextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
    }
}
