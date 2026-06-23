import SwiftUI
import SwiftData

/// Root tab navigation: Pets / Care / Health / Weight / Settings.
struct MainTabView: View {
    @Bindable var settings: AppSettings
    @Query(sort: \Pet.createdAt) private var pets: [Pet]

    private var overdueBadge: Int {
        let items = CareTimeline.build(for: pets)
        return CareTimeline.overdueCount(items, soonWindowDays: settings.soonWindowDays)
    }

    var body: some View {
        TabView {
            PetsView(settings: settings)
                .tabItem { Label("Pets", systemImage: "pawprint.fill") }

            CareView(settings: settings)
                .tabItem { Label("Care", systemImage: "checklist") }
                .badge(overdueBadge)

            HealthView(settings: settings)
                .tabItem { Label("Health", systemImage: "cross.case.fill") }

            WeightView(settings: settings)
                .tabItem { Label("Weight", systemImage: "chart.xyaxis.line") }

            SettingsView(settings: settings)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

#Preview {
    MainTabView(settings: {
        let s = AppSettings(hasOnboarded: true)
        return s
    }())
    .modelContainer(PersistenceController.preview.container)
}
