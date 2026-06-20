import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settingsQ: [CampSettings]

    var body: some View {
        if settingsQ.first?.onboardingComplete == true {
            mainTabs
        } else {
            CampOnboardingView()
        }
    }

    private var mainTabs: some View {
        TabView {
            TripsListView()
                .tabItem {
                    Label("Trips", systemImage: "tent.fill")
                }

            CampStatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            CampSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(CampfireTheme.accent)
    }
}
