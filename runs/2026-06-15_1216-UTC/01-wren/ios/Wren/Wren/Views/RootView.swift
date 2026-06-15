import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @Query private var companions: [Companion]
    @State private var selection: Tab = .today

    enum Tab: Hashable {
        case today, goals, journeys, insights, reflections
    }

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.and.horizon.fill") }
                .tag(Tab.today)

            GoalsView()
                .tabItem { Label("Goals", systemImage: "checklist") }
                .tag(Tab.goals)

            JourneysView()
                .tabItem { Label("Journeys", systemImage: "map.fill") }
                .tag(Tab.journeys)

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                .tag(Tab.insights)

            ReflectionsView()
                .tabItem { Label("Reflect", systemImage: "leaf.fill") }
                .tag(Tab.reflections)
        }
        .background(Theme.bg)
        .onAppear {
            // Safety net: if the store somehow has no companion (e.g. fresh install that
            // bypassed onboarding seeding), seed it now so the app is never empty.
            if companions.isEmpty {
                SeedData.seedIfNeeded(context: modelContext)
            }
        }
    }
}
