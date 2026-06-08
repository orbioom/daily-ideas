import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("anew.onboarded") private var onboarded: Bool = false
    @AppStorage("anew.haptics")   private var hapticsEnabled: Bool = true

    @Environment(\.modelContext) private var modelContext
    @Query private var quits: [Quit]

    var body: some View {
        Group {
            if onboarded {
                MainTabs()
            } else {
                OnboardingView()
            }
        }
        .tint(Brand.text)
        .task {
            Haptics.enabled = hapticsEnabled
            if quits.isEmpty {
                SeedData.insert(into: modelContext)
            }
        }
        .onChange(of: hapticsEnabled) { _, newValue in
            Haptics.enabled = newValue
        }
    }
}

// MARK: - MainTabs

struct MainTabs: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            MilestonesView()
                .tabItem {
                    Label("Milestones", systemImage: "trophy.fill")
                }

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }

            JournalHubView()
                .tabItem {
                    Label("Journal", systemImage: "book.closed.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
