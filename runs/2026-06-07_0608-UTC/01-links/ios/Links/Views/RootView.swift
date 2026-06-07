import SwiftUI
import SwiftData

/// Tab shell. Gates first run behind a persisted onboarding flag and seeds the
/// sample record once.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("links.hasOnboarded") private var hasOnboarded = false
    @AppStorage("links.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("links.appearance") private var appearance = "system"
    @Query private var courses: [Course]

    private var scheme: ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if hasOnboarded {
                TabView {
                    HandicapView()
                        .tabItem { Label("Handicap", systemImage: "flag.fill") }
                    RoundsView()
                        .tabItem { Label("Rounds", systemImage: "list.bullet.rectangle") }
                    CoursesView()
                        .tabItem { Label("Courses", systemImage: "map") }
                    InsightsView()
                        .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }
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
