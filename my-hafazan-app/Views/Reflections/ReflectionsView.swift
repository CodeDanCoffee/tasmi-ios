import SwiftUI

struct ReflectionsView: View {
    @Environment(AuthManager.self) private var auth
    @State private var viewModel = ReflectionsViewModel()

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let labelColor = Color(red: 168/255, green: 160/255, blue: 152/255)

    var body: some View {
        ZStack {
            Color.hCreamBg.ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(Color.hOliveGreen)
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    messageState(
                        icon: "exclamationmark.circle",
                        title: "Couldn\u{2019}t load reflections",
                        detail: errorMessage,
                        actionTitle: "Try again"
                    ) {
                        Task { await viewModel.refresh(auth: auth) }
                    }
                    Spacer()
                } else if viewModel.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    feedList
                }
            }
        }
        .navigationTitle("Reflections")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadIfNeeded(auth: auth) }
    }

    // MARK: - Feed

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.reflections) { reflection in
                    ReflectionCardView(reflection: reflection)
                    .task {
                        await viewModel.loadMoreIfNeeded(auth: auth, currentItem: reflection)
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(Color.hOliveGreen)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .refreshable {
            await viewModel.refresh(auth: auth)
        }
    }

    // MARK: - Empty / error states

    private var emptyState: some View {
        messageState(
            icon: "number",
            title: "No #Tasmi reflections yet",
            detail: "Finish a challenge and share what those ayahs left with you — it\u{2019}ll show up here.",
            actionTitle: nil,
            action: {}
        )
    }

    private func messageState(
        icon: String,
        title: String,
        detail: String,
        actionTitle: String?,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .fill(Color.hOliveGreen.opacity(0.25))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Color.hOliveGreen.opacity(0.5))
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.custom("Georgia", size: 20))
                    .foregroundStyle(Color.hDarkText)
                    .tracking(-0.3)

                Text(detail)
                    .font(HFont.generalSans(13))
                    .foregroundStyle(subtextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 40)

            if let actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(HFont.generalSans(14, weight: .medium))
                        .foregroundStyle(Color.hOliveGreen)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .overlay(
                            Capsule().stroke(Color.hOliveGreen.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
