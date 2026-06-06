import SwiftUI
import SwiftData

/// Root container: seeds sample data once, gates onboarding, hosts the tab bar.
struct RootView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var routines: [Routine]

    var body: some View {
        ZStack {
            Brand.pageBackground

            if !settings.hasLaunchedBefore {
                OnboardingView()
                    .transition(.opacity)
            } else {
                TabView {
                    LibraryView()
                        .tabItem { Label("Routines", systemImage: "list.bullet.rectangle.portrait.fill") }
                    HistoryView()
                        .tabItem { Label("History", systemImage: "chart.bar.fill") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                }
                .transition(.opacity)
            }
        }
        .animation(Brand.ease(), value: settings.hasLaunchedBefore)
        .task { seedIfNeeded() }
    }

    /// Insert the starter routines exactly once, on the first launch into an empty store.
    private func seedIfNeeded() {
        guard !settings.hasSeeded, routines.isEmpty else { return }
        SampleData.insert(into: context)
        settings.hasSeeded = true
    }
}

#Preview {
    RootView().intervalPreview()
}
