import SwiftUI

struct SparTabView: View {
    var body: some View {
        TabView {
            SparDashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
            SessionListView()
                .tabItem { Label("Sessions", systemImage: "list.bullet.rectangle") }
            TechniqueLibraryView()
                .tabItem { Label("Techniques", systemImage: "book.closed.fill") }
            FightRecordView()
                .tabItem { Label("Record", systemImage: "trophy.fill") }
            SparInsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
        }
    }
}
