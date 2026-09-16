import SwiftUI

struct ChallengeDetailView: View {
    let challenge: Challenge
    @Environment(\.dismiss) private var dismiss
    @State private var showStageView = false
    @State private var stageToOpen = 1
    @State private var showCompletion = false

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let lockColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let dividerColor = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.06)
    private let progressTrackColor = Color(red: 242/255, green: 238/255, blue: 231/255)

    private var stages: [StageType] {
        StageDefinitions.stages(for: challenge.templateType)
    }

    private var totalStages: Int { stages.count }

    private var completedStageCount: Int {
        if challenge.isCompleted { return totalStages }
        return max(0, challenge.currentStage - 1)
    }

    private var currentStage: StageType? {
        let idx = challenge.currentStage - 1
        guard idx >= 0, idx < stages.count else { return nil }
        return stages[idx]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Nav header
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.hDarkText)
                }

                Spacer()

                Text("Challenge")
                    .font(HFont.generalSans(13))
                    .foregroundStyle(subtextColor)
                    .tracking(0.3)

                Spacer()

                // Invisible spacer for balance
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 10)

            // Scrollable content
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    progressSection
                    stageList
                }
            }

            // Bottom button
            VStack(spacing: 0) {
                Rectangle().fill(dividerColor).frame(height: 1)

                if let stage = currentStage, !challenge.isCompleted {
                    Button {
                        openStage(challenge.currentStage)
                    } label: {
                        Text("Start Stage \(challenge.currentStage) · \(stage.title)")
                            .font(HFont.generalSans(17, weight: .medium))
                            .tracking(-0.2)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.hOliveGreen)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .background(Color.hCreamBg)
        }
        .background(Color.hCreamBg)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .fullScreenCover(isPresented: $showStageView) {
            NavigationStack {
                ChallengeStageView(
                    viewModel: ChallengeViewModel(
                        challenge: challenge,
                        stageNumber: stageToOpen
                    )
                )
            }
        }
        .fullScreenCover(isPresented: $showCompletion) {
            CompletionView(challenge: challenge)
        }
        .onChange(of: showStageView) { _, isShowing in
            if !isShowing && challenge.isCompleted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showCompletion = true
                }
            }
        }
    }

    private func openStage(_ number: Int) {
        stageToOpen = number
        showStageView = true
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            Text(ChapterNames.arabicName(for: challenge.surahId) ?? challenge.surahNameArabic)
                .font(HFont.amiriQuran(38))
                .foregroundStyle(Color.hDarkText)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, -14)

            Text("\(challenge.surahName) \(challenge.verseStart)–\(challenge.verseEnd)")
                .font(HFont.sourceSerif(24, weight: .regular))
                .foregroundStyle(Color.hDarkText)
                .tracking(-0.3)
                .padding(.bottom, 4)

            Text("\(templateName) · \(challenge.reciterName)")
                .font(HFont.generalSans(13))
                .foregroundStyle(subtextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    private var templateName: String {
        MemorizationTemplate.all.first { $0.id == challenge.templateType }?.name ?? "Standard"
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Progress")
                    .font(HFont.generalSans(13))
                    .foregroundStyle(subtextColor)
                Spacer()
                Text("\(completedStageCount) of \(totalStages) stages")
                    .font(HFont.generalSans(13))
                    .foregroundStyle(Color.hDarkText)
            }

            // Progress bar
            GeometryReader { geo in
                let progress = totalStages > 0
                    ? geo.size.width * CGFloat(completedStageCount) / CGFloat(totalStages)
                    : 0
                Capsule()
                    .fill(progressTrackColor)
                    .frame(height: 4)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(Color.hOliveGreen)
                            .frame(width: progress, height: 4)
                    }
                    .clipShape(Capsule())
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
    }

    // MARK: - Stage List

    private var stageList: some View {
        VStack(spacing: 8) {
            ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                let status = stageStatus(for: index)
                stageRow(stage: stage, index: index, status: status)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private enum StageStatus {
        case completed, current, locked
    }

    private func stageStatus(for index: Int) -> StageStatus {
        if challenge.isCompleted { return .completed }
        if index < challenge.currentStage - 1 { return .completed }
        if index == challenge.currentStage - 1 { return .current }
        return .locked
    }

    @ViewBuilder
    private func stageRow(stage: StageType, index: Int, status: StageStatus) -> some View {
        switch status {
        case .current:
            currentStageRow(stage: stage, index: index)
        case .completed:
            completedStageRow(stage: stage, index: index)
        case .locked:
            lockedStageRow(stage: stage, index: index)
        }
    }

    // MARK: - Current Stage Row

    private func currentStageRow(stage: StageType, index: Int) -> some View {
        Button {
            openStage(index + 1)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                // Number circle
                ZStack {
                    Circle()
                        .stroke(Color.hOliveGreen, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                    Text("\(index + 1)")
                        .font(HFont.generalSans(13))
                        .foregroundStyle(Color.hOliveGreen)
                }

                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(stage.title)
                        .font(HFont.generalSans(16, weight: .medium))
                        .foregroundStyle(Color.hDarkText)
                        .tracking(-0.1)
                    Text(stage.subtitle)
                        .font(HFont.generalSans(13))
                        .foregroundStyle(subtextColor)
                        .lineSpacing(2)
                }
                .padding(.top, 4)

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.hOliveGreen)
                    .padding(.top, 8)
            }
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.hOliveGreen, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Completed Stage Row

    private func completedStageRow(stage: StageType, index: Int) -> some View {
        Button {
            openStage(index + 1)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                // Checkmark circle
                ZStack {
                    Circle()
                        .fill(Color.hOliveGreen)
                        .frame(width: 32, height: 32)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(stage.title)
                        .font(HFont.generalSans(16, weight: .medium))
                        .foregroundStyle(Color.hDarkText)
                        .tracking(-0.1)
                    Text(stage.subtitle)
                        .font(HFont.generalSans(13))
                        .foregroundStyle(subtextColor)
                        .lineSpacing(2)
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Locked Stage Row

    private func lockedStageRow(stage: StageType, index: Int) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Lock circle
            ZStack {
                Circle()
                    .stroke(Color.hDarkText.opacity(0.08), lineWidth: 1.5)
                    .frame(width: 32, height: 32)
                Image(systemName: "lock")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(lockColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(stage.title)
                        .font(HFont.generalSans(16))
                        .foregroundStyle(Color.hDarkText)
                        .tracking(-0.1)

                    if stage.isGate {
                        Text("GATE")
                            .font(HFont.generalSans(10, weight: .medium))
                            .foregroundStyle(Color(red: 184/255, green: 112/255, blue: 77/255))
                            .tracking(0.3)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(red: 184/255, green: 112/255, blue: 77/255).opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Text(stage.subtitle)
                    .font(HFont.generalSans(13))
                    .foregroundStyle(subtextColor)
                    .lineSpacing(2)
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(16)
        .opacity(0.5)
    }
}
