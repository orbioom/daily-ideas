import SwiftUI
import SwiftData

/// Root tab bar. Seeds the sample budget on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false

    var body: some View {
        TabView {
            BudgetScreen()
                .tabItem { Label("Budget", systemImage: "tray.full.fill") }

            AccountsScreen()
                .tabItem { Label("Accounts", systemImage: "wallet.pass.fill") }

            TransactionsScreen()
                .tabItem { Label("Transactions", systemImage: "list.bullet.rectangle.fill") }

            ReportsScreen()
                .tabItem { Label("Reports", systemImage: "chart.pie.fill") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .task {
            var seeded = didSeed
            SeedData.seedIfNeeded(context: context, didSeed: &seeded)
            didSeed = seeded
        }
    }
}
