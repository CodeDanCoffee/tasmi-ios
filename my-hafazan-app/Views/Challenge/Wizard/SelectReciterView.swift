import SwiftUI

struct SelectReciterView: View {
    @Bindable var viewModel: ChallengeWizardViewModel

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Pick a reciter")
                    .font(HFont.sourceSerif(26, weight: .regular))
                    .foregroundStyle(Color.hDarkText)
                    .tracking(-0.4)
                Text("The voice you'll practice with. Pick one you'll stick with. Familiarity helps memorisation.")
                    .font(HFont.generalSans(14))
                    .foregroundStyle(subtextColor)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 16)

            if viewModel.isLoadingReciters {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.reciters) { reciter in
                            ReciterRowView(
                                reciter: reciter,
                                isSelected: viewModel.selectedReciter?.id == reciter.id,
                                isPreviewPlaying: viewModel.previewingReciterId == reciter.id && !viewModel.isLoadingPreview,
                                isPreviewLoading: viewModel.previewingReciterId == reciter.id && viewModel.isLoadingPreview,
                                onTap: {
                                    viewModel.selectedReciter = reciter
                                },
                                onPlayTap: {
                                    Task { await viewModel.togglePreview(for: reciter) }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .task {
            await viewModel.loadReciters()
        }
        .onDisappear {
            viewModel.stopPreview()
        }
    }
}

struct ReciterRowView: View {
    let reciter: Reciter
    let isSelected: Bool
    var isPreviewPlaying: Bool = false
    var isPreviewLoading: Bool = false
    let onTap: () -> Void
    var onPlayTap: (() -> Void)?

    // Design tokens
    private let selectedBg = Color(red: 233/255, green: 236/255, blue: 227/255)
    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Play button circle
                Button {
                    onPlayTap?()
                } label: {
                    ZStack {
                        Circle()
                            .fill(isPreviewPlaying ? Color.hOliveGreen : Color.hCreamBg)
                            .frame(width: 38, height: 38)
                        Circle()
                            .stroke(isPreviewPlaying ? Color.hOliveGreen : Color.hDarkText.opacity(0.08), lineWidth: 1)
                            .frame(width: 38, height: 38)

                        if isPreviewLoading {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: isPreviewPlaying ? "stop.fill" : "play.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(isPreviewPlaying ? .white : Color.hDarkText)
                                .offset(x: isPreviewPlaying ? 0 : 1)
                        }
                    }
                }
                .buttonStyle(.plain)

                // Name and style
                VStack(alignment: .leading, spacing: 2) {
                    Text(reciter.reciterName)
                        .font(HFont.generalSans(15))
                        .foregroundStyle(Color.hDarkText)
                    if let style = reciter.style, !style.isEmpty {
                        Text(style)
                            .font(HFont.generalSans(12))
                            .foregroundStyle(subtextColor)
                    }
                }

                Spacer()

                // Radio button
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
