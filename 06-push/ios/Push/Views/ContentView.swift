import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var onboardingRecords: [PushOnboarding]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab: Int = 0
    @State private var showOnboarding: Bool = false

    private var onboarding: PushOnboarding {
        if let existing = onboardingRecords.first { return existing }
        let new = PushOnboarding()
        modelContext.insert(new)
        return new
    }

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView {
                    onboarding.completed = true
                    showOnboarding = false
                }
                .transition(.opacity)
            } else {
                mainTabs
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showOnboarding)
        .onAppear {
            // Check if onboarding needed
            if onboardingRecords.isEmpty || !(onboardingRecords.first?.completed ?? false) {
                showOnboarding = true
            }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            PackSelectView()
                .tabItem {
                    Label("Play", systemImage: "square.grid.2x2.fill")
                }
                .tag(0)

            DailyView()
                .tabItem {
                    Label("Daily", systemImage: "calendar")
                }
                .tag(1)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(PushTheme.accent)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PushRecord.self, PushPrefs.self, PushDailyResult.self, PushOnboarding.self], inMemory: true)
}
