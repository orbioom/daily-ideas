import SwiftUI

/// App root: gates onboarding, then shows the main TabView.
struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        ZStack {
            if hasOnboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: hasOnboarded)
    }
}

/// The five-tab main interface. Settings is reachable from a toolbar entry on
/// each primary screen (and is itself not a "feature" tab).
struct MainTabView: View {
    @State private var selection: Tab = .estimate

    enum Tab: Hashable {
        case estimate, ledger, quarterly, scenarios, learn
    }

    var body: some View {
        TabView(selection: $selection) {
            EstimateView()
                .tabItem { Label("Estimate", systemImage: "function") }
                .tag(Tab.estimate)

            LedgerView()
                .tabItem { Label("Ledger", systemImage: "list.bullet.rectangle") }
                .tag(Tab.ledger)

            QuarterlyView()
                .tabItem { Label("Quarterly", systemImage: "calendar.badge.clock") }
                .tag(Tab.quarterly)

            ScenariosView()
                .tabItem { Label("Scenarios", systemImage: "square.on.square") }
                .tag(Tab.scenarios)

            LearnView()
                .tabItem { Label("Learn", systemImage: "book") }
                .tag(Tab.learn)
        }
    }
}
