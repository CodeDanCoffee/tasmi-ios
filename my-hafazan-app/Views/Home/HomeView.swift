import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var auth
    @State private var viewModel = HomeViewModel()
    @State private var showWizard = false
    @State private var selectedChallenge: Challenge?
    @State private var showSettings = false

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let labelColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let cardBg = Color.white
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)

    var body: some View {
        ZStack {
            Color.hCreamBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                if viewModel.activeChallenges.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 28) {
                            activeChallengesSection

                            // Start another challenge
                            startAnotherCard
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showWizard) {
            ChallengeWizardView()
        }
        .navigationDestination(item: $selectedChallenge) { challenge in
            ChallengeDetailView(challenge: challenge)
        }
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            viewModel.load(context: modelContext)
        }
    }

    // MARK: - Header

    private var greetingName: String {
        if let custom = auth.displayName, !custom.isEmpty {
            return custom.split(separator: " ").first.map(String.init) ?? custom
        }
        if let name = auth.userName, !name.isEmpty {
            return name.split(separator: " ").first.map(String.init) ?? name
        }
        if let email = auth.userEmail,
           let local = email.split(separator: "@").first {
            return String(local).capitalized
        }
        return "Assalamualaikum"
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TODAY")
                    .font(HFont.generalSans(11, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(labelColor)

                Text(greetingName)
                    .font(.custom("Georgia", size: 36))
                    .foregroundStyle(Color.hDarkText)
                    .tracking(-0.3)
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.hDarkText)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white))
                    .overlay(Circle().stroke(Color.hDarkText.opacity(0.1), lineWidth: 1))
            }
        }
    }

    // MARK: - Active Challenges Section

    private var activeChallengesSection: some View {
        let challenges = viewModel.activeChallenges
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "scope")
                    .font(.system(size: 12))
                Text(challenges.count == 1 ? "ACTIVE CHALLENGE" : "ACTIVE CHALLENGES")
                    .font(HFont.generalSans(11, weight: .medium))
                    .tracking(0.5)
            }
            .foregroundStyle(labelColor)

            VStack(spacing: 12) {
                ForEach(challenges) { challenge in
                    Button {
                        selectedChallenge = challenge
                    } label: {
                        activeChallengeCard(challenge)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func activeChallengeCard(_ challenge: Challenge) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    // Arabic reference
                    (Text(challenge.surahNameArabic.isEmpty ? challenge.surahName : challenge.surahNameArabic)
                        .font(HFont.amiriQuran(22)) +
                    Text(" \(challenge.verseStart)-\(challenge.verseEnd)")
                        .font(.custom("Georgia", size: 20)))
                        .foregroundStyle(Color.hDarkText)
                        .padding(.bottom, 2)

                    // English name
                    Text("\(challenge.surahName) \(challenge.verseStart)\u{2013}\(challenge.verseEnd)")
                        .font(HFont.sourceSerif(20, weight: .semibold))
                        .foregroundStyle(Color.hDarkText)
                        .padding(.bottom, 4)

                    // Stage info
                    let stageType = StageType(rawValue: challenge.currentStage)
                    Text("Stage \(challenge.currentStage) \u{00B7} \(stageType?.title ?? "")")
                        .font(HFont.generalSans(13))
                        .foregroundStyle(subtextColor)
                }

                Spacer(minLength: 12)

                // Go button
                ZStack {
                    Circle()
                        .fill(Color.hDarkText)
                        .frame(width: 48, height: 48)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.bottom, 16)

            // Progress bar
            let totalStages = StageDefinitions.stageCount(for: challenge.templateType)
            let completed = challenge.currentStage - 1
            let fraction = Double(completed) / Double(totalStages)
            let percent = Int(fraction * 100)

            ProgressBarView(progress: fraction, height: 6)
                .padding(.bottom, 8)

            // Progress labels
            HStack {
                Text("\(completed) of \(totalStages) complete")
                    .font(HFont.generalSans(12))
                    .foregroundStyle(subtextColor)
                Spacer()
                Text("\(percent)%")
                    .font(HFont.generalSans(12, weight: .medium))
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

    // MARK: - Start Another Challenge

    private var startAnotherCard: some View {
        Button {
            showWizard = true
        } label: {
            HStack(spacing: 14) {
                // Plus icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Start another challenge")
                        .font(HFont.generalSans(15, weight: .medium))
                        .foregroundStyle(.white)

                    if let suggested = viewModel.suggestedNextRange {
                        Text("Recommendation: \(suggested)")
                            .font(HFont.generalSans(12))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            .padding(16)
            .background(Color.hDarkText)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.hOliveGreen.opacity(0.08))
                    .frame(width: 80, height: 80)
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                    .foregroundStyle(Color.hOliveGreen.opacity(0.4))
                    .frame(width: 64, height: 64)
                Image(systemName: "sun.max")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Color.hOliveGreen)
            }
            .padding(.bottom, 24)

            Text("Start your first challenge")
                .font(.custom("Georgia", size: 24))
                .foregroundStyle(Color.hDarkText)
                .tracking(-0.3)
                .padding(.bottom, 12)

            (Text("Pick a surah you want to memorise.\nTasmi will guide you through.\n") +
             Text("in Sha Allah.").italic())
                .font(HFont.generalSans(14))
                .foregroundStyle(subtextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, 32)

            Button {
                showWizard = true
            } label: {
                Text("Start a Challenge")
                    .font(HFont.generalSans(16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.hDarkText)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 20)
    }
}
