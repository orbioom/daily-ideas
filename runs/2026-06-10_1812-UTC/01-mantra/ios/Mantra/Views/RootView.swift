import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("didSeedLibrary") private var didSeedLibrary = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appearance") private var appearance = "system"

    var body: some View {
        ZStack {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .task { seedIfNeeded() }
        .onAppear { Haptics.enabled = hapticsEnabled }
        .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
    }

    private func seedIfNeeded() {
        guard !didSeedLibrary else { return }
        // Guard against partial double-seed: only seed if no built-ins exist.
        let descriptor = FetchDescriptor<Affirmation>(predicate: #Predicate { $0.isCustom == false })
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        if existing == 0 {
            for (text, category) in Library.seeds {
                context.insert(Affirmation(text: text, category: category))
            }
            try? context.save()
        }
        didSeedLibrary = true
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
            BrowseView()
                .tabItem { Label("Browse", systemImage: "square.grid.2x2.fill") }
            CollectionView()
                .tabItem { Label("Mine", systemImage: "heart.fill") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Brand.text)
    }
}
