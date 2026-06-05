import SwiftUI
import SwiftData

/// Root container: seeds sample data once, gates onboarding, hosts the tab bar.
struct RootView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var groups: [SplitGroup]

    var body: some View {
        ZStack {
            Brand.pageBackground

            if !settings.hasOnboarded {
                OnboardingView()
                    .transition(.opacity)
            } else {
                TabView {
                    GroupsListView()
                        .tabItem { Label("Groups", systemImage: "person.2.fill") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                }
                .transition(.opacity)
            }
        }
        .animation(Brand.ease(), value: settings.hasOnboarded)
        .task { seedIfNeeded() }
    }

    /// Insert the starter groups exactly once, on the very first launch into an empty store.
    private func seedIfNeeded() {
        guard !settings.hasSeeded, groups.isEmpty else { return }
        SampleData.insert(into: context)
        settings.hasSeeded = true
    }
}
