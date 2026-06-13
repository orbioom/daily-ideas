import SwiftUI

struct RootView: View {
    @State private var pro = ProStore()

    var body: some View {
        TabView {
            OverviewView()
                .tabItem { Label("Overview", systemImage: "chart.line.uptrend.xyaxis") }
            AccountsView()
                .tabItem { Label("Accounts", systemImage: "square.stack.3d.up.fill") }
            TrendsView()
                .tabItem { Label("Trends", systemImage: "calendar") }
            AllocationView()
                .tabItem { Label("Allocation", systemImage: "chart.pie.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environment(pro)
        .tint(Theme.accent)
    }
}
