import SwiftUI
import SwiftData

@main
struct VitaeApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                RootTabView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(for: Resume.self)
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            ResumesListView()
                .tabItem { Label("Resumes", systemImage: "doc.text.fill") }
            TipsView()
                .tabItem { Label("Guide", systemImage: "lightbulb.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(VitaeTheme.blue)
    }
}
