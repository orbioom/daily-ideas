import SwiftUI

struct RootView: View {
    @State private var selection: Tab = .portfolio

    enum Tab: Hashable {
        case portfolio, rent, reports, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            PortfolioView()
                .tabItem { Label("Portfolio", systemImage: "house.fill") }
                .tag(Tab.portfolio)

            RentView()
                .tabItem { Label("Rent", systemImage: "calendar.badge.clock") }
                .tag(Tab.rent)

            ReportsView()
                .tabItem { Label("Reports", systemImage: "chart.bar.xaxis") }
                .tag(Tab.reports)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(Theme.accent)
    }
}
