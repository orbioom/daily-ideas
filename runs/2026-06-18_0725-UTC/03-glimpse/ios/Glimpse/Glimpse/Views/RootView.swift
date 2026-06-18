import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @State private var didSeed = false
    @State private var selectedTab: Tab = .today

    enum Tab: Hashable {
        case today, timeline, calendar, memories, stats
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
                .tag(Tab.today)

            TimelineView()
                .tabItem { Label("Timeline", systemImage: "rectangle.stack.fill") }
                .tag(Tab.timeline)

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(Tab.calendar)

            MemoriesView()
                .tabItem { Label("Memories", systemImage: "sparkles") }
                .tag(Tab.memories)

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(Tab.stats)
        }
        .tint(Theme.accent)
        .task {
            guard !didSeed else { return }
            didSeed = true
            SeedData.seedIfNeeded(context: context)
        }
    }
}
