import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var rules: [RecurringRule]
    @AppStorage("tally.onboarded") private var onboarded = false
    @AppStorage("tally.haptics") private var haptics = true
    @State private var didSetup = false

    var body: some View {
        ZStack {
            Brand.pageBackground
            if onboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(Color(hex: 0x3E9E78))
        .onAppear {
            Haptics.enabled = haptics
            if onboarded { setup() }
        }
        .onChange(of: onboarded) { _, new in if new { setup() } }
        .onChange(of: haptics) { _, new in Haptics.enabled = new }
    }

    private func setup() {
        guard !didSetup else { return }
        didSetup = true
        // Post any due recurring transactions on launch.
        let created = MoneyEngine.postDue(rules)
        for t in created { context.insert(t) }
        if !created.isEmpty { try? context.save() }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            OverviewView()
                .tabItem { Label("Overview", systemImage: "chart.pie.fill") }
            TransactionsView()
                .tabItem { Label("Activity", systemImage: "list.bullet") }
            BudgetsView()
                .tabItem { Label("Budgets", systemImage: "chart.bar.fill") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
        }
    }
}
