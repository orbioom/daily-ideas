import SwiftUI

struct RootView: View {
    @State private var pro = ProStore()

    var body: some View {
        TabView {
            DebtsView()
                .tabItem { Label("Debts", systemImage: "list.bullet.rectangle.fill") }
            PlanView()
                .tabItem { Label("Plan", systemImage: "calendar.badge.clock") }
            CompareView()
                .tabItem { Label("Compare", systemImage: "arrow.left.arrow.right") }
            ProgressTabView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environment(pro)
        .tint(Theme.accent)
    }
}
