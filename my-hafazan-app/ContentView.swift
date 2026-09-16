import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Today", systemImage: "scope")
            }
            .tag(0)

            NavigationStack {
                JourneyView()
            }
            .tabItem {
                Label("Journey", systemImage: "point.bottomleft.forward.to.point.topright.scurvepath")
            }
            .tag(1)

            NavigationStack {
                DeckListView()
            }
            .tabItem {
                Label("Revise", systemImage: "book.closed.fill")
            }
            .tag(2)

            NavigationStack {
                ReflectionsView()
            }
            .tabItem {
                Label("Reflections", systemImage: "text.bubble")
            }
            .tag(3)
        }
        .tint(Color.hOliveGreen)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.hCreamBg)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
        .modelContainer(for: [Challenge.self, DeckCard.self, JourneyEntry.self])
}
