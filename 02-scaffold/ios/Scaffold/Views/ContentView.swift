import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settingsQ: [ScaffoldSettings]
    private var settings: ScaffoldSettings? { settingsQ.first }

    var body: some View {
        if settings?.onboardingComplete == true {
            mainApp
        } else {
            ScaffoldOnboardingView()
        }
    }

    private var mainApp: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "squares.below.rectangle") }

            RoomsListView()
                .tabItem { Label("Rooms", systemImage: "door.sliding.right.hand.closed") }

            MaterialsShoppingView()
                .tabItem { Label("Shopping", systemImage: "cart.fill") }

            ScaffoldSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(ScaffoldTheme.accent)
    }
}
