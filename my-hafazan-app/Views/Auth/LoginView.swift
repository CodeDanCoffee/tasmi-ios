import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        ZStack {
            Color.hCreamBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                ZStack {
                    RadialGradient(
                        colors: [
                            Color.hOliveGreen.opacity(0.10),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 177
                    )
                    .frame(width: 354, height: 354)

                    Image("tasmi-ornament")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 234, height: 234)
                        .shadow(
                            color: Color(red: 0.247, green: 0.314, blue: 0.216).opacity(0.10),
                            radius: 10, x: 0, y: 3
                        )
                }
                .frame(width: 210, height: 210)
                .padding(.bottom, HSpacing.xxl)

                // Heading
                Text("Your Quran memorisation\njourney is just up ahead.")
                    .font(HFont.sourceSerif(32, weight: .regular))
                    .foregroundStyle(Color.hDarkText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.bottom, HSpacing.xl)

                // Subtitle — hadith
                Text("\u{201C}The best among you are those who\nlearn the Qur\u{2019}ān and teach it.\u{201D}\n(Sahīh al-Bukhārī)")
                    .font(HFont.generalSans(16))
                    .italic()
                    .foregroundStyle(Color.hSubtext)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                Spacer()
                Spacer()

                // Error message
                if let error = auth.lastError {
                    Text(error)
                        .font(HFont.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, HSpacing.md)
                }

                // Get Started. Dark pill
                Button {
                    Task { await auth.signIn() }
                } label: {
                    Group {
                        if auth.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            HStack(spacing: 10) {
                                Image("quran-foundation-logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                                Text("Sign in with Quran Foundation")
                                    .font(HFont.bodyMedium)
                            }
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.hDarkText)
                    .clipShape(Capsule())
                }
                .disabled(auth.isLoading)
                .padding(.bottom, HSpacing.xxxl)
            }
            .padding(.horizontal, HSpacing.screenPadding)
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthManager())
}
