import SwiftUI

/// Composes a QuranReflect post anchored to an ayah range.
struct ComposeReflectionSheet: View {
    @State var viewModel: ComposeReflectionViewModel

    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isEditorFocused: Bool

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let labelColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let cardBg = Color(red: 255/255, green: 253/255, blue: 248/255)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hCreamBg.ignoresSafeArea()

                if viewModel.didPublish {
                    publishedState
                } else {
                    composer
                }
            }
            .navigationTitle(viewModel.didPublish ? "" : "Share a reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !viewModel.didPublish {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .font(HFont.generalSans(15))
                            .foregroundStyle(subtextColor)
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            Task { await publish() }
                        } label: {
                            if viewModel.isSubmitting {
                                ProgressView().tint(Color.hOliveGreen)
                            } else {
                                Text(viewModel.isDraft ? "Save" : "Share")
                                    .font(HFont.generalSans(15, weight: .medium))
                            }
                        }
                        .disabled(!viewModel.canSubmit)
                        .foregroundStyle(viewModel.canSubmit ? Color.hOliveGreen : labelColor)
                    }
                }
            }
        }
    }

    private func publish() async {
        await viewModel.submit(auth: auth)
        if viewModel.didPublish {
            isEditorFocused = false
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    // MARK: - Composer

    private var composer: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    referenceChip

                    editor

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(HFont.generalSans(13))
                            .foregroundStyle(Color.hWeakRed)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    draftToggle
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isEditorFocused = true
            }
        }
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
                    .frame(minHeight: 200)
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

    private var draftToggle: some View {
        Toggle(isOn: $viewModel.isDraft) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Save as draft")
                    .font(HFont.generalSans(14, weight: .medium))
                    .foregroundStyle(Color.hDarkText)
                Text("Only you can see drafts")
                    .font(HFont.generalSans(11))
                    .foregroundStyle(subtextColor)
            }
        }
        .tint(Color.hOliveGreen)
        .padding(14)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Published

    private var publishedState: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .fill(Color.hOliveGreen.opacity(0.25))
                    .frame(width: 56, height: 56)
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Color.hOliveGreen)
            }
            .padding(.bottom, 20)

            Text(viewModel.isDraft ? "Saved as a draft." : "Shared.")
                .font(.custom("Georgia", size: 28).italic())
                .foregroundStyle(Color.hOliveGreen)
                .tracking(-0.3)
                .padding(.bottom, 10)

            Text(viewModel.isDraft
                 ? "You can publish it later from QuranReflect."
                 : "Your reflection now sits alongside \(viewModel.referenceLabel) for others reading these ayahs.")
                .font(HFont.generalSans(14))
                .foregroundStyle(subtextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(HFont.generalSans(17, weight: .medium))
                    .tracking(-0.2)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.hOliveGreen)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}
