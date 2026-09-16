import SwiftUI

struct SplashView: View {
    @State private var ornamentOffset: CGFloat = 0
    @State private var showLatin = false

    var body: some View {
        ZStack {
            // Background: warm cream with subtle radial gradients
            Color.hCreamBg
                .ignoresSafeArea()

            // Top highlight
            RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.992, blue: 0.965),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            // Bottom shadow
            RadialGradient(
                colors: [
                    Color(red: 0.941, green: 0.922, blue: 0.875),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 1.0),
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Ornament with olive halo
                ZStack {
                    // Soft olive halo behind ornament
                    RadialGradient(
                        colors: [
                            Color(red: 0.357, green: 0.431, blue: 0.31).opacity(0.10),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 177 // 1.5x bump from 118
                    )
                    .frame(width: 354, height: 354) // 1.5x bump from 236

                    Image("tasmi-ornament")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 234, height: 234)
                        .shadow(
                            color: Color(red: 0.247, green: 0.314, blue: 0.216).opacity(0.10),
                            radius: 14, x: 0, y: 4
                        )
                }
                .offset(y: ornamentOffset)

                Spacer()
                    .frame(height: 32)

                // Latin: Tasmi
                Text("Tasmi")
                    .font(.custom("Playfair Display", size: 34))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.hOliveGreen)
                    .tracking(-0.2)
                    .opacity(showLatin ? 1 : 0)
                    .offset(y: showLatin ? 0 : 12)

                Spacer()
            }
        }
        .onAppear {
            // Floating ornament animation (perpetual)
            withAnimation(
                .easeInOut(duration: 4.2)
                .repeatForever(autoreverses: true)
            ) {
                ornamentOffset = -6
            }

            // Fade-in Latin with delay
            withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
                showLatin = true
            }
        }
    }
}

#Preview {
    SplashView()
}
