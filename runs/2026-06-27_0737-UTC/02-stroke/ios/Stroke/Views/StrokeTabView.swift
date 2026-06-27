import SwiftUI

struct StrokeTabView: View {
    var body: some View {
        TabView {
            DashboardRowView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
            WorkoutListView()
                .tabItem { Label("Workouts", systemImage: "list.bullet.rectangle") }
            PersonalRecordsView()
                .tabItem { Label("Records", systemImage: "trophy.fill") }
            RowInsightsView()
                .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }
            StrokeSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
