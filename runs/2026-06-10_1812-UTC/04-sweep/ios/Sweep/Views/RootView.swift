import SwiftUI

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appearance") private var appearance = "system"

    var body: some View {
        ZStack {
            if hasOnboarded { MainTabView() } else { OnboardingView() }
        }
        .onAppear { Haptics.enabled = hapticsEnabled }
        .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
    }
}

struct MainTabView: View {
    @EnvironmentObject private var library: PhotoLibraryService

    var body: some View {
        TabView {
            OverviewView()
                .tabItem { Label("Clean", systemImage: "sparkles") }
            BasketView()
                .tabItem { Label("To Delete", systemImage: "trash") }
                .badge(library.basket.count)
            InsightsView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Brand.text)
    }
}
