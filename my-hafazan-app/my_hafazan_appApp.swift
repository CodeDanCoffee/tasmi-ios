import SwiftUI
import SwiftData

@main
struct my_hafazan_appApp: App {
    @State private var auth = AuthManager()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(auth)

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
            .onOpenURL { url in
                _ = auth.resume(with: url)
            }
        }
        .modelContainer(for: [
            Challenge.self,
            DeckCard.self,
            JourneyEntry.self
        ])
    }
}
