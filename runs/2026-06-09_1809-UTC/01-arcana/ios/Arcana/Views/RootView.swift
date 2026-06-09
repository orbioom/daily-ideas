import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(PrefKey.onboarded) private var onboarded = false
    @AppStorage(PrefKey.haptics) private var haptics = true
    @State private var isSeeding = false

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded {
                if isSeeding {
                    SeedingView()
                } else {
                    MainTabView()
                }
            } else {
                OnboardingView()
            }
        }
        .tint(Brand.magic)
        .task { await prepare() }
        .onChange(of: onboarded) { _, isOn in
            if isOn { Task { await prepare() } }
        }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }

    /// Applies haptic preference and seeds sample data once, showing a brief
    /// loading state while the seed runs.
    private func prepare() async {
        Haptics.enabled = haptics
        guard onboarded else { return }
        let needsSeed = ((try? context.fetch(FetchDescriptor<Reading>())) ?? []).isEmpty
        if needsSeed {
            isSeeding = true
            SeedData.seedIfNeeded(context)
            // A brief beat so the loading state reads as intentional, not a flash.
            try? await Task.sleep(nanoseconds: 350_000_000)
            isSeeding = false
        }
    }
}

/// Lightweight loading state shown while seed/heavy work runs.
struct SeedingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Shuffling the deck…")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preparing your readings")
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { TodayView() }
                .tabItem { Label("Today", systemImage: "moon.stars.fill") }
            NavigationStack { DrawView() }
                .tabItem { Label("Draw", systemImage: "rectangle.portrait.on.rectangle.portrait") }
            NavigationStack { LibraryView() }
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }
            NavigationStack { JournalView() }
                .tabItem { Label("Journal", systemImage: "book.closed.fill") }
            NavigationStack { InsightsView() }
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
        }
    }
}
