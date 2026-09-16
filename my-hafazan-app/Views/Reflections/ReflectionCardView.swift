import SwiftUI

struct ReflectionCardView: View {
    let reflection: Reflection

    @Environment(AuthManager.self) private var auth

    @State private var isExpanded = false
    @State private var showComments = false

    /// Set once the user acts on this card. Until then the feed's own values
    /// are shown, so a card the user hasn't touched always reflects the server.
    @State private var likedOverride: Bool?
    @State private var likesOverride: Int?
    @State private var commentsOverride: Int?

    private let labelColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let cardBg = Color(red: 255/255, green: 253/255, blue: 248/255)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)

    private let collapsedLineLimit = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            authorRow

            if let reference = reflection.references?.first {
                referenceChip(reference)
            }

            bodyText

            actionRow
        }
        .padding(18)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorder, lineWidth: 1)
        )
        .sheet(isPresented: $showComments) {
            CommentsSheet(postId: reflection.id) { newCount in
                commentsOverride = newCount
            }
        }
    }

    // MARK: - Likes & comments

    private var isLiked: Bool { likedOverride ?? reflection.isLiked ?? false }
    private var likesCount: Int { likesOverride ?? reflection.likesCount ?? 0 }
    private var commentsCount: Int { commentsOverride ?? reflection.commentsCount ?? 0 }

    private var actionRow: some View {
        HStack(spacing: 18) {
            Button {
                Task { await toggleLike() }
            } label: {
                actionLabel(
                    icon: isLiked ? "heart.fill" : "heart",
                    count: likesCount,
                    tint: isLiked ? Color.hWeakRed : labelColor
                )
            }
            .buttonStyle(.plain)

            Button {
                showComments = true
            } label: {
                actionLabel(icon: "bubble.left", count: commentsCount, tint: labelColor)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.top, 2)
    }

    private func actionLabel(icon: String, count: Int, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 13))
            if count > 0 {
                Text("\(count)")
                    .font(HFont.generalSans(12))
            }
        }
        .foregroundStyle(tint)
        .contentShape(Rectangle())
    }

    /// Optimistic: flip immediately, then reconcile against the state the
    /// server reports, or roll back if the call fails. The endpoint is a
    /// toggle, so its response is the authoritative new state.
    private func toggleLike() async {
        let wasLiked = isLiked
        let baseCount = likesCount

        withAnimation(.easeOut(duration: 0.15)) {
            likedOverride = !wasLiked
            likesOverride = max(0, baseCount + (wasLiked ? -1 : 1))
        }

        do {
            let confirmed = try await ReflectionsAPI.toggleLike(auth: auth, postId: reflection.id)
            likedOverride = confirmed
            likesOverride = confirmed == wasLiked
                ? baseCount
                : max(0, baseCount + (confirmed ? 1 : -1))
        } catch {
            withAnimation(.easeOut(duration: 0.15)) {
                likedOverride = wasLiked
                likesOverride = baseCount
            }
        }
    }

    // MARK: - Author

    private var authorRow: some View {
        HStack(spacing: 10) {
            avatar

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(reflection.author?.displayName ?? "Someone")
                        .font(HFont.generalSans(14, weight: .medium))
                        .foregroundStyle(Color.hDarkText)
                        .lineLimit(1)

                    if reflection.author?.verified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.hOliveGreen)
                    }
                }

                if let timestamp = reflection.relativeTimestamp {
                    Text(timestamp)
                        .font(HFont.generalSans(11))
                        .foregroundStyle(labelColor)
                }
            }

            Spacer()

            if reflection.draft == true {
                Text("DRAFT")
                    .font(HFont.generalSans(10, weight: .medium))
                    .tracking(0.3)
                    .foregroundStyle(labelColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.hDarkText.opacity(0.05))
                    .clipShape(Capsule())
            }
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(Color.hOliveGreen.opacity(0.12))
                .frame(width: 34, height: 34)

            if let url = reflection.author?.avatarURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initialsLabel
                }
                .frame(width: 34, height: 34)
                .clipShape(Circle())
            } else {
                initialsLabel
            }
        }
    }

    private var initialsLabel: some View {
        Text(reflection.author?.initials ?? "?")
            .font(HFont.generalSans(12, weight: .medium))
            .foregroundStyle(Color.hOliveGreen)
    }

    // MARK: - Reference

    private func referenceChip(_ reference: ReflectionReference) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "book.closed")
                .font(.system(size: 10))
            Text(reference.label)
                .font(HFont.generalSans(12, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(Color.hOliveGreen)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.hOliveGreen.opacity(0.09))
        .clipShape(Capsule())
    }

    // MARK: - Body

    private var bodyText: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(reflection.trimmedBody)
                .font(HFont.generalSans(15))
                .foregroundStyle(Color.hDarkText)
                .lineSpacing(5)
                .multilineTextAlignment(.leading)
                .lineLimit(isExpanded ? nil : collapsedLineLimit)
                .fixedSize(horizontal: false, vertical: true)

            if isTruncatable {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                } label: {
                    Text(isExpanded ? "Show less" : "Read more")
                        .font(HFont.generalSans(12, weight: .medium))
                        .foregroundStyle(Color.hOliveGreen)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Rough proxy for "longer than the collapsed line limit" — avoids the
    /// layout round-trip a precise measurement would need.
    private var isTruncatable: Bool {
        reflection.trimmedBody.count > 240
    }
}
