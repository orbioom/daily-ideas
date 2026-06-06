import SwiftUI
import SwiftData

/// Root container: seeds sample data once, gates onboarding, hosts the tab bar.
struct RootView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var rolls: [Roll]

    var body: some View {
        ZStack {
            Brand.pageBackground

            if !settings.hasOnboarded {
                OnboardingView()
                    .transition(.opacity)
            } else {
                TabView {
                    CalculatorView()
                        .tabItem { Label("Calculator", systemImage: "camera.aperture") }
                    RollsListView()
                        .tabItem { Label("Rolls", systemImage: "film") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                }
                .transition(.opacity)
            }
        }
        .animation(Brand.ease(), value: settings.hasOnboarded)
        .task { seedIfNeeded() }
    }

    /// Insert the starter rolls exactly once, on the very first launch into an empty store.
    private func seedIfNeeded() {
        guard !settings.hasSeeded, rolls.isEmpty else { return }
        SampleData.insert(into: context)
        settings.hasSeeded = true
    }
}

#Preview {
    RootView()
        .environment(SettingsStore())
        .modelContainer(for: [Roll.self, Frame.self], inMemory: true)
}
