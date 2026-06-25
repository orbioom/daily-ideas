import SwiftUI

struct FieldMainTabView: View {
    var body: some View {
        TabView {
            ObserveView()
                .tabItem { Label("Observe", systemImage: "binoculars.fill") }
            CatalogView()
                .tabItem { Label("Catalog", systemImage: "books.vertical.fill") }
            TripsView()
                .tabItem { Label("Trips", systemImage: "map.fill") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
            FieldSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(FieldTheme.fern)
    }
}
