import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var schedules: [UserSchedule]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    private var schedule: UserSchedule {
        if let s = schedules.first { return s }
        let s = UserSchedule()
        modelContext.insert(s)
        return s
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            ExerciseLibraryView()
                .tabItem { Label("Exercises", systemImage: "figure.walk") }
                .tag(1)

            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(PoiseTheme.sky)
    }
}
