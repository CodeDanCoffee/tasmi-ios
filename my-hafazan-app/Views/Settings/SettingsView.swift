import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL

    @State private var showSignOutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var showEditName = false
    @State private var editingName: String = ""

    private let subtextColor = Color(red: 122/255, green: 114/255, blue: 106/255)
    private let labelColor = Color(red: 168/255, green: 160/255, blue: 152/255)
    private let cardBorder = Color(red: 27/255, green: 24/255, blue: 21/255).opacity(0.04)

    private let privacyURL = URL(string: "https://tasmi.cloud/privacy")!
    private let termsURL = URL(string: "https://tasmi.cloud/terms")!
    private let coffeeURL = URL(string: "https://buymeacoffee.com/codedancoffee")!
    private let shareURL = URL(string: "https://tasmi.cloud")!

    var body: some View {
        ZStack {
            Color.hCreamBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Settings")
                        .font(.custom("Georgia", size: 40))
                        .foregroundStyle(Color.hDarkText)
                        .tracking(-0.5)
                        .padding(.top, 4)

                    accountCard

                    section(title: "ABOUT") {
                        VStack(spacing: 0) {
                            versionRow
                            divider
                            linkRow(title: "Privacy Policy") { openURL(privacyURL) }
                            divider
                            linkRow(title: "Terms of Service") { openURL(termsURL) }
                        }
                    }

                    section(title: "SUPPORT") {
                        VStack(spacing: 0) {
                            ShareLink(item: shareURL) {
                                rowContent(icon: "square.and.arrow.up", title: "Share App", tint: .hOliveGreen)
                            }
                            .buttonStyle(.plain)
                            divider
                            linkRow(icon: "cup.and.saucer.fill", title: "Buy Me a Coffee") { openURL(coffeeURL) }
                            divider
                            linkRow(icon: "star.fill", title: "Rate Us", iconColor: Color(red: 0.95, green: 0.75, blue: 0.2)) {
                                requestReview()
                            }
                        }
                    }

                    destructiveCard

                    Text("Deleting your account will permanently remove all your data including challenges, decks, and journey entries.")
                        .font(HFont.generalSans(12))
                        .foregroundStyle(subtextColor)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.hCreamBg, for: .navigationBar)
        .confirmationDialog(
            "Sign out of your account?",
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                auth.signOut()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete account?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { deleteAccount() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your challenges, decks, and journey entries on this device. This action cannot be undone.")
        }
        .alert("Your name", isPresented: $showEditName) {
            TextField("Display name", text: $editingName)
                .textInputAutocapitalization(.words)
            Button("Save") {
                auth.displayName = editingName
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This name appears on your home page.")
        }
    }

    // MARK: - Account Card

    private var accountCard: some View {
        Button {
            editingName = auth.displayName ?? auth.userName ?? ""
            showEditName = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 52, height: 52)
                    Image(systemName: "person.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(displayIdentity)
                        .font(HFont.generalSans(17, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text(accountSubtitle)
                        .font(HFont.generalSans(13))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 8)

                HStack(spacing: 4) {
                    Text("Basic")
                        .font(HFont.generalSans(13, weight: .semibold))
                        .foregroundStyle(Color.hOliveGreen)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.hOliveGreen)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.hOliveGreen)
            )
        }
        .buttonStyle(.plain)
    }

    private var displayIdentity: String {
        if let custom = auth.displayName, !custom.isEmpty { return custom }
        if let name = auth.userName, !name.isEmpty { return name }
        if let email = auth.userEmail { return email }
        return "Signed in"
    }

    private var accountSubtitle: String {
        if let email = auth.userEmail, displayIdentity != email { return email }
        return "Tap to edit your name"
    }

    // MARK: - Section helpers

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(HFont.generalSans(11, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(labelColor)
                .padding(.horizontal, 4)

            content()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(cardBorder, lineWidth: 1)
                )
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.hDarkText.opacity(0.05))
            .frame(height: 1)
            .padding(.leading, 16)
    }

    private var versionRow: some View {
        HStack {
            Text("Version")
                .font(HFont.generalSans(15, weight: .medium))
                .foregroundStyle(Color.hDarkText)
            Spacer()
            Text(versionString)
                .font(HFont.generalSans(15))
                .foregroundStyle(subtextColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func linkRow(
        icon: String? = nil,
        title: String,
        iconColor: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            rowContent(icon: icon, title: title, tint: .hOliveGreen, iconColor: iconColor)
        }
        .buttonStyle(.plain)
    }

    private func rowContent(
        icon: String? = nil,
        title: String,
        tint: Color,
        iconColor: Color? = nil
    ) -> some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor ?? tint)
                    .frame(width: 22)
            }
            Text(title)
                .font(HFont.generalSans(15, weight: .medium))
                .foregroundStyle(tint)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(labelColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    // MARK: - Destructive

    private var destructiveCard: some View {
        VStack(spacing: 0) {
            destructiveRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out") {
                showSignOutConfirm = true
            }
            divider
            destructiveRow(icon: "trash", title: "Delete Account") {
                showDeleteConfirm = true
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    private func destructiveRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.hWeakRed)
                    .frame(width: 22)
                Text(title)
                    .font(HFont.generalSans(15, weight: .medium))
                    .foregroundStyle(Color.hWeakRed)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func deleteAccount() {
        try? modelContext.delete(model: Challenge.self)
        try? modelContext.delete(model: DeckCard.self)
        try? modelContext.delete(model: JourneyEntry.self)
        try? modelContext.save()
        auth.signOut()
        dismiss()
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AuthManager())
    .modelContainer(for: [Challenge.self, DeckCard.self, JourneyEntry.self])
}
