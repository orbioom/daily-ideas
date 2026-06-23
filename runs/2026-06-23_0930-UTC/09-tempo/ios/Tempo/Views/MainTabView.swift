import SwiftUI
import SwiftData

/// Root tab interface: Train / History / Exercises / Stats / Settings.
struct MainTabView: View {
    var body: some View {
        TabView {
            TrainView()
                .tabItem { Label("Train", systemImage: "dumbbell.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            ExercisesView()
                .tabItem { Label("Exercises", systemImage: "list.bullet.rectangle") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.xyaxis.line") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

/// Resolves the single persisted settings row, creating it if missing.
/// Centralizes safe access so screens never force-unwrap.
struct SettingsAccess {
    static func current(_ settings: [AppSettings], context: ModelContext) -> AppSettings {
        if let existing = settings.first { return existing }
        let created = AppSettings()
        context.insert(created)
        try? context.save()
        return created
    }
}

#Preview {
    MainTabView()
        .modelContainer(PersistenceController.preview)
}
