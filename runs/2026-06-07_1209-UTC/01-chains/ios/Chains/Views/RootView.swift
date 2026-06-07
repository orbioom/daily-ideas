import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("chains.hasOnboarded") private var hasOnboarded = false
    @AppStorage("chains.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("chains.appearance") private var appearance = "system"
    @Query private var courses: [DiscCourse]

    private var scheme: ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                TabView {
                    RoundsView()
                        .tabItem { Label("Rounds", systemImage: "flag.checkered") }
                    CoursesView()
                        .tabItem { Label("Courses", systemImage: "map") }
                    StatsView()
                        .tabItem { Label("Stats", systemImage: "chart.xyaxis.line") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
                .tint(Brand.text)
            } else {
                OnboardingView {
                    if courses.isEmpty { SampleData.seed(into: context) }
                    hasOnboarded = true
                }
            }
        }
        .preferredColorScheme(scheme)
        .onAppear { Haptics.enabled = hapticsEnabled }
    }
}
