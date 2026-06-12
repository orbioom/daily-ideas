import SwiftUI
import SwiftData

@main
struct RotaApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                RootTabView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(for: [ShiftType.self, RotationPattern.self, PatternSlot.self, ShiftOverride.self])
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "clock.badge.checkmark") }
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            EarningsView()
                .tabItem { Label("Earnings", systemImage: "banknote") }
            PatternsView()
                .tabItem { Label("Rotation", systemImage: "arrow.triangle.2.circlepath") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(RotaTheme.amber)
    }
}
