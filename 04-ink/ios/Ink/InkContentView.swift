import SwiftUI

struct InkContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                IdeasView()
            }
            .tabItem {
                Label("Ideas", systemImage: "sparkles")
            }
            .tag(0)

            NavigationStack {
                ArtistsView()
            }
            .tabItem {
                Label("Artists", systemImage: "person.crop.rectangle.fill")
            }
            .tag(1)

            NavigationStack {
                AppointmentsView()
            }
            .tabItem {
                Label("Sessions", systemImage: "calendar")
            }
            .tag(2)

            NavigationStack {
                InkSettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .tint(InkTheme.accent)
    }
}
