import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            SkyMapView()
                .tabItem {
                    Label("Sky", systemImage: "staroflife.fill")
                }
                .tag(0)

            TonightView()
                .tabItem {
                    Label("Tonight", systemImage: "moon.stars.fill")
                }
                .tag(1)

            CatalogView()
                .tabItem {
                    Label("Catalog", systemImage: "list.star")
                }
                .tag(2)

            ObservingLogView()
                .tabItem {
                    Label("Log", systemImage: "book.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .tint(Color(red: 0.45, green: 0.65, blue: 1.0))
        .preferredColorScheme(.dark)
    }
}
