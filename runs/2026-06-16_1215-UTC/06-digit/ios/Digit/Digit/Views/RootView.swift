import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Profile.createdDate) private var profiles: [Profile]

    @State private var didSeed = false
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            PlayView(selectedProfile: selectedProfile)
                .tabItem { Label("Play", systemImage: "play.circle.fill") }
                .tag(0)

            ProgressDashboardView(selectedProfile: selectedProfile)
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
                .tag(1)

            RewardsView(selectedProfile: selectedProfile)
                .tabItem { Label("Rewards", systemImage: "rosette") }
                .tag(2)

            SettingsView(selectedProfile: selectedProfile)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(Theme.accent)
        .task { seedAndSelect() }
        .onChange(of: profiles.count) { _, _ in ensureSelection() }
    }

    /// The profile the app currently focuses, falling back to the first available.
    private var selectedProfile: Profile? {
        if let match = profiles.first(where: { $0.id.uuidString == settings.selectedProfileID }) {
            return match
        }
        return profiles.first
    }

    private func seedAndSelect() {
        guard !didSeed else { return }
        didSeed = true
        if profiles.isEmpty {
            if let seeded = SeedData.seedIfNeeded(context: context) {
                settings.selectedProfileID = seeded.id.uuidString
            }
        } else {
            ensureSelection()
        }
    }

    private func ensureSelection() {
        if profiles.first(where: { $0.id.uuidString == settings.selectedProfileID }) == nil {
            settings.selectedProfileID = profiles.first?.id.uuidString ?? ""
        }
    }
}
