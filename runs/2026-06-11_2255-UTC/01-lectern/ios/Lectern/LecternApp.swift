import SwiftUI
import SwiftData

@main
struct LecternApp: App {
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
        .modelContainer(for: [Script.self, RehearsalSession.self])
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            ScriptsListView()
                .tabItem { Label("Scripts", systemImage: "doc.text") }
            RehearsalsView()
                .tabItem { Label("Rehearsals", systemImage: "chart.bar.xaxis") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
