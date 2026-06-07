import SwiftUI
import SwiftData

/// App shell: gates onboarding, then presents the four-tab experience.
struct RootView: View {
    @Environment(\.modelContext) private var context

    @AppStorage(PrefKey.hasOnboarded) private var hasOnboarded = false
    @AppStorage(PrefKey.haptics) private var hapticsEnabled = true
    @AppStorage(PrefKey.appearance) private var appearanceRaw = AppAppearance.system.rawValue

    private var appearance: AppAppearance {
        AppAppearance(rawValue: appearanceRaw) ?? .system
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView {
                    SampleData.seedIfNeeded(in: context)
                    withAnimation(Brand.ease()) { hasOnboarded = true }
                }
                .transition(.opacity)
            }
        }
        .tint(Brand.text)
        .preferredColorScheme(appearance.colorScheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
        .onChange(of: hapticsEnabled) { _, newValue in Haptics.enabled = newValue }
    }
}

/// The persistent four-tab navigation.
struct MainTabView: View {
    var body: some View {
        TabView {
            SystemsView()
                .tabItem { Label("Systems", systemImage: "bolt.batteryblock") }

            SizingView()
                .tabItem { Label("Sizing", systemImage: "slider.horizontal.3") }

            ReferenceView()
                .tabItem { Label("Reference", systemImage: "books.vertical") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [PowerSystem.self, Load.self], inMemory: true)
}
