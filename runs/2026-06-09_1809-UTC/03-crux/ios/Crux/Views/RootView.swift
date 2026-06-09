import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Prefs.onboarded) private var onboarded = false
    @AppStorage(Prefs.haptics) private var haptics = true
    @State private var didSeed = false
    @State private var isSeeding = false

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded {
                if isSeeding && !didSeed {
                    SeedingView()
                } else {
                    MainTabView()
                }
            } else {
                OnboardingView()
            }
        }
        .tint(Brand.magic)
        .task {
            Haptics.enabled = haptics
            await seedIfNeeded()
        }
        .onChange(of: onboarded) { _, isOn in
            if isOn { Task { await seedIfNeeded() } }
        }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }

    /// Runs the one-time seed off the first frame, showing a brief loading state.
    @MainActor
    private func seedIfNeeded() async {
        guard onboarded, !didSeed else { return }
        let alreadySeeded = ((try? context.fetch(FetchDescriptor<Area>())) ?? []).isEmpty == false
        if alreadySeeded { didSeed = true; return }
        isSeeding = true
        // Yield so the loading state can paint before the heavier insert work.
        await Task.yield()
        SeedData.seedIfNeeded(context)
        didSeed = true
        isSeeding = false
    }
}

/// Calm full-screen loading state shown while the first-run seed runs.
private struct SeedingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(Brand.magic)
            Text("Setting up your workspace…")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Setting up your workspace")
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { TodayView() }
                .tabItem { Label("Today", systemImage: "checklist") }
            NavigationStack { UpcomingView() }
                .tabItem { Label("Upcoming", systemImage: "calendar") }
            NavigationStack { ProjectsView() }
                .tabItem { Label("Projects", systemImage: "folder") }
            NavigationStack { BrowseView() }
                .tabItem { Label("Browse", systemImage: "square.stack") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
