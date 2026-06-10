import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("onboarded") private var onboarded = false
    @AppStorage("appearance") private var appearance = "system"

    private var scheme: ColorScheme? {
        switch appearance { case "light": .light; case "dark": .dark; default: nil }
    }

    var body: some View {
        ZStack {
            if onboarded {
                MainTabView()
            } else {
                OnboardingView { withAnimation(Brand.ease()) { onboarded = true } }
            }
        }
        .animation(Brand.ease(), value: onboarded)
        .preferredColorScheme(scheme)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            ProjectsView()
                .tabItem { Label("Collages", systemImage: "square.grid.2x2") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Brand.text)
    }
}

#Preview {
    RootView().modelContainer(for: CollageProject.self, inMemory: true)
}
