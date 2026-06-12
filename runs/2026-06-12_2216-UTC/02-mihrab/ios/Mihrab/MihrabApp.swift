import SwiftUI
import SwiftData

@main
struct MihrabApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootTabView()
                } else {
                    OnboardingView()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active, hasOnboarded else { return }
                let enabled = notificationsEnabled
                Task { await NotificationScheduler.reschedule(enabled: enabled) }
            }
        }
        .modelContainer(for: PrayerLog.self)
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.and.horizon.fill") }
            QiblaView()
                .tabItem { Label("Qibla", systemImage: "location.north.line.fill") }
            TrackerView()
                .tabItem { Label("Tracker", systemImage: "checkmark.circle.fill") }
            MonthView()
                .tabItem { Label("Month", systemImage: "calendar") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
