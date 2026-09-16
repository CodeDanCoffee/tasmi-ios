import SwiftUI
import SwiftData

struct ChallengeWizardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ChallengeWizardViewModel()
    @State private var createdChallenge: Challenge?

    var body: some View {
        VStack(spacing: 0) {
            // Header: back, step label, close
            HStack {
                if viewModel.currentStep > 1 {
                    Button {
                        viewModel.previousStep()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.hDarkText)
                    }
                } else {
                    // Placeholder for alignment
                    Color.clear.frame(width: 18, height: 18)
                }

                Spacer()

                Text("Step \(viewModel.currentStep) of \(viewModel.totalSteps)")
                    .font(HFont.generalSans(13))
                    .foregroundStyle(Color(red: 122/255, green: 114/255, blue: 106/255))
                    .tracking(0.3)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.hDarkText)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 18)

            // Progress bar
            GeometryReader { geo in
                let progress = geo.size.width * CGFloat(viewModel.currentStep) / CGFloat(viewModel.totalSteps)
                Capsule()
                    .fill(Color(red: 242/255, green: 238/255, blue: 231/255))
                    .frame(height: 4)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(Color.hOliveGreen)
                            .frame(width: progress, height: 4)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                    }
                    .clipShape(Capsule())
            }
            .frame(height: 4)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Content
            Group {
                switch viewModel.currentStep {
                case 1: SelectSurahView(viewModel: viewModel)
                case 2: SelectVersesView(viewModel: viewModel)
                case 3: SelectTemplateView(viewModel: viewModel)
                case 4: SelectReciterView(viewModel: viewModel)
                case 5: SelectTranslationView(viewModel: viewModel)
                case 6: ConfirmChallengeView(viewModel: viewModel)
                default: EmptyView()
                }
            }
            .frame(maxHeight: .infinity)

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(HFont.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, HSpacing.screenPadding)
            }

            // Bottom button
            Button {
                if viewModel.currentStep < viewModel.totalSteps {
                    viewModel.nextStep()
                } else {
                    Task {
                        if let challenge = await viewModel.createChallenge(context: modelContext) {
                            createdChallenge = challenge
                            dismiss()
                        }
                    }
                }
            } label: {
                let isLastStep = viewModel.currentStep == viewModel.totalSteps
                HStack(spacing: 8) {
                    if isLastStep && viewModel.isRebuildingVerses {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(isLastStep ? "Create Challenge" : "Continue")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                }
                .foregroundStyle(isLastStep ? .white : Color.hCreamBg)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(canProceed
                    ? (isLastStep ? Color.hOliveGreen : Color.hDarkText)
                    : Color.hDarkText.opacity(0.3))
                .clipShape(Capsule())
            }
            .disabled(!canProceed || viewModel.isRebuildingVerses)
            .padding(.horizontal, HSpacing.screenPadding)
            .padding(.bottom, HSpacing.lg)
        }
        .background(Color.hCreamBg)
        .navigationBarHidden(true)
        .toolbarVisibility(.hidden, for: .tabBar)
    }

    private var canProceed: Bool {
        switch viewModel.currentStep {
        case 1: return viewModel.canProceedToStep2
        case 2: return viewModel.canProceedToStep3
        case 3: return viewModel.canProceedToStep4
        case 4: return viewModel.canProceedToStep5
        case 5: return viewModel.canProceedToStep6
        default: return true
        }
    }
}
