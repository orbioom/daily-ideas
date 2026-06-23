import SwiftUI

/// The app's four primary tabs.
struct RootTabView: View {
    var body: some View {
        TabView {
            TripsListView()
                .tabItem {
                    Label("Trips", systemImage: "suitcase.fill")
                }

            ActiveTripView()
                .tabItem {
                    Label("Packing", systemImage: "checklist")
                }

            TemplatesView()
                .tabItem {
                    Label("Templates", systemImage: "square.stack.3d.up.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
