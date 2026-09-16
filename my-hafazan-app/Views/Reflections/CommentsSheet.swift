import SwiftUI

/// Comments on a single reflection, opened from the comment button on a card.
struct CommentsSheet: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: CommentsViewModel
    @FocusState private var isComposerFocused: Bool

    /// Called with the new comment count after a successful post, so the card
    /// underneath can update its counter without refetching the feed.
    let onCommentPosted: (Int) -> Void

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let labelColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let cardBg = Color(red: 255/255, green: 253/255, blue: 248/255)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)

    init(postId: Int, onCommentPosted: @escaping (Int) -> Void) {
        _viewModel = State(initialValue: CommentsViewModel(postId: postId))
        self.onCommentPosted = onCommentPosted
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hCreamBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    content
                    composer
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.hCreamBg, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(HFont.generalSans(15, weight: .medium))
                        .foregroundStyle(Color.hOliveGreen)
                }
            }
        }
        .task { await viewModel.loadIfNeeded(auth: auth) }
    }

    // MARK: - List

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView().tint(Color.hOliveGreen)
            Spacer()
        } else if let errorMessage = viewModel.errorMessage {
            Spacer()
            emptyMessage(icon: "exclamationmark.circle", title: "Couldn\u{2019}t load comments", detail: errorMessage)
            Spacer()
        } else if viewModel.isEmpty {
            Spacer()
            emptyMessage(
                icon: "bubble.left",
                title: "No comments yet",
                detail: "Be the first to respond to this reflection."
            )
            Spacer()
        } else {
            list
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.comments) { comment in
                    commentRow(comment)
                        .task {
                            await viewModel.loadMoreIfNeeded(auth: auth, currentItem: comment)
                        }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(Color.hOliveGreen)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .refreshable { await viewModel.load(auth: auth) }
    }

    private func commentRow(_ comment: Comment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 9) {
                avatar(for: comment.author)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(comment.author?.displayName ?? "Someone")
                            .font(HFont.generalSans(13, weight: .medium))
                            .foregroundStyle(Color.hDarkText)
                            .lineLimit(1)

                        if comment.author?.verified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.hOliveGreen)
                        }
                    }

                    if let timestamp = comment.relativeTimestamp {
                        Text(timestamp)
                            .font(HFont.generalSans(10))
                            .foregroundStyle(labelColor)
                    }
                }

                Spacer()

                if let likes = comment.likesCount, likes > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                        Text("\(likes)")
                            .font(HFont.generalSans(11))
                    }
                    .foregroundStyle(labelColor)
                }
            }

            Text(comment.trimmedBody)
                .font(HFont.generalSans(14))
                .foregroundStyle(Color.hDarkText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14).stroke(cardBorder, lineWidth: 1)
        )
    }

    private func avatar(for author: ReflectionAuthor?) -> some View {
        ZStack {
            Circle()
                .fill(Color.hOliveGreen.opacity(0.12))
                .frame(width: 28, height: 28)

            if let url = author?.avatarURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initials(for: author)
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())
            } else {
                initials(for: author)
            }
        }
    }

    private func initials(for author: ReflectionAuthor?) -> some View {
        Text(author?.initials ?? "?")
            .font(HFont.generalSans(11, weight: .medium))
            .foregroundStyle(Color.hOliveGreen)
    }

    // MARK: - Composer

    private var composer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let submitError = viewModel.submitError {
                Text(submitError)
                    .font(HFont.generalSans(12))
                    .foregroundStyle(Color.hWeakRed)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .bottom, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    if viewModel.draft.isEmpty {
                        Text("Add a comment\u{2026}")
                            .font(HFont.generalSans(14))
                            .foregroundStyle(labelColor)
                            .padding(.top, 9)
                            .padding(.horizontal, 13)
                    }

                    TextEditor(text: $viewModel.draft)
                        .font(HFont.generalSans(14))
                        .foregroundStyle(Color.hDarkText)
                        .scrollContentBackground(.hidden)
                        .focused($isComposerFocused)
                        .frame(minHeight: 38, maxHeight: 110)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                }
                .background(cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12).stroke(cardBorder, lineWidth: 1)
                )

                Button {
                    Task { await post() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(viewModel.canSubmit ? Color.hOliveGreen : Color.hDarkText.opacity(0.12))
                            .frame(width: 38, height: 38)

                        if viewModel.isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canSubmit)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color.hCreamBg)
    }

    private func post() async {
        isComposerFocused = false
        if let newCount = await viewModel.submit(auth: auth) {
            onCommentPosted(newCount)
        }
    }

    // MARK: - Empty / error

    private func emptyMessage(icon: String, title: String, detail: String) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .fill(Color.hOliveGreen.opacity(0.25))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Color.hOliveGreen.opacity(0.5))
            }

            VStack(spacing: 5) {
                Text(title)
                    .font(.custom("Georgia", size: 18))
                    .foregroundStyle(Color.hDarkText)

                Text(detail)
                    .font(HFont.generalSans(13))
                    .foregroundStyle(subtextColor)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
        }
    }
}
