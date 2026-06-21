import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var onboardingList: [AtomOnboarding]
    @Query private var prefsList: [AtomPrefs]
    @Environment(\.modelContext) private var modelContext

    private var onboarding: AtomOnboarding {
        if let o = onboardingList.first { return o }
        let o = AtomOnboarding(); modelContext.insert(o); return o
    }
    private var prefs: AtomPrefs {
        if let p = prefsList.first { return p }
        let p = AtomPrefs(); modelContext.insert(p); return p
    }

    @State private var selectedTab: Tab = .table

    enum Tab: Hashable {
        case table, search, quiz, stats, settings
    }

    var body: some View {
        if !onboarding.completed {
            OnboardingView()
        } else {
            mainTabView
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            // Table
            NavigationStack {
                VStack(spacing: 0) {
                    PeriodicTableView(
                        elements: Element.all,
                        colorBlindMode: prefs.colorBlindMode,
                        showMass: prefs.showAtomicMass
                    )
                    .navigationTitle("Periodic Table")
                    .navigationBarTitleDisplayMode(.inline)

                    // Legend toggle button could go here
                }
            }
            .tabItem {
                Label("Table", systemImage: "tablecells")
            }
            .tag(Tab.table)

            // Search
            SearchView(
                colorBlindMode: prefs.colorBlindMode,
                kelvin: prefs.temperatureUnitKelvin,
                showMass: prefs.showAtomicMass
            )
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(Tab.search)

            // Quiz
            QuizView()
                .tabItem {
                    Label("Quiz", systemImage: "brain.head.profile")
                }
                .tag(Tab.quiz)

            // Stats
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(Tab.stats)

            // Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(AtomTheme.accent)
        .preferredColorScheme(.dark)
        .onAppear {
            // Style tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(AtomTheme.cardBackground)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [AtomOnboarding.self, AtomPrefs.self, AtomProgress.self])
        .preferredColorScheme(.dark)
}
