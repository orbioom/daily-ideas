import SwiftUI

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .onAppear { Haptics.enabled = hapticsEnabled }
        .onChange(of: hapticsEnabled) { _, enabled in Haptics.enabled = enabled }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
            IdeasView()
                .tabItem { Label("Ideas", systemImage: "lightbulb") }
            MemoriesView()
                .tabItem { Label("Memories", systemImage: "photo.on.rectangle.angled") }
            PulseView()
                .tabItem { Label("Pulse", systemImage: "waveform.path.ecg") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Brand.text)
    }
}
