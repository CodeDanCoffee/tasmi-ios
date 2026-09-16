import SwiftUI

struct ChallengeStageView: View {
    @Bindable var viewModel: ChallengeViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var auth
    @State private var journeyVM = JourneyViewModel()
    @State private var showStageComplete = false
    @State private var showNeededHelpSheet = false
    @State private var showNeedsWorkSheet = false
    @State private var isLoadingAudio = false
    @State private var showFirstWordsInline = false
    @State private var showPrayerInputSheet = false
    @State private var editingPrayerIndex: Int? = nil
    @State private var showExitConfirmation = false
    /// Built on appear for the share stage — it needs the challenge, which
    /// isn't available at `@State` initialisation.
    @State private var composeVM: ComposeReflectionViewModel?

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let dividerColor = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.06)
    private let progressTrackColor = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.06)

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Text("STAGE \(viewModel.displayStage) · ACTIVITY \(viewModel.currentActivity)/\(viewModel.totalActivities)")
                        .font(HFont.generalSans(12))
                        .foregroundStyle(subtextColor)
                        .tracking(0.5)

                    Spacer()

                    Button { showExitConfirmation = true } label: {
                        ZStack {
                            Circle()
                                .fill(Color.hDarkText.opacity(0.04))
                                .frame(width: 36, height: 36)
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.hDarkText)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 10)

                // Progress bar
                GeometryReader { geo in
                    let progress = geo.size.width * CGFloat(viewModel.currentActivity) / CGFloat(viewModel.totalActivities)
                    Capsule()
                        .fill(progressTrackColor)
                        .frame(height: 4)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(Color.hOliveGreen)
                                .frame(width: progress, height: 4)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.currentActivity)
                        }
                        .clipShape(Capsule())
                }
                .frame(height: 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            // Stage content
            ScrollView {
                stageContent
            }

            // Bottom action
            VStack(spacing: 0) {
                Rectangle().fill(dividerColor).frame(height: 1)

                stageAction
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
            }
            .background(Color.hCreamBg)
        }
        .background(Color.hCreamBg)
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $showPrayerInputSheet) {
            PrayerInputSheet(
                viewModel: viewModel,
                editingIndex: editingPrayerIndex,
                onDismiss: {
                    showPrayerInputSheet = false
                    editingPrayerIndex = nil
                }
            )
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.hidden)
        }
        .overlay {
            if showStageComplete {
                stageCompleteOverlay
            }
        }
        .overlay {
            if showNeededHelpSheet {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.22)) {
                            showNeededHelpSheet = false
                        }
                    }

                VStack {
                    Spacer()
                    neededHelpSheet
                }
                .transition(.move(edge: .bottom))
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .animation(.interpolatingSpring(duration: 0.22, bounce: 0.05), value: showNeededHelpSheet)
        .overlay {
            if showNeedsWorkSheet {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.22)) {
                            showNeedsWorkSheet = false
                        }
                    }

                VStack {
                    Spacer()
                    needsWorkSheet
                }
                .transition(.move(edge: .bottom))
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .animation(.interpolatingSpring(duration: 0.22, bounce: 0.05), value: showNeedsWorkSheet)
        .task {
            await viewModel.loadAudio()
            await viewModel.loadTranslations()
        }
        .onAppear {
            if viewModel.currentStageType == .listenOnly {
                viewModel.onLastAyahCompleted = { [self] in
                    finishActivity()
                }
            }
            if viewModel.currentStageType == .shareReflection, composeVM == nil {
                composeVM = ComposeReflectionViewModel(challenge: viewModel.challenge)
            }
        }
        .onChange(of: viewModel.currentActivity) { _, newActivity in
            if newActivity == 2 && viewModel.currentStageType == .listenWithText {
                Task {
                    await viewModel.loadTranslations()
                }
            }
            // Re-set callback when advancing to activity 2 (harder gap fill)
            if viewModel.currentStageType == .listenOnly {
                viewModel.onLastAyahCompleted = { [self] in
                    finishActivity()
                }
            }
        }
        .alert("Leave this stage?", isPresented: $showExitConfirmation) {
            Button("Leave", role: .destructive) { dismiss() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your progress on this activity won\u{2019}t be saved.")
        }
    }

    @ViewBuilder
    private var stageContent: some View {
        switch viewModel.currentStageType {
        case .listenWithText:
            switch viewModel.currentActivity {
            case 2:
                TranslationMatchView(viewModel: viewModel)
            case 3:
                TranslationMatchGameView(viewModel: viewModel)
            default:
                ListenStageView(viewModel: viewModel, showText: true)
            }
        case .listenOnly:
            switch viewModel.currentActivity {
            case 1:
                GapFillView(viewModel: viewModel, mode: .warmUp)
            default:
                GapFillView(viewModel: viewModel, mode: .harder)
            }
        case .readWithHints:
            ReadStageView(viewModel: viewModel, showHints: true)
        case .readFromMemory:
            switch viewModel.currentActivity {
            case 1:
                TransitionDrillView(viewModel: viewModel)
            default:
                FirstWordCascadeView(viewModel: viewModel)
            }
        case .write:
            switch viewModel.currentActivity {
            case 1:
                ContinueFromHereView(viewModel: viewModel)
            default:
                RandomDropInView(viewModel: viewModel)
            }
        case .recite:
            ReciteStageView(viewModel: viewModel)
        case .prayerCount:
            PrayerCountView(viewModel: viewModel) { index in
                editingPrayerIndex = index
                showPrayerInputSheet = true
            }
        case .shareReflection:
            if let composeVM {
                ShareReflectionView(viewModel: composeVM)
            }
        }
    }

    @ViewBuilder
    private var stageAction: some View {
        switch viewModel.currentStageType {
        case .listenWithText:
            if viewModel.currentActivity == 2 {
                Button {
                    finishActivity()
                } label: {
                    Text("I\u{2019}ve read them. Continue")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.hOliveGreen)
                        .clipShape(Capsule())
                }
            } else if viewModel.currentActivity == 3 {
                Button {
                    finishActivity()
                } label: {
                    Text("Continue")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(viewModel.allTranslationsMatched
                            ? Color.hOliveGreen
                            : Color.hOliveGreen.opacity(0.35))
                        .clipShape(Capsule())
                }
                .disabled(!viewModel.allTranslationsMatched)
            } else {
                Button {
                    finishActivity()
                } label: {
                    Text("Finish activity")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(viewModel.audioService.isSequentialComplete
                            ? Color.hOliveGreen
                            : Color.hOliveGreen.opacity(0.4))
                        .clipShape(Capsule())
                }
                .disabled(!viewModel.audioService.isSequentialComplete)
            }

        case .listenOnly:
            if viewModel.gapFillChecked && !viewModel.allGapsCorrect {
                // Retry (some answers wrong — auto-checked)
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.retryGapAyah()
                    }
                } label: {
                    Text("Retry")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.hOliveGreen)
                        .clipShape(Capsule())
                }
            } else {
                // Empty spacer — auto-advances on correct answers
                EmptyView()
            }

        case .readWithHints:
            HStack(spacing: 10) {
                Button {
                    withAnimation(.interpolatingSpring(duration: 0.22, bounce: 0.05)) {
                        showNeededHelpSheet = true
                    }
                } label: {
                    Text("Needed help")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(Color.hDarkText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .overlay(
                            Capsule()
                                .stroke(Color.hDarkText.opacity(0.08), lineWidth: 1)
                        )
                }

                Button {
                    recordAndAdvance()
                } label: {
                    Text("I got through")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.hOliveGreen)
                        .clipShape(Capsule())
                }
            }

        case .readFromMemory:
            if viewModel.currentActivity == 1 {
                // Transition drill buttons
                if !viewModel.isTransitionRevealed {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.revealTransition()
                        }
                    } label: {
                        Text("Reveal next word")
                            .font(HFont.generalSans(17, weight: .medium))
                            .tracking(-0.2)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.hOliveGreen)
                            .clipShape(Capsule())
                    }
                } else if !viewModel.isLastTransition {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.advanceTransition()
                        }
                    } label: {
                        Text("Next transition")
                            .font(HFont.generalSans(17, weight: .medium))
                            .tracking(-0.2)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.hOliveGreen)
                            .clipShape(Capsule())
                    }
                } else {
                    Button {
                        finishActivity()
                    } label: {
                        Text("Continue")
                            .font(HFont.generalSans(17, weight: .medium))
                            .tracking(-0.2)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.hOliveGreen)
                            .clipShape(Capsule())
                    }
                }
            } else {
                // Activity 2: first-word cascade
                HStack(spacing: 10) {
                    Button {
                        recordAndAdvance()
                    } label: {
                        Text("Skip")
                            .font(HFont.generalSans(17, weight: .medium))
                            .tracking(-0.2)
                            .foregroundStyle(Color.hDarkText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .overlay(
                                Capsule()
                                    .stroke(Color.hDarkText.opacity(0.08), lineWidth: 1)
                            )
                    }

                    Button {
                        recordAndAdvance()
                    } label: {
                        Text("\(viewModel.cascadeVerifiedCount) of \(viewModel.verses.count) verified")
                            .font(HFont.generalSans(17, weight: .medium))
                            .tracking(-0.2)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(viewModel.allCascadeVerified
                                ? Color.hOliveGreen
                                : Color.hOliveGreen.opacity(0.35))
                            .clipShape(Capsule())
                    }
                    .disabled(!viewModel.allCascadeVerified)
                }
            }

        case .write:
            if viewModel.currentActivity == 1 && viewModel.continueFromNotePhase {
                // Phase 5: Note
                Button {
                    finishActivity()
                } label: {
                    Text("Save & continue to activity 2")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.hOliveGreen)
                        .clipShape(Capsule())
                }
            } else if viewModel.currentActivity == 1 && viewModel.continueFromStumblePhase {
                // Phase 4: Stumble review
                Button {
                    finishActivity()
                } label: {
                    Text("Done \u{2014} continue to activity 2")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.hOliveGreen)
                        .clipShape(Capsule())
                }
            } else if viewModel.currentActivity == 1 && !viewModel.continueFromMemoryPhase && !viewModel.continueFromVerificationPhase {
                // Phase 1: Audio playing
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.continueFromMemoryPhase = true
                    }
                } label: {
                    Text("Audio stopped \u{2014} I\u{2019}ll continue")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(viewModel.audioService.isSequentialComplete
                            ? Color.hOliveGreen
                            : Color.hOliveGreen.opacity(0.35))
                        .clipShape(Capsule())
                }
                .disabled(!viewModel.audioService.isSequentialComplete)
            } else if viewModel.currentActivity == 1 && viewModel.continueFromMemoryPhase && !viewModel.continueFromVerificationPhase {
                // Phase 2: Memory recitation
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.continueFromMemoryPhase = false
                        viewModel.continueFromVerificationPhase = true
                    }
                } label: {
                    Text("I finished")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.hOliveGreen)
                        .clipShape(Capsule())
                }
            } else if viewModel.currentActivity == 1 && viewModel.continueFromVerificationPhase {
                // Phase 3: Verification
                HStack(spacing: 10) {
                    Button {
                        withAnimation(.interpolatingSpring(duration: 0.22, bounce: 0.05)) {
                            showNeedsWorkSheet = true
                        }
                    } label: {
                        Text("Needs work")
                            .font(HFont.generalSans(17, weight: .medium))
                            .tracking(-0.2)
                            .foregroundStyle(Color.hDarkText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .overlay(
                                Capsule()
                                    .stroke(Color.hDarkText.opacity(0.08), lineWidth: 1)
                            )
                    }

                    Button {
                        finishActivity()
                    } label: {
                        Text("Continue to activity 2")
                            .font(HFont.generalSans(17, weight: .medium))
                            .tracking(-0.2)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.hOliveGreen)
                            .clipShape(Capsule())
                    }
                }
            } else if viewModel.dropInPhase == .cue {
                // Activity 2: Random drop-in — cue phase
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.audioService.stop()
                        viewModel.dropInPhase = .recite
                    }
                } label: {
                    Text("Cue ended \u{2014} I\u{2019}ll continue")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(viewModel.audioService.isSequentialComplete
                            ? Color.hOliveGreen
                            : Color.hOliveGreen.opacity(0.35))
                        .clipShape(Capsule())
                }
                .disabled(!viewModel.audioService.isSequentialComplete)
            } else if viewModel.dropInPhase == .recite {
                // Activity 2: Random drop-in — recite phase
                HStack(spacing: 10) {
                    Button {
                        withAnimation(.interpolatingSpring(duration: 0.22, bounce: 0.05)) {
                            showNeededHelpSheet = true
                        }
                    } label: {
                        Text("I\u{2019}m stuck")
                            .font(HFont.generalSans(17, weight: .medium))
                            .tracking(-0.2)
                            .foregroundStyle(Color.hDarkText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .overlay(
                                Capsule()
                                    .stroke(Color.hDarkText.opacity(0.08), lineWidth: 1)
                            )
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.dropInPhase = .review
                        }
                    } label: {
                        Text("I finished")
                            .font(HFont.generalSans(17, weight: .medium))
                            .tracking(-0.2)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.hOliveGreen)
                            .clipShape(Capsule())
                    }
                }
            } else {
                // Activity 2: Random drop-in — review phase
                Button {
                    if viewModel.dropInAttempts >= viewModel.dropInMaxAttempts - 1 {
                        viewModel.dropInAttempts += 1
                        recordAndAdvance()
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.advanceDropInAttempt()
                        }
                    }
                } label: {
                    Text("Try a new drop-in")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.hOliveGreen)
                        .clipShape(Capsule())
                }
            }

        case .recite:
            if !viewModel.chainStarted {
                // Initial state — begin the chain
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.beginChain()
                    }
                } label: {
                    Text("Begin chain")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.hOliveGreen)
                        .clipShape(Capsule())
                }
            } else if viewModel.isChainComplete {
                // All rounds done
                Button {
                    recordAndAdvance()
                } label: {
                    Text("Continue")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.hOliveGreen)
                        .clipShape(Capsule())
                }
            } else {
                // During a round — confirm last completed round
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.advanceChainRound()
                    }
                } label: {
                    Text("I got through round \(viewModel.lastCompletedRound)\u{2014} next")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.hOliveGreen)
                        .clipShape(Capsule())
                }
            }

        case .prayerCount:
            if viewModel.canCompletePrayerStage {
                Button {
                    recordAndAdvance()
                } label: {
                    Text("Complete challenge")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.hOliveGreen)
                        .clipShape(Capsule())
                }
            } else {
                Button {
                    editingPrayerIndex = nil
                    showPrayerInputSheet = true
                } label: {
                    Text("I recited it in a prayer")
                        .font(HFont.generalSans(17, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.hOliveGreen)
                        .clipShape(Capsule())
                }
            }

        case .shareReflection:
            shareReflectionAction
        }
    }

    @ViewBuilder
    private var shareReflectionAction: some View {
        let hasPublished = composeVM?.didPublish == true
        let isSubmitting = composeVM?.isSubmitting == true

        VStack(spacing: 10) {
            Button {
                Task { await publishReflection() }
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text(hasPublished ? "Complete challenge" : "Share reflection")
                            .font(HFont.generalSans(17, weight: .medium))
                            .tracking(-0.2)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(canShareReflection ? Color.hOliveGreen : Color.hOliveGreen.opacity(0.35))
                .clipShape(Capsule())
            }
            .disabled(!canShareReflection || isSubmitting)
        }
    }

    private var canShareReflection: Bool {
        guard let composeVM else { return false }
        return composeVM.didPublish || composeVM.canSubmit
    }

    private func publishReflection() async {
        guard let composeVM else { return }

        if composeVM.didPublish {
            recordAndAdvance()
            return
        }

        await composeVM.submit(auth: auth)

        if composeVM.didPublish {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private var isDropInContext: Bool {
        viewModel.currentStageType == .write && viewModel.currentActivity == 2
    }

    private var isChainContext: Bool {
        viewModel.currentStageType == .recite && viewModel.chainStarted
    }

    private func finishActivity() {
        if viewModel.currentActivity < viewModel.totalActivities {
            // Reset gap fill state when transitioning between gap fill activities
            if viewModel.currentStageType == .listenOnly {
                viewModel.ayahGaps = []
                viewModel.resetGapAyahState()
            }
            // Reset transition drill state when finishing Activity 1
            if viewModel.currentStageType == .readFromMemory {
                viewModel.currentTransitionIndex = 0
                viewModel.isTransitionRevealed = false
            }
            // Reset audio state when finishing continue-from-here
            if viewModel.currentStageType == .write {
                viewModel.audioService.stop()
            }
            viewModel.currentActivity += 1
            viewModel.audioService.resetForNextActivity()
        } else {
            recordAndAdvance()
        }
    }

    private func recordAndAdvance() {
        journeyVM.recordStageCompletion(
            challenge: viewModel.challenge,
            stage: viewModel.challenge.currentStage,
            context: modelContext
        )
        viewModel.advanceStage()

        withAnimation(.easeInOut(duration: 0.3)) {
            showStageComplete = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }

    // MARK: - Needed Help Sheet

    private var neededHelpSheet: some View {
        let challenge = viewModel.challenge
        let ayahLabel = challenge.verseStart == challenge.verseEnd
            ? "ayah \(challenge.verseStart)"
            : "ayahs \(challenge.verseStart)\u{2013}\(challenge.verseEnd)"
        let totalSeconds = challenge.verseCount * 8
        let estDuration = "\(totalSeconds / 60):\(String(format: "%02d", totalSeconds % 60))"
        let iconBg = Color(red: 233/255, green: 236/255, blue: 227/255)
        let mutedColor = Color(red: 168/255, green: 160/255, blue: 152/255)

        return VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.hDarkText.opacity(0.08))
                .frame(width: 40, height: 4)
                .padding(.bottom, 18)

            // Title
            Text("That\u{2019}s alright.")
                .font(.system(size: 22, design: .serif))
                .foregroundStyle(Color.hDarkText)
                .tracking(-0.3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

            // Subtitle
            Text("Take a breath. Pick what would help \u{2014} there\u{2019}s no penalty.")
                .font(HFont.generalSans(13))
                .foregroundStyle(subtextColor)
                .lineSpacing(13 * 0.3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 18)

            // Options
            VStack(spacing: 8) {
                hearAyahsOption(
                    ayahLabel: ayahLabel,
                    reciterName: challenge.reciterName,
                    estDuration: estDuration,
                    iconBg: iconBg
                )

                firstWordsOption(iconBg: iconBg)

                helpOption(
                    icon: {
                        Text("\u{21BA}")
                            .font(.system(size: 16))
                    },
                    iconBg: iconBg,
                    title: "Redo this stage",
                    subtitle: "Start the recitation over"
                ) {
                    if isDropInContext {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.dropInPhase = .cue
                        }
                        Task {
                            await viewModel.startDropInCueAudio()
                        }
                    } else if isChainContext {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.chainCurrentRound = 0
                        }
                    } else {
                        viewModel.redoReciteStage()
                    }
                    withAnimation(.easeOut(duration: 0.22)) { showNeededHelpSheet = false }
                }
            }

            // Continue anyway
            VStack(spacing: 4) {
                Button {
                    withAnimation(.easeOut(duration: 0.22)) { showNeededHelpSheet = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        if isDropInContext {
                            if viewModel.dropInAttempts >= viewModel.dropInMaxAttempts - 1 {
                                viewModel.dropInAttempts += 1
                                recordAndAdvance()
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.advanceDropInAttempt()
                                }
                            }
                        } else if isChainContext {
                            recordAndAdvance()
                        } else {
                            recordAndAdvance()
                        }
                    }
                } label: {
                    Text("Continue anyway \u{00B7} mark for review")
                        .font(HFont.generalSans(14))
                        .foregroundStyle(subtextColor)
                        .underline()
                }

                Text("These ayahs will surface sooner in your review deck")
                    .font(HFont.generalSans(11))
                    .foregroundStyle(mutedColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
        }
        .padding(.top, 12)
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
        .background(Color(red: 250/255, green: 247/255, blue: 242/255))
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 15, y: -8)
    }

    @ViewBuilder
    private func helpOption<Icon: View>(
        @ViewBuilder icon: () -> Icon,
        iconBg: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconBg)
                        .frame(width: 36, height: 36)
                    icon()
                        .foregroundStyle(Color.hOliveGreen)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(HFont.generalSans(15, weight: .medium))
                        .foregroundStyle(Color.hDarkText)
                    Text(subtitle)
                        .font(HFont.generalSans(12))
                        .foregroundStyle(subtextColor)
                }

                Spacer()
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.hDarkText.opacity(0.08), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func hearAyahsOption(
        ayahLabel: String,
        reciterName: String,
        estDuration: String,
        iconBg: Color
    ) -> some View {
        let isPlaying = viewModel.audioService.isPlaying
        let isPaused = viewModel.audioService.isSequentialMode && !isPlaying && !viewModel.audioService.isSequentialComplete

        HStack(spacing: 14) {
            Button {
                if viewModel.audioService.isSequentialMode {
                    viewModel.audioService.toggleSequential()
                } else {
                    isLoadingAudio = true
                    Task {
                        await viewModel.loadAndPlayAudioSoftly()
                        isLoadingAudio = false
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(iconBg)
                        .frame(width: 36, height: 36)

                    if isLoadingAudio {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(Color.hOliveGreen)
                    } else {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.hOliveGreen)
                            .offset(x: isPlaying ? 0 : 1)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Hear \(ayahLabel) once more")
                    .font(HFont.generalSans(15, weight: .medium))
                    .foregroundStyle(Color.hDarkText)

                if isPlaying {
                    Text("Playing softly\u{2026}")
                        .font(HFont.generalSans(12))
                        .foregroundStyle(Color.hOliveGreen)
                } else if isPaused {
                    Text("Paused \u{00B7} tap to resume")
                        .font(HFont.generalSans(12))
                        .foregroundStyle(subtextColor)
                } else {
                    Text("\(reciterName) \u{00B7} ~\(estDuration)")
                        .font(HFont.generalSans(12))
                        .foregroundStyle(subtextColor)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.hDarkText.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func firstWordsOption(iconBg: Color) -> some View {
        let isExpanded = showFirstWordsInline
        let warmBeige = Color(red: 242/255, green: 238/255, blue: 231/255)

        VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.22)) {
                    showFirstWordsInline.toggle()
                }
                if !viewModel.showFirstWords {
                    viewModel.showFirstWords = true
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(iconBg)
                            .frame(width: 36, height: 36)
                        Text("\u{0627}")
                            .font(HFont.amiriQuran(16))
                            .foregroundStyle(Color.hOliveGreen)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reveal each ayah")
                            .font(HFont.generalSans(15, weight: .medium))
                            .foregroundStyle(Color.hDarkText)
                        Text("See the full text of each ayah")
                            .font(HFont.generalSans(12))
                            .foregroundStyle(subtextColor)
                    }

                    Spacer()
                }
                .padding(14)
            }

            if isExpanded {
                firstWordsGrid
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(warmBeige)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isExpanded ? Color.hOliveGreen : Color.hDarkText.opacity(0.08), lineWidth: 1)
        )
    }

    private var firstWordsGrid: some View {
        let ayahs: [(Int, String)] = viewModel.verses.map { verse in
            (verse.verseNumber, verse.textUthmani.cleanArabic)
        }

        return VStack(spacing: 14) {
            ForEach(ayahs, id: \.0) { number, text in
                VStack(spacing: 4) {
                    Text("\(number).")
                        .font(HFont.generalSans(11))
                        .foregroundStyle(Color(red: 168/255, green: 160/255, blue: 152/255))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text(text)
                        .font(HFont.amiriQuran(20))
                        .foregroundStyle(Color.hDarkText)
                        .multilineTextAlignment(.trailing)
                        .lineSpacing(10)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Needs Work Sheet

    private var needsWorkSheet: some View {
        let iconBg = Color(red: 233/255, green: 236/255, blue: 227/255)
        let mutedColor = Color(red: 168/255, green: 160/255, blue: 152/255)

        return VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.hDarkText.opacity(0.08))
                .frame(width: 40, height: 4)
                .padding(.bottom, 18)

            // Title
            Text("That\u{2019}s alright.")
                .font(.system(size: 22, design: .serif))
                .foregroundStyle(Color.hDarkText)
                .tracking(-0.3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

            // Subtitle
            Text("What would help most?")
                .font(HFont.generalSans(13))
                .foregroundStyle(subtextColor)
                .lineSpacing(13 * 0.3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 18)

            // Options
            VStack(spacing: 8) {
                // 1. Hear it once, then try again
                helpOption(
                    icon: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                            .offset(x: 1)
                    },
                    iconBg: iconBg,
                    title: "Hear it once, then try again",
                    subtitle: "Replays the audio, then restarts your turn"
                ) {
                    withAnimation(.easeOut(duration: 0.22)) { showNeedsWorkSheet = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.retryContinueFrom()
                        }
                        Task {
                            await viewModel.startContinueFromAudio()
                        }
                    }
                }

                // 2. See where I stumbled
                helpOption(
                    icon: {
                        Image(systemName: "eye")
                            .font(.system(size: 13, weight: .medium))
                    },
                    iconBg: iconBg,
                    title: "See where I stumbled",
                    subtitle: "Shows the full text so you can compare"
                ) {
                    withAnimation(.easeOut(duration: 0.22)) { showNeedsWorkSheet = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.continueFromVerificationPhase = false
                            viewModel.continueFromStumblePhase = true
                        }
                    }
                }

                // 3. Add a short note
                helpOption(
                    icon: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                    },
                    iconBg: iconBg,
                    title: "Add a short note",
                    subtitle: "Jot down what tripped you up"
                ) {
                    withAnimation(.easeOut(duration: 0.22)) { showNeedsWorkSheet = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.continueFromVerificationPhase = false
                            viewModel.continueFromNotePhase = true
                        }
                    }
                }
            }

            // Continue anyway
            VStack(spacing: 4) {
                Button {
                    withAnimation(.easeOut(duration: 0.22)) { showNeedsWorkSheet = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        finishActivity()
                    }
                } label: {
                    Text("Continue anyway \u{00B7} mark for review")
                        .font(HFont.generalSans(14))
                        .foregroundStyle(subtextColor)
                        .underline()
                }

                Text("These ayahs will surface sooner in your review deck")
                    .font(HFont.generalSans(11))
                    .foregroundStyle(mutedColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
        }
        .padding(.top, 12)
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
        .background(Color(red: 250/255, green: 247/255, blue: 242/255))
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 15, y: -8)
    }

    private var stageCompleteOverlay: some View {
        ZStack {
            Color.hCreamBg.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: HSpacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.hOliveGreen)

                Text("Stage Complete!")
                    .font(HFont.heading)
                    .foregroundStyle(Color.hDarkText)
            }
            .scaleEffect(showStageComplete ? 1.0 : 0.7)
            .opacity(showStageComplete ? 1.0 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showStageComplete)
        }
    }
}

// MARK: - Flow Layout

private struct FirstWordsFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for (i, row) in rows.enumerated() {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight
            if i > 0 { height += spacing }
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for (i, row) in rows.enumerated() {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            if i > 0 { y += spacing }
            var x = bounds.minX
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubview]] = [[]]
        var currentWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentWidth += size.width + spacing
        }
        return rows
    }
}
