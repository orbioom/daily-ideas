import SwiftUI
import SwiftData

/// Top-level tab shell. Five feature tabs plus Settings reachable from each top bar.
struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(TimerEngine.self) private var timerEngine
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @Query private var activeTimers: [CookTimer]

    @State private var selection: Tab = .guide

    enum Tab: Hashable { case guide, timers, convert, favorites, stats }

    init() {
        _activeTimers = Query(filter: #Predicate<CookTimer> { $0.isActive })
    }

    var body: some View {
        TabView(selection: $selection) {
            GuideView()
                .tabItem { Label("Guide", systemImage: "fork.knife") }
                .tag(Tab.guide)

            TimersView()
                .tabItem { Label("Timers", systemImage: "timer") }
                .badge(runningCount)
                .tag(Tab.timers)

            ConvertView()
                .tabItem { Label("Convert", systemImage: "arrow.left.arrow.right") }
                .tag(Tab.convert)

            FavoritesView()
                .tabItem { Label("Saved", systemImage: "heart") }
                .tag(Tab.favorites)

            StatsView()
                .tabItem { Label("Log", systemImage: "chart.bar.xaxis") }
                .tag(Tab.stats)
        }
        .tint(Theme.accent)
        .onChange(of: scenePhase) { _, newPhase in
            // Remaining time is always derived live from endDate via TimelineView, so
            // nothing needs recomputing on resume. We do mark any timers that finished
            // while backgrounded as handled, so their completion state is consistent.
            if newPhase == .active {
                for timer in activeTimers where timer.isFinished() {
                    _ = timerEngine.registerCompletionIfNeeded(timer)
                }
            }
        }
    }

    private var runningCount: Int {
        activeTimers.filter { !$0.isFinished() }.count
    }
}
