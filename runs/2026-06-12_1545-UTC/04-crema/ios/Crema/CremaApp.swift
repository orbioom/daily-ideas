import SwiftUI
import SwiftData

@main
struct CremaApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootView()
                } else {
                    OnboardingView()
                }
            }
            .tint(Theme.accent)
        }
        .modelContainer(for: [Bean.self, Brew.self])
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    var body: some View {
        TabView {
            ShelfView()
                .tabItem { Label("Shelf", systemImage: "bag.fill") }
            BrewLogView()
                .tabItem { Label("Brews", systemImage: "list.bullet") }
            DialInView()
                .tabItem { Label("Dial-in", systemImage: "slider.horizontal.3") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task { SeedData.installIfNeeded(context: context) }
    }
}
