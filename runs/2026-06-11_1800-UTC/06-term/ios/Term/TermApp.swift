import SwiftUI
import SwiftData

@main
struct TermApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                TermRootView()
            } else {
                TermOnboardingView(isComplete: $hasSeenOnboarding)
            }
        }
        .modelContainer(for: [AcademicTerm.self, Course.self, GradeWeight.self, Assignment.self, ClassSchedule.self])
    }
}

struct TermRootView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            AgendaView()
                .tabItem { Label("Agenda", systemImage: "calendar") }
                .tag(0)

            CoursesView()
                .tabItem { Label("Courses", systemImage: "books.vertical.fill") }
                .tag(1)

            GradeBookView()
                .tabItem { Label("Grades", systemImage: "chart.bar.fill") }
                .tag(2)

            TermSettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(3)
        }
        .tint(TermTheme.accent)
    }
}
