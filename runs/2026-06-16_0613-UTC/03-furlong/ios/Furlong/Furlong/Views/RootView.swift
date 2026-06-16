import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @State private var seeded = false

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "gauge.with.dots.needle.50percent") }

            TripsView()
                .tabItem { Label("Trips", systemImage: "car.fill") }

            ExpensesView()
                .tabItem { Label("Expenses", systemImage: "creditcard.fill") }

            ReportsView()
                .tabItem { Label("Reports", systemImage: "chart.pie.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.accent)
        .task {
            guard !seeded else { return }
            seeded = true
            SeedData.seedIfNeeded(context)
        }
    }
}
